// @title Fenwick Tree
<*
 Fenwick Tree is basically a faster version of Segment Tree and with smaller constant,
 but it has more strict constraints on the elements.

 https://cp-algorithms.com/data_structures/fenwick.html

 @require concept::@is_monoid(Monoid) : "Fenwick tree requires a monoid with `op(a,b)` and `e()`"
*>
module c3algo::collections::fenwicktree <Monoid>;

import c3algo::algebra::concept;

struct FenwickTree
{
	Allocator allocator;
	Monoid[] tree;
}

<*
 Initialize a Fenwick tree of `n` elements.

 @param [&inout] allocator : "The allocator for the array"
 @param n : "The number of elements"

 @require !self.is_initialized() : "The FenwickTree must not be initialized"
 @require n >= 0 : "The number of elements may not be negative"

 @ensure (sz)self.tree.len == n
*>
fn FenwickTree* FenwickTree.init(&self, Allocator allocator, sz n)
{
	self.allocator = allocator;
	self.tree = alloc::alloc_array(allocator, Monoid, n);
	Monoid id = ((Monoid) { }).e();
	foreach (&node : self.tree)
	{
		*node = id;
	}
	return self;
}

<*
 Initialize a Fenwick tree with `values`, folding every node in O(n) time.

 @param [&inout] allocator : "The allocator for the array"
 @param [in] values : "The initial elements"

 @require !self.is_initialized() : "The FenwickTree must not be initialized"

 @ensure self.tree.len == values.len
*>
fn FenwickTree* FenwickTree.init_with(&self, Allocator allocator, Monoid[] values)
{
	self.init(allocator, (sz)values.len);
	sz n = (sz)self.tree.len;
	foreach (i, v : values)
	{
		self.tree[i] = v;
	}
	for (sz i = 0; i < n; i++)
	{
		sz parent = i | (i + 1);
		if (parent < n) self.tree[parent] = self.tree[parent].op(self.tree[i]);
	}
	return self;
}

<*
 Initialize a Fenwick tree of `n` identity elements with the temp allocator.

 @param n : "The number of elements"

 @require !self.is_initialized() : "The FenwickTree must not be initialized"
 @require n >= 0 : "The number of elements may not be negative"

 @ensure (sz)self.tree.len == n
*>
fn FenwickTree* FenwickTree.tinit(&self, sz n) @inline => self.init(tmem, n);

<*
 Free the array and leave the tree uninitialized.

 @ensure !self.is_initialized()
*>
fn void FenwickTree.free(&self)
{
	if (!self.is_initialized()) return;
	alloc::free(self.allocator, self.tree.ptr);
	*self = { };
}

<*
 @return "`true` if the tree has an allocator"
*>
fn bool FenwickTree.is_initialized(&self) @inline => self.allocator != null;

<*
 @return "The number of elements"
*>
fn sz FenwickTree.len(&self) @inline => (sz)self.tree.len;

<*
 Combine `v` into the element at `i`, leaving `a[i]` equal to `a[i].op(v)`.

 @param i : "The position to update"
 @param v : "The element to combine in"

 @require i >= 0 && i < self.len() : "Index out of range"
*>
fn void FenwickTree.add(&self, sz i, Monoid v)
{
	sz n = (sz)self.tree.len;
	for (; i < n; i = i | (i + 1))
	{
		self.tree[i] = self.tree[i].op(v);
	}
}

<*
 Fold of the prefix [0, r), which relies on the monoid operation being commutative.

 @param r : "One past the last position of the prefix"

 @return "The fold of the prefix, the monoid identity when empty"

 @require r >= 0 && r <= self.len() : "Prefix out of range"
*>
fn Monoid FenwickTree.fold(&self, sz r)
{
	Monoid acc = ((Monoid) { }).e();
	for (; r > 0; r = r & (r - 1))
	{
		acc = self.tree[r - 1].op(acc);
	}
	return acc;
}

<*
 Fold of the range [l, r), obtained by cancelling the shorter prefix out of the longer one.

 @param l : "The first position of the range"
 @param r : "One past the last position of the range"

 @return "The fold of the range, the monoid identity when empty"

 @require concept::@has_inverse(Monoid) : "range() requires a group: add `fn Monoid.inv()` to the monoid"
 @require l >= 0 && l <= r && r <= self.len() : "Range out of bounds"
*>
macro Monoid FenwickTree.range(&self, sz l, sz r)
{
	return self.fold(r).op(self.fold(l).inv());
}

<*
 Replace the element at `i`.

 @param i : "The position to write"
 @param v : "The new element"

 @require concept::@has_inverse(Monoid) : "set() requires a group: add `fn Monoid.inv()` to the monoid"
 @require i >= 0 && i < self.len() : "Index out of range"
*>
macro void FenwickTree.set(&self, sz i, Monoid v)
{
	Monoid cur = self.range(i, i + 1);
	self.add(i, v.op(cur.inv()));
}