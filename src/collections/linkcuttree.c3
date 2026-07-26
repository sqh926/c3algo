// @title Link-Cut Tree
<*
 https://en.wikipedia.org/wiki/Link/cut_tree

 @require concept::@is_monoid(Monoid) : "Link-cut tree requires a monoid with `op(a,b)` and `e()`"
 @require concept::@is_action(Action, Monoid) : "Link-cut tree requires an action with `act(m)`, `op(f)` and `e()`"
*>
module c3algo::collections::linkcuttree <Monoid, Action>;

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
	Node* parent;
	Node*[2] child;
}

struct LinkCutTree
{
	Allocator allocator;
	Node[] nodes;
}

<*
 Initialize a forest of `n` isolated vertices holding the monoid identity.

 @param [&inout] allocator : "The allocator for nodes"
 @param n : "The number of vertices"

 @require !self.is_initialized() : "The LinkCutTree must not be initialized"
 @require n >= 0 : "The number of vertices may not be negative"

 @ensure (sz)self.nodes.len == n
*>
fn LinkCutTree* LinkCutTree.init(&self, Allocator allocator, sz n)
{
	self.allocator = allocator;
	self.nodes = alloc::alloc_array(allocator, Node, n);
	Monoid id = ((Monoid) { }).e();
	foreach (&node : self.nodes)
	{
		*node = { .val = id, .agg = id, .ragg = id, .lazy = ((Action) { }).e() };
	}
	return self;
}

<*
 Initialize a forest of isolated vertices holding `values`.

 @param [&inout] allocator : "The allocator for nodes"
 @param [in] values : "The initial vertex values"

 @require !self.is_initialized() : "The LinkCutTree must not be initialized"

 @ensure self.nodes.len == values.len
*>
fn LinkCutTree* LinkCutTree.init_with(&self, Allocator allocator, Monoid[] values)
{
	self.init(allocator, (sz)values.len);
	foreach (i, v : values)
	{
		self.nodes[i].val = v;
		self.nodes[i].agg = v;
		self.nodes[i].ragg = v;
	}
	return self;
}

<*
 Initialize a forest of `n` isolated vertices with the temp allocator.

 @param n : "The number of vertices"

 @require !self.is_initialized() : "The LinkCutTree must not be initialized"
 @require n >= 0 : "The number of vertices may not be negative"

 @ensure (sz)self.nodes.len == n
*>
fn LinkCutTree* LinkCutTree.tinit(&self, sz n) @inline => self.init(tmem, n);

<*
 Free the vertices and leave the forest uninitialized.

 @ensure !self.is_initialized()
*>
fn void LinkCutTree.free(&self)
{
	if (!self.is_initialized()) return;
	alloc::free(self.allocator, self.nodes.ptr);
	*self = { };
}

<*
 @return "`true` if the forest has an allocator"
*>
fn bool LinkCutTree.is_initialized(&self) @inline => self.allocator != null;

<*
 @return "The number of vertices"
*>
fn sz LinkCutTree.len(&self) @inline => (sz)self.nodes.len;

<*
 Make `v` the root of its tree.

 @param v : "The vertex to root the tree at"

 @require v >= 0 && v < (sz)self.nodes.len : "Vertex out of range"
*>
fn void LinkCutTree.evert(&self, sz v)
{
	Node* node = &self.nodes[v];
	expose(node);
	apply_rev(node);
	push(node);
}

<*
 Add the edge (u, v), rooting the tree of `u` at `u` first.

 @param u : "One end of the new edge"
 @param v : "The other end of the new edge"

 @require u >= 0 && u < (sz)self.nodes.len : "Vertex out of range"
 @require v >= 0 && v < (sz)self.nodes.len : "Vertex out of range"
 @require !self.connected(u, v) : "link() would close a cycle"
*>
fn void LinkCutTree.link(&self, sz u, sz v)
{
	self.evert(u);
	self.nodes[u].parent = &self.nodes[v];
}

<*
 Remove the edge (u, v).

 @param u : "One end of the edge"
 @param v : "The other end of the edge"

 @require u >= 0 && u < (sz)self.nodes.len : "Vertex out of range"
 @require v >= 0 && v < (sz)self.nodes.len : "Vertex out of range"
 @require self.is_edge(u, v) : "cut() requires an existing edge between u and v"
*>
fn void LinkCutTree.cut(&self, sz u, sz v)
{
	self.evert(u);
	Node* node = &self.nodes[v];
	expose(node);
	node.child[L].parent = null;
	node.child[L] = null;
	pull(node);
}

<*
 @param u : "One end of the edge"
 @param v : "The other end of the edge"

 @return "`true` if the edge (u, v) is present in the forest"

 @require u >= 0 && u < (sz)self.nodes.len : "Vertex out of range"
 @require v >= 0 && v < (sz)self.nodes.len : "Vertex out of range"
*>
fn bool LinkCutTree.is_edge(&self, sz u, sz v)
{
	if (u == v) return false;
	self.evert(u);
	Node* top = &self.nodes[v];
	expose(top);
	Node* below = &self.nodes[u];
	return top.child[L] == below && below.child[L] == null && below.child[R] == null;
}

<*
 @param v : "The vertex to start from"

 @return "The root of the tree holding `v`"

 @require v >= 0 && v < (sz)self.nodes.len : "Vertex out of range"
 @ensure return >= 0 && return < (sz)self.nodes.len
*>
fn sz LinkCutTree.find_root(&self, sz v)
{
	Node* node = &self.nodes[v];
	expose(node);
	while (node.child[L])
	{
		node = node.child[L];
		push(node);
	}
	splay(node);
	return node - self.nodes.ptr;
}

<*
 @param u : "The first vertex"
 @param v : "The second vertex"

 @return "`true` if `u` and `v` lie in the same tree"

 @require u >= 0 && u < (sz)self.nodes.len : "Vertex out of range"
 @require v >= 0 && v < (sz)self.nodes.len : "Vertex out of range"
*>
fn bool LinkCutTree.connected(&self, sz u, sz v) => self.find_root(u) == self.find_root(v);

<*
 @param v : "The vertex to read"

 @return "The value stored at `v`"

 @require v >= 0 && v < (sz)self.nodes.len : "Vertex out of range"
*>
fn Monoid LinkCutTree.get(&self, sz v)
{
	Node* node = &self.nodes[v];
	splay_push(node);
	return node.val;
}

<*
 Replace the value stored at `v`.

 @param v : "The vertex to write"
 @param m : "The new value"

 @require v >= 0 && v < (sz)self.nodes.len : "Vertex out of range"
*>
fn void LinkCutTree.set(&self, sz v, Monoid m)
{
	Node* node = &self.nodes[v];
	splay_push(node);
	node.val = m;
	pull(node);
}

<*
 Fold of the path from `u` to `v`, in that direction.

 @param u : "The vertex the path starts at"
 @param v : "The vertex the path ends at"

 @return "The fold of every value along the path, both ends included"

 @require u >= 0 && u < (sz)self.nodes.len : "Vertex out of range"
 @require v >= 0 && v < (sz)self.nodes.len : "Vertex out of range"
 @require self.connected(u, v) : "path() requires u and v to lie in the same tree"
*>
fn Monoid LinkCutTree.path(&self, sz u, sz v)
{
	self.evert(u);
	Node* node = &self.nodes[v];
	expose(node);
	return node.agg;
}

<*
 Apply an action to every value along the path from `u` to `v`.

 @param u : "The vertex the path starts at"
 @param v : "The vertex the path ends at"
 @param f : "The action to apply"

 @require u >= 0 && u < (sz)self.nodes.len : "Vertex out of range"
 @require v >= 0 && v < (sz)self.nodes.len : "Vertex out of range"
 @require self.connected(u, v) : "update_path() requires u and v to lie in the same tree"
*>
fn void LinkCutTree.update_path(&self, sz u, sz v, Action f)
{
	self.evert(u);
	Node* node = &self.nodes[v];
	expose(node);
	apply(node, f);
}

fn void expose(Node* node) @local
{
	splay_push(node);
	node.child[R] = null;
	pull(node);
	while (node.parent)
	{
		Node* above = node.parent;
		splay_push(above);
		above.child[R] = node;
		pull(above);
		splay_push(node);
	}
}

fn void splay_push(Node* node) @local
{
	push_down(node);
	splay(node);
}

fn void push_down(Node* node) @local
{
	if (!is_root(node)) push_down(node.parent);
	push(node);
}

fn void push(Node* node) @local
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

fn Monoid safe_agg(Node* node) @local @inline => node ? node.agg : ((Monoid) { }).e();

fn Monoid safe_ragg(Node* node) @local @inline => node ? node.ragg : ((Monoid) { }).e();

fn void pull(Node* node) @local
{
	node.agg = safe_agg(node.child[L]).op(node.val).op(safe_agg(node.child[R]));
	node.ragg = safe_ragg(node.child[R]).op(node.val).op(safe_ragg(node.child[L]));
}

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