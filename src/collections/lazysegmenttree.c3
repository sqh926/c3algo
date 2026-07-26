// @title Lazy Segment Tree
<*
 A Segment Tree that also stores a pending action in every node, so that an action applied
 to a whole range costs O(logn) instead of touching each element. A pending action is pushed
 one level down whenever a query has to look inside the node.

 https://cp-algorithms.com/data_structures/segment_tree.html#range-updates-lazy-propagation

 @require concept::@is_monoid(Monoid) : "Lazy segment tree requires a monoid with `op(a,b)` and `e()`"
 @require concept::@is_action(Action, Monoid) : "Lazy segment tree requires an action with `act(m)`, `op(f)` and `e()`"
*>
module c3algo::collections::lazysegmenttree <Monoid, Action>;

import c3algo::algebra::concept;

struct LazySegmentTree
{
	Allocator allocator;
	Monoid[] tree;
	Action[] lazy;
	sz count;
	sz size;
}

<*
 Initialize a lazy segment tree of `n` elements.

 @param [&inout] allocator : "The allocator for nodes"
 @param n : "The number of elements"

 @require !self.is_initialized() : "The LazySegmentTree must not be initialized"
 @require n >= 0 : "The number of elements may not be negative"

 @ensure self.count == n
*>
fn LazySegmentTree* LazySegmentTree.init(&self, Allocator allocator, sz n)
{
	self.allocator = allocator;
	self.count = n;
	self.size = 1;
	while (self.size < n) self.size *= 2;
	sz total = 2 * self.size - 1;
	self.tree = alloc::alloc_array(allocator, Monoid, total);
	self.lazy = alloc::alloc_array(allocator, Action, total);
	Monoid id   = ((Monoid) { }).e();
	Action none = ((Action) { }).e();
	foreach (i, &node : self.tree)
	{
		*node = id;
		self.lazy[i] = none;
	}
	return self;
}

<*
 Initialize a lazy segment tree with `values`.

 @param [&inout] allocator : "The allocator for nodes"
 @param [in] values : "The initial elements"

 @require !self.is_initialized() : "The LazySegmentTree must not be initialized"

 @ensure self.count == (sz)values.len
*>
fn LazySegmentTree* LazySegmentTree.init_with(&self, Allocator allocator, Monoid[] values)
{
	self.init(allocator, (sz)values.len);
	foreach (i, v : values)
	{
		self.tree[self.size + (sz)i - 1] = v;
	}
	for (sz x = self.size - 2; x >= 0; x--)
	{
		self.tree[x] = self.tree[2 * x + 1].op(self.tree[2 * x + 2]);
	}
	return self;
}

<*
 Initialize a lazy segment tree of `n` elements with the temp allocator.

 @param n : "The number of elements"

 @require !self.is_initialized() : "The LazySegmentTree must not be initialized"
 @require n >= 0 : "The number of elements may not be negative"

 @ensure self.count == n
*>
fn LazySegmentTree* LazySegmentTree.tinit(&self, sz n) @inline => self.init(tmem, n);

<*
 Free the nodes and leave the tree uninitialized.

 @ensure !self.is_initialized()
*>
fn void LazySegmentTree.free(&self)
{
	if (!self.is_initialized()) return;
	alloc::free(self.allocator, self.tree.ptr);
	alloc::free(self.allocator, self.lazy.ptr);
	*self = { };
}

<*
 @return "`true` if the tree has an allocator"
*>
fn bool LazySegmentTree.is_initialized(&self) @inline => self.allocator != null;

<*
 @return "The number of elements"
*>
fn sz LazySegmentTree.len(&self) @inline => self.count;

<*
 Read the element at `i`, pushing every pending action on the way down.

 @param i : "The position to read"

 @return "The element at `i`"

 @require i >= 0 && i < self.len() : "Index out of range"
*>
fn Monoid LazySegmentTree.get(&self, sz i)
{
	return get_node(self, 0, 0, self.size, i);
}

<*
 Replace the element at `i` and refresh every fold above it.

 @param i : "The position to write"
 @param v : "The new element"

 @require i >= 0 && i < self.len() : "Index out of range"
*>
fn void LazySegmentTree.set(&self, sz i, Monoid v)
{
	set_node(self, 0, 0, self.size, i, v);
}

<*
 Apply an action to every element in the range [l, r).

 @param l : "The first position of the range"
 @param r : "One past the last position of the range"
 @param f : "The action to apply"

 @require l >= 0 && l <= r && r <= self.len() : "Range out of bounds"
*>
fn void LazySegmentTree.update(&self, sz l, sz r, Action f)
{
	update_node(self, 0, 0, self.size, l, r, f);
}

<*
 Fold of the range [l, r).

 @param l : "The first position of the range"
 @param r : "One past the last position of the range"

 @return "The fold of the range, the monoid identity when empty"

 @require l >= 0 && l <= r && r <= self.len() : "Range out of bounds"
*>
fn Monoid LazySegmentTree.range(&self, sz l, sz r)
{
	return fold_node(self, 0, 0, self.size, l, r);
}

fn void apply_node(LazySegmentTree* self, sz x, Action f) @local @inline
{
	self.tree[x] = f.act(self.tree[x]);
	self.lazy[x] = self.lazy[x].op(f);
}

fn void push_down(LazySegmentTree* self, sz x) @local @inline
{
	apply_node(self, 2 * x + 1, self.lazy[x]);
	apply_node(self, 2 * x + 2, self.lazy[x]);
	self.lazy[x] = ((Action) { }).e();
}

fn Monoid get_node(LazySegmentTree* self, sz x, sz lx, sz rx, sz i) @local
{
	if (rx - lx == 1) return self.tree[x];
	push_down(self, x);
	sz m = (lx + rx) / 2;
	if (i < m) return get_node(self, 2 * x + 1, lx, m, i);
	return get_node(self, 2 * x + 2, m, rx, i);
}

fn void set_node(LazySegmentTree* self, sz x, sz lx, sz rx, sz i, Monoid v) @local
{
	if (rx - lx == 1)
	{
		self.tree[x] = v;
		return;
	}
	push_down(self, x);
	sz m = (lx + rx) / 2;
	if (i < m)
	{
		set_node(self, 2 * x + 1, lx, m, i, v);
	}
	else
	{
		set_node(self, 2 * x + 2, m, rx, i, v);
	}
	self.tree[x] = self.tree[2 * x + 1].op(self.tree[2 * x + 2]);
}

fn void update_node(LazySegmentTree* self, sz x, sz lx, sz rx, sz l, sz r, Action f) @local
{
	if (l >= rx || r <= lx) return;
	if (l <= lx && rx <= r)
	{
		apply_node(self, x, f);
		return;
	}
	push_down(self, x);
	sz m = (lx + rx) / 2;
	update_node(self, 2 * x + 1, lx, m, l, r, f);
	update_node(self, 2 * x + 2, m, rx, l, r, f);
	self.tree[x] = self.tree[2 * x + 1].op(self.tree[2 * x + 2]);
}

fn Monoid fold_node(LazySegmentTree* self, sz x, sz lx, sz rx, sz l, sz r) @local
{
	if (l >= rx || r <= lx) return ((Monoid) { }).e();
	if (l <= lx && rx <= r) return self.tree[x];
	push_down(self, x);
	sz m         = (lx + rx) / 2;
	Monoid left  = fold_node(self, 2 * x + 1, lx, m, l, r);
	Monoid right = fold_node(self, 2 * x + 2, m, rx, l, r);
	return left.op(right);
}