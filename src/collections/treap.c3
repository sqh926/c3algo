// @title Implicit Treap
<*
 Treap with implicit key, can be treated as a dynamic array supporting insert, erase,
 range fold, range action and range reverse, all in O(logn) time.

 https://cp-algorithms.com/data_structures/treap.html

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
     import c3algo::collections::treap;

     alias Elem = SumLen {long};
     alias Map  = Affine {long};
     alias Seq  = Treap {Elem, Map};

 API
     Seq* init(Allocator allocator)                    an empty sequence
     Seq* tinit()                                      init on the temp allocator
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
     Seq split(sz at)                                  [at, len) leaves as a new treap
     void merge(Seq* other)                            appends other and empties it

 USE
     Seq s;
     s.init(mem);
     defer s.free();

     for (sz i = 0; i < 5; i++) s.push_back({ (long)i, 1 });
     s.reverse(1, 4);
     long sum = s.range(0, 3).sum;

 @require concept::@is_monoid(Monoid) : "Implicit treap requires a monoid with `op(a,b)` and `e()`"
 @require concept::@is_action(Action, Monoid) : "Implicit treap requires an action with `act(m)`, `op(f)` and `e()`"
*>
module c3algo::collections::treap <Monoid, Action>;

import c3algo::algebra::concept;
import c3algo::random;

const int L = 0;
const int R = 1;

struct Node
{
	Monoid val;
	Monoid agg;
	Action lazy;
	bool rev;
	int prior;
	sz size;
	Node*[2] child;
}

struct Treap
{
	Allocator allocator;
	Node* root;
}

<*
 Initialize an empty Treap.

 @param [&inout] allocator : "The allocator nodes are taken from"

 @require !self.is_initialized() : "The Treap must not be initialized"

 @ensure self.root == null
*>
fn Treap* Treap.init(&self, Allocator allocator)
{
	self.allocator = allocator;
	self.root = null;
	return self;
}

<*
 Initialize an empty Treap with the temp allocator.

 @require !self.is_initialized() : "The Treap must not be initialized"

 @ensure self.root == null
*>
fn Treap* Treap.tinit(&self) => self.init(tmem) @inline;

<*
 Free every node and leave the Treap uninitialized.

 @ensure !self.is_initialized()
*>
fn void Treap.free(&self)
{
	if (!self.is_initialized()) return;
	self.clear();
	*self = { };
}

<*
 Free every node, keeping the Treap initialized.

 @require self.is_initialized() : "The Treap must be initialized"

 @ensure self.root == null
*>
fn void Treap.clear(&self)
{
	free_nodes(self.allocator, self.root);
	self.root = null;
}

<*
 @return "`true` if the Treap has an allocator"
*>
fn bool Treap.is_initialized(&self) @inline => self.allocator != null;

<*
 @return "The number of elements"
*>
fn sz Treap.len(&self) @inline => safe_size(self.root);

<*
 @return "`true` if the Treap holds no elements"
*>
fn bool Treap.is_empty(&self) @inline => self.root == null;

<*
 Append an element.

 @param v : "The element to append"

 @require self.allocator != null : "The Treap must be initialized"
*>
fn void Treap.push_back(&self, Monoid v)
{
	self.root = merge_nodes(self.root, new_node(self.allocator, v));
}

<*
 Insert an element, shifting everything from `at` one position to the right.

 @param at : "The position the element takes"
 @param v : "The element to insert"

 @require self.allocator != null : "The Treap must be initialized"
 @require at >= 0 && at <= self.len() : "Index out of range"
*>
fn void Treap.insert(&self, sz at, Monoid v)
{
	Node* l;
	Node* r;
	split_nodes(self.root, at, &l, &r);
	self.root = merge_nodes(merge_nodes(l, new_node(self.allocator, v)), r);
}

<*
 Remove the element at `at`.

 @param at : "The position to remove"

 @require self.allocator != null : "The Treap must be initialized"
 @require at >= 0 && at < self.len() : "Index out of range"
*>
fn void Treap.erase(&self, sz at)
{
	Node* l;
	Node* m;
	Node* r;
	split_nodes(self.root, at, &l, &r);
	split_nodes(r, 1, &m, &r);
	alloc::free(self.allocator, m);
	self.root = merge_nodes(l, r);
}

<*
 @param k : "The position to read"

 @return "The element at `k`"

 @require k >= 0 && k < self.len() : "Index out of range"
*>
fn Monoid Treap.get(&self, sz k)
{
	Node* node = self.root;
	while (node)
	{
		push_down(node);
		sz ls = safe_size(node.child[L]);
		if (k == ls) return node.val;
		if (k < ls)
		{
			node = node.child[L];
			continue;
		}
		k -= ls + 1;
		node = node.child[R];
	}
	return ((Monoid) { }).e();
}

<*
 Replace the element at `k`.

 @param k : "The position to write"
 @param v : "The new element"

 @require k >= 0 && k < self.len() : "Index out of range"
*>
fn void Treap.set(&self, sz k, Monoid v)
{
	Node* a;
	Node* b;
	Node* c;
	split_nodes(self.root, k, &a, &b);
	split_nodes(b, 1, &b, &c);
	b.val = v;
	b.agg = v;
	self.root = merge_nodes(merge_nodes(a, b), c);
}

<*
 Fold of the range [l, r).

 @param l : "The first position of the range"
 @param r : "One past the last position of the range"

 @return "The fold of the range, the monoid identity when empty"

 @require l >= 0 && l <= r && r <= self.len() : "Range out of bounds"
*>
fn Monoid Treap.range(&self, sz l, sz r)
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
fn void Treap.update(&self, sz l, sz r, Action f)
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
fn void Treap.reverse(&self, sz l, sz r)
{
	Node* a;
	Node* b;
	Node* c;
	split_nodes(self.root, l, &a, &b);
	split_nodes(b, r - l, &b, &c);
	if (b) b.rev = !b.rev;
	self.root = merge_nodes(merge_nodes(a, b), c);
}

<*
 Cut the Treap in two, keeping [0, at) here.

 @param at : "Index of first element going to the right Treap"

 @return "A Treap holding the elements [at, len), sharing this allocator"

 @require self.allocator != null : "The Treap must be initialized"
 @require at >= 0 && at <= self.len() : "Index out of range"
*>
fn Treap Treap.split(&self, sz at)
{
	Treap right;
	right.allocator = self.allocator;
	split_nodes(self.root, at, &self.root, &right.root);
	return right;
}

<*
 Append every element of `other`, absorbing `other` in the process.

 @param [&inout] other : "Treap to absorb"

 @require self.allocator == other.allocator : "Both Treaps must share an allocator"
 @require self != other : "A Treap may not be merged into itself"
*>
fn void Treap.merge(&self, Treap* other)
{
	self.root = merge_nodes(self.root, other.root);
	other.root = null;
}

fn Node* new_node(Allocator allocator, Monoid v) @local
{
	Node* node = alloc::new(allocator, Node);
	node.val = v;
	node.agg = v;
	node.lazy = ((Action) { }).e();
	node.prior = (int)(random::next() >> 33);
	node.size = 1;
	return node;
}

fn sz safe_size(Node* node) @local @inline => node ? node.size : 0;

fn Monoid safe_agg(Node* node) @local @inline => node ? node.agg : ((Monoid) { }).e();

fn void apply(Node* node, Action f) @local @inline
{
	node.val = f.act(node.val);
	node.agg = f.act(node.agg);
	node.lazy = node.lazy.op(f);
}

fn void pull(Node* node) @local @inline
{
	node.agg = safe_agg(node.child[L]).op(node.val).op(safe_agg(node.child[R]));
	node.size = 1 + safe_size(node.child[L]) + safe_size(node.child[R]);
}

fn void push_down(Node* node) @local
{
	if (node.rev)
	{
		@swap(node.child[L], node.child[R]);
		if (node.child[L]) node.child[L].rev ^= true;
		if (node.child[R]) node.child[R].rev ^= true;
		node.rev = false;
	}
	if (node.child[L]) apply(node.child[L], node.lazy);
	if (node.child[R]) apply(node.child[R], node.lazy);
	node.lazy = ((Action) { }).e();
}

fn Node* merge_nodes(Node* l, Node* r) @local
{
	if (!l || !r) return l ? l : r;
	Node* top;
	if (l.prior >= r.prior)
	{
		push_down(l);
		l.child[R] = merge_nodes(l.child[R], r);
		top = l;
	}
	else
	{
		push_down(r);
		r.child[L] = merge_nodes(l, r.child[L]);
		top = r;
	}
	pull(top);
	return top;
}

// cursed code :3
fn void split_nodes(Node* node, sz k, Node** l, Node** r) @local
{
	if (!node)
	{
		*l = null;
		*r = null;
		return;
	}
	push_down(node);
	if (safe_size(node.child[L]) < k)
	{
		split_nodes(node.child[R], k - safe_size(node.child[L]) - 1, &node.child[R], r);
		*l = node;
	}
	else
	{
		split_nodes(node.child[L], k, l, &node.child[L]);
		*r = node;
	}
	pull(node);
}

fn void free_nodes(Allocator allocator, Node* node) @local
{
	if (!node) return;
	free_nodes(allocator, node.child[L]);
	free_nodes(allocator, node.child[R]);
	alloc::free(allocator, node);
}