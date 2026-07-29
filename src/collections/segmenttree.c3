// @title Segment Tree
<*
 A Segment Tree is a data structure that stores information about array intervals as a tree.
 This allows answering range queries over an array efficiently,
 while still being flexible enough to allow quick modification of the array.

 https://cp-algorithms.com/data_structures/segment_tree.html

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

 INSTANTIATE
     import c3algo::algebra::monoid;
     import c3algo::collections::segmenttree;

     alias Seg = SegmentTree {Max {long}};

 API
     Seg* init(Allocator allocator, sz n)              every element is e()
     Seg* init_with(Allocator allocator, Monoid[] src) same, filled from src, O(n)
     Seg* tinit(sz n)                                  init on the temp allocator
     void free()
     bool is_initialized()
     sz   len()
     Monoid get(sz i)
     void set(sz i, Monoid v)
     Monoid range(sz l, sz r)                          fold of [l, r)

 USE
     Seg s;
     s.init(mem, 8);
     defer s.free();

     s.set(2, {42});
     long best = s.range(0, 5).v;

 @require concept::@is_monoid(Monoid) : "Segment tree requires a monoid with `op(a,b)` and `e()`"
*>
module c3algo::collections::segmenttree <Monoid>;

import c3algo::algebra::concept;

struct SegmentTree
{
	Allocator allocator;
	Monoid[] tree;
	sz count;
	sz size;
}

<*
 Initialize a segment tree of `n` elements.

 @param [&inout] allocator : "The allocator for nodes"
 @param n : "The number of elements"

 @require !self.is_initialized() : "The SegmentTree must not be initialized"
 @require n >= 0 : "The number of elements may not be negative"

 @ensure self.count == n
*>
fn SegmentTree* SegmentTree.init(&self, Allocator allocator, sz n)
{
	self.allocator = allocator;
	self.count = n;
	self.size = 1;
	while (self.size < n) self.size *= 2;
	self.tree = alloc::alloc_array(allocator, Monoid, 2 * self.size - 1);
	Monoid id = ((Monoid) { }).e();
	foreach (&node : self.tree)
	{
		*node = id;
	}
	return self;
}

<*
 Initialize a segment tree with `values`.

 @param [&inout] allocator : "The allocator for nodes"
 @param [in] values : "The initial elements"

 @require !self.is_initialized() : "The SegmentTree must not be initialized"

 @ensure self.count == (sz)values.len
*>
fn SegmentTree* SegmentTree.init_with(&self, Allocator allocator, Monoid[] values)
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
 Initialize a segment tree of `n` elements with the temp allocator.

 @param n : "The number of elements"

 @require !self.is_initialized() : "The SegmentTree must not be initialized"
 @require n >= 0 : "The number of elements may not be negative"

 @ensure self.count == n
*>
fn SegmentTree* SegmentTree.tinit(&self, sz n) @inline => self.init(tmem, n);

<*
 Free the nodes and leave the tree uninitialized.

 @ensure !self.is_initialized()
*>
fn void SegmentTree.free(&self)
{
	if (!self.is_initialized()) return;
	alloc::free(self.allocator, self.tree.ptr);
	*self = { };
}

<*
 @return "`true` if the tree has an allocator"
*>
fn bool SegmentTree.is_initialized(&self) @inline => self.allocator != null;

<*
 @return "The number of elements"
*>
fn sz SegmentTree.len(&self) @inline => self.count;

<*
 @param i : "The position to read"

 @return "The element at `i`"

 @require i >= 0 && i < self.len() : "Index out of range"
*>
fn Monoid SegmentTree.get(&self, sz i) @inline => self.tree[self.size + i - 1];

<*
 Replace the element at `i` and refresh every fold above it.

 @param i : "The position to write"
 @param v : "The new element"

 @require i >= 0 && i < self.len() : "Index out of range"
*>
fn void SegmentTree.set(&self, sz i, Monoid v)
{
	set_node(self.tree, 0, 0, self.size, i, v);
}

<*
 Fold of the range [l, r).

 @param l : "The first position of the range"
 @param r : "One past the last position of the range"

 @return "The fold of the range, the monoid identity when empty"

 @require l >= 0 && l <= r && r <= self.len() : "Range out of bounds"
*>
fn Monoid SegmentTree.range(&self, sz l, sz r)
{
	return fold_node(self.tree, 0, 0, self.size, l, r);
}

fn void set_node(Monoid[] tree, sz x, sz lx, sz rx, sz i, Monoid v) @local
{
	if (rx - lx == 1)
	{
		tree[x] = v;
		return;
	}
	sz m = (lx + rx) / 2;
	if (i < m)
	{
		set_node(tree, 2 * x + 1, lx, m, i, v);
	}
	else
	{
		set_node(tree, 2 * x + 2, m, rx, i, v);
	}
	tree[x] = tree[2 * x + 1].op(tree[2 * x + 2]);
}

fn Monoid fold_node(Monoid[] tree, sz x, sz lx, sz rx, sz l, sz r) @local
{
	if (l >= rx || r <= lx) return ((Monoid) { }).e();
	if (l <= lx && rx <= r) return tree[x];
	sz m         = (lx + rx) / 2;
	Monoid left  = fold_node(tree, 2 * x + 1, lx, m, l, r);
	Monoid right = fold_node(tree, 2 * x + 2, m, rx, l, r);
	return left.op(right);
}