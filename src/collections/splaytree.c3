// @title Implicit Splay Tree
<*
 A variant of self-balancing binary search tree.
 https://en.wikipedia.org/wiki/Splay_tree

 MONOID
     The element is any struct of yours with two methods:

         fn T T.op(self, T other)   combines two elements, has to be associative;
                                    the order is kept, so it may be non-commutative
         fn T T.e(self)             the neutral element, x.op(x.e()) == x

     Some of the most popular monoids are already implemented in c3algo::algebra::monoid <Elem>:
	 Sum, Min, Max, Prod, Xor, Gcd, SumLen.


     Classical example, the minimum together with how many times it occurs:

         struct MinCount { long v; long n; }
         fn MinCount MinCount.op(self, MinCount o) @inline
         {
             if (self.v != o.v) return self.v < o.v ? self : o;
             return (MinCount) { self.v, self.n + o.n };
         }
         fn MinCount MinCount.e(self) @inline => (MinCount) { long::max, 0 };

 ACTION
     An action is a monoid as well, plus a way to apply itself to an element:

         fn A A.op(self, A other)   compose, self applied first and other after it
         fn A A.e(self)             the action that changes nothing
         fn M A.act(self, M m)      apply to an element

     Classical example, adding a constant to a range folded by Min:

         alias MinLong = Min {long};

         struct Add { long v; }
         fn Add Add.op(self, Add o) @inline => (Add) { self.v + o.v };
         fn Add Add.e(self) @inline => (Add) { 0 };
         fn MinLong Add.act(self, MinLong m) @inline => (MinLong) { m.v + self.v };

     act() is handed the fold of a whole range, not the elements one by one. A
     minimum survives that, since it shifts by the same constant. A sum would not,
     for example.

 INSTANTIATE
     import c3algo::algebra::monoid;
     import c3algo::algebra::action;
     import c3algo::collections::splaytree;

     alias Elem = SumLen {long};
     alias Map  = Affine {long};
     alias Tree = SplayTree {Elem, Map};

 API
     Tree* init(Allocator allocator)                   an empty sequence
     Tree* tinit()                                     init on the temp allocator
     void free()
     void clear()
     bool is_initialized()
     sz   len()
     bool is_empty()
     void push_back(Monoid v)
     void insert(sz at, Monoid v)
     void erase(sz at)
     Monoid get(sz k)
     void set(sz k, Monoid v)
     Monoid range(sz l, sz r)                          fold of [l, r)
     void update(sz l, sz r, Action f)
     void reverse(sz l, sz r)
     Tree split(sz at)                                 [at, len) leaves as a new tree
     void merge(Tree* other)                           appends other and empties it

 USE
     Tree t;
     t.init(mem);
     defer t.free();

     for (sz i = 0; i < 5; i++) t.push_back({ (long)i, 1 });
     t.reverse(1, 4);
     long sum = t.range(0, 3).sum;

 @require concept::@is_monoid(Monoid) : "Splay tree requires a monoid with `op(a,b)` and `e()`"
 @require concept::@is_action(Action, Monoid) : "Splay tree requires an action with `act(m)`, `op(f)` and `e()`"
*>
module c3algo::collections::splaytree <Monoid, Action>;

import c3algo::algebra::concept;

const int L = 0;
const int R = 1;

struct Node
{
	Monoid val;
	Monoid agg;
	Monoid ragg;
	Action lazy;
	bool rev;
	sz size;
	Node* parent;
	Node*[2] child;
}

struct SplayTree
{
	Allocator allocator;
	Node* root;
}

<*
 Initialize an empty sequence.

 @param [&inout] allocator : "The allocator for nodes"

 @require !self.is_initialized() : "The SplayTree must not be initialized"

 @ensure self.root == null
*>
fn SplayTree* SplayTree.init(&self, Allocator allocator)
{
	self.allocator = allocator;
	self.root = null;
	return self;
}

<*
 Initialize an empty sequence with the temp allocator.

 @require !self.is_initialized() : "The SplayTree must not be initialized"

 @ensure self.root == null
*>
fn SplayTree* SplayTree.tinit(&self) @inline => self.init(tmem);

<*
 Free every node and leave the sequence uninitialized.

 @ensure !self.is_initialized()
*>
fn void SplayTree.free(&self)
{
	if (!self.is_initialized()) return;
	self.clear();
	*self = { };
}

<*
 Free every node, keeping the sequence initialized.

 @require self.is_initialized() : "The SplayTree must be initialized"

 @ensure self.root == null
*>
fn void SplayTree.clear(&self)
{
	free_nodes(self.allocator, self.root);
	self.root = null;
}

<*
 @return "`true` if the sequence has an allocator"
*>
fn bool SplayTree.is_initialized(&self) @inline => self.allocator != null;

<*
 @return "The number of elements"
*>
fn sz SplayTree.len(&self) @inline => safe_size(self.root);

<*
 @return "`true` if the sequence holds no elements"
*>
fn bool SplayTree.is_empty(&self) @inline => self.root == null;

<*
 Append an element.

 @param v : "The element to append"

 @require self.is_initialized() : "The SplayTree must be initialized"
*>
fn void SplayTree.push_back(&self, Monoid v)
{
	self.root = merge_nodes(self.root, new_node(self.allocator, v));
}

<*
 Insert an element, shifting everything from `at` one position to the right.

 @param at : "The position the element takes"
 @param v : "The element to insert"

 @require self.allocator != null : "The SplayTree must be initialized"
 @require at >= 0 && at <= self.len() : "Index out of range"
*>
fn void SplayTree.insert(&self, sz at, Monoid v)
{
	Node* a;
	Node* b;
	split_nodes(self.root, at, &a, &b);
	self.root = merge_nodes(merge_nodes(a, new_node(self.allocator, v)), b);
}

<*
 Remove the element at `at`.

 @param at : "The position to remove"

 @require self.allocator != null : "The SplayTree must be initialized"
 @require at >= 0 && at < self.len() : "Index out of range"
*>
fn void SplayTree.erase(&self, sz at)
{
	Node* a;
	Node* m;
	Node* b;
	split_nodes(self.root, at, &a, &b);
	split_nodes(b, 1, &m, &b);
	alloc::free(self.allocator, m);
	self.root = merge_nodes(a, b);
}

<*
 Read the element at `k`, splaying it to the root.

 @param k : "The position to read"

 @return "The element at `k`"

 @require k >= 0 && k < self.len() : "Index out of range"
*>
fn Monoid SplayTree.get(&self, sz k)
{
	Node* node = kth_node(self.root, k);
	splay(node);
	self.root = node;
	return node.val;
}

<*
 Replace the element at `k`.

 @param k : "The position to write"
 @param v : "The new element"

 @require k >= 0 && k < self.len() : "Index out of range"
*>
fn void SplayTree.set(&self, sz k, Monoid v)
{
	Node* a;
	Node* b;
	Node* c;
	split_nodes(self.root, k, &a, &b);
	split_nodes(b, 1, &b, &c);
	b.val = v;
	pull(b);
	self.root = merge_nodes(merge_nodes(a, b), c);
}

<*
 Fold of the range [l, r).

 @param l : "The first position of the range"
 @param r : "One past the last position of the range"

 @return "The fold of the range, the monoid identity when empty"

 @require l >= 0 && l <= r && r <= self.len() : "Range out of bounds"
*>
fn Monoid SplayTree.range(&self, sz l, sz r)
{
	Node* a;
	Node* b;
	Node* c;
	split_nodes(self.root, l, &a, &b);
	split_nodes(b, r - l, &b, &c);
	Monoid res = safe_agg(b);
	self.root = merge_nodes(merge_nodes(a, b), c);
	return res;
}

<*
 Apply an action to every element in the range [l, r).

 @param l : "The first position of the range"
 @param r : "One past the last position of the range"
 @param f : "The action to apply"

 @require l >= 0 && l <= r && r <= self.len() : "Range out of bounds"
*>
fn void SplayTree.update(&self, sz l, sz r, Action f)
{
	Node* a;
	Node* b;
	Node* c;
	split_nodes(self.root, l, &a, &b);
	split_nodes(b, r - l, &b, &c);
	if (b) apply(b, f);
	self.root = merge_nodes(merge_nodes(a, b), c);
}

<*
 Reverse the range [l, r).

 @param l : "The first position of the range"
 @param r : "One past the last position of the range"

 @require l >= 0 && l <= r && r <= self.len() : "Range out of bounds"
*>
fn void SplayTree.reverse(&self, sz l, sz r)
{
	Node* a;
	Node* b;
	Node* c;
	split_nodes(self.root, l, &a, &b);
	split_nodes(b, r - l, &b, &c);
	if (b) apply_rev(b);
	self.root = merge_nodes(merge_nodes(a, b), c);
}

<*
 Cut the sequence in two, keeping [0, at) here.

 @param at : "Index of first element going to the right sequence"

 @return "A sequence holding the elements [at, len), sharing this allocator"

 @require self.allocator != null : "The SplayTree must be initialized"
 @require at >= 0 && at <= self.len() : "Index out of range"
*>
fn SplayTree SplayTree.split(&self, sz at)
{
	SplayTree right;
	right.allocator = self.allocator;
	split_nodes(self.root, at, &self.root, &right.root);
	return right;
}

<*
 Append every element of `other`, absorbing `other` in the process.

 @param [&inout] other : "The sequence to absorb"

 @require self.allocator == other.allocator : "Both sequences must share an allocator"
 @require self != other : "A sequence may not be merged into itself"
*>
fn void SplayTree.merge(&self, SplayTree* other)
{
	self.root = merge_nodes(self.root, other.root);
	other.root = null;
}

fn Node* new_node(Allocator allocator, Monoid v) @local
{
	Node* node = alloc::new(allocator, Node);
	node.val = v;
	node.agg = v;
	node.ragg = v;
	node.lazy = ((Action) { }).e();
	node.size = 1;
	return node;
}

fn sz safe_size(Node* node) @local @inline => node ? node.size : 0;

fn Monoid safe_agg(Node* node) @local @inline => node ? node.agg : ((Monoid) { }).e();

fn Monoid safe_ragg(Node* node) @local @inline => node ? node.ragg : ((Monoid) { }).e();

fn void apply(Node* node, Action f) @local @inline
{
	node.val = f.act(node.val);
	node.agg = f.act(node.agg);
	node.ragg = f.act(node.ragg);
	node.lazy = node.lazy.op(f);
}

fn void apply_rev(Node* node) @local @inline
{
	@swap(node.agg, node.ragg);
	node.rev ^= true;
}

fn void pull(Node* node) @local
{
	node.agg = safe_agg(node.child[L]).op(node.val).op(safe_agg(node.child[R]));
	node.ragg = safe_ragg(node.child[R]).op(node.val).op(safe_ragg(node.child[L]));
	node.size = 1 + safe_size(node.child[L]) + safe_size(node.child[R]);
}

fn void push_down(Node* node) @local
{
	if (node.rev)
	{
		@swap(node.child[L], node.child[R]);
		if (node.child[L]) apply_rev(node.child[L]);
		if (node.child[R]) apply_rev(node.child[R]);
		node.rev = false;
	}
	if (node.child[L]) apply(node.child[L], node.lazy);
	if (node.child[R]) apply(node.child[R], node.lazy);
	node.lazy = ((Action) { }).e();
}

fn bool is_root(Node* node) @local @inline
{
	return node.parent == null || (node.parent.child[L] != node && node.parent.child[R] != node);
}

fn void rotate(Node* node) @local
{
	Node* parent = node.parent;
	Node* grand  = parent.parent;
	int dir      = parent.child[R] == node ? R : L;
	int opp      = dir ^ 1;
	parent.child[dir] = node.child[opp];
	if (node.child[opp]) node.child[opp].parent = parent;
	node.child[opp] = parent;
	parent.parent = node;
	node.parent = grand;
	if (grand)
	{
		if (grand.child[L] == parent)
		{
			grand.child[L] = node;
		}
		else if (grand.child[R] == parent)
		{
			grand.child[R] = node;
		}
	}
	pull(parent);
	pull(node);
}

fn void splay(Node* node) @local
{
	while (!is_root(node))
	{
		Node* parent = node.parent;
		if (!is_root(parent))
		{
			bool zigzig = (parent.parent.child[L] == parent) == (parent.child[L] == node);
			rotate(zigzig ? parent : node);
		}
		rotate(node);
	}
}

fn Node* kth_node(Node* node, sz k) @local
{
	while (node)
	{
		push_down(node);
		sz ls = safe_size(node.child[L]);
		if (k == ls) return node;
		if (k < ls)
		{
			node = node.child[L];
			continue;
		}
		k -= ls + 1;
		node = node.child[R];
	}
	return null;
}

fn void split_nodes(Node* node, sz k, Node** l, Node** r) @local
{
	if (k == 0)
	{
		*l = null;
		*r = node;
		return;
	}
	if (k >= safe_size(node))
	{
		*l = node;
		*r = null;
		return;
	}
	Node* left = kth_node(node, k - 1);
	splay(left);
	Node* right = left.child[R];
	left.child[R] = null;
	if (right) right.parent = null;
	pull(left);
	*l = left;
	*r = right;
}

fn Node* merge_nodes(Node* l, Node* r) @local
{
	if (!l || !r) return l ? l : r;
	Node* last = l;
	push_down(last);
	while (last.child[R])
	{
		last = last.child[R];
		push_down(last);
	}
	splay(last);
	last.child[R] = r;
	r.parent = last;
	pull(last);
	return last;
}

<*
 A splay tree is not height balanced, so the nodes are released by repeatedly rotating the
 left child up and detaching the root, which never recurses however deep the tree got.
*>
fn void free_nodes(Allocator allocator, Node* node) @local
{
	while (node)
	{
		if (!node.child[L])
		{
			Node* rest = node.child[R];
			alloc::free(allocator, node);
			node = rest;
			continue;
		}
		Node* left = node.child[L];
		node.child[L] = left.child[R];
		left.child[R] = node;
		node = left;
	}
}