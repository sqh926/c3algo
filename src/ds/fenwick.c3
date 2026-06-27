// @title Fenwick Tree
module c3algo::ds::fenwick <Monoid>;

import std::collections::list;

struct FenwickTree
{
	List{Monoid} tree;
}

fn FenwickTree* FenwickTree.init(&self, Allocator allocator, sz n)
{
	Monoid id = ((Monoid) { }).e();
	self.tree.init(allocator, n);
	for (sz i = 0; i < n; i++)
	{
		self.tree.push(id);
	}
	return self;
}

fn void FenwickTree.free(&self)
{
	self.tree.free();
	*self = { };
}

// a[i] = a[i].op(v)
fn void FenwickTree.add(&self, sz i, Monoid v) @inline
{
	for (; i < self.tree.len(); i = i | (i + 1))
	{
		self.tree[i] = self.tree[i].op(v);
	}
}

// Assumes commutativity
fn Monoid FenwickTree.fold(&self, sz r) @inline
{
	Monoid acc = ((Monoid) { }).e();
	for (; r > 0; r = r & (r - 1))
	{
		acc = self.tree[r - 1].op(acc);
	}
	return acc;
}

// Monoid needs to be a group
macro Monoid FenwickTree.range(&self, sz l, sz r)
{
	$if $defined((Monoid) { }.inv()):
		return self.fold(r).op(self.fold(l).inv());
	$else
		$error "fenwick.range() requires a group: add `fn Monoid.inv()` to the monoid";
	$endif
}

// a[i] = v, monoid needs to be a group
macro void FenwickTree.set(&self, sz i, Monoid v)
{
	$if $defined((Monoid) { }.inv()):
		Monoid cur = self.range(i, i + 1);
		self.add(i, v.op(cur.inv()));
	$else
		$error "fenwick.set() requires a group: add `fn Monoid.inv()` to the monoid";
	$endif
}
