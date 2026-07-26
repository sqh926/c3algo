// @title Segment Tree
module c3algo::collections::segmenttree <Monoid>;

import std::collections::list;


struct SegmentTree
{
	List{Monoid} tree;
	sz size;
}

fn SegmentTree* SegmentTree.init(&self, Allocator allocator, sz n)
{
	self.size = (sz)1;
	while (self.size < n) self.size *= 2;
	sz total = 2 * self.size - 1;
	self.tree.init(allocator, total);
	for (sz i = 0; i < total; i++)
	{
		self.tree.push(((Monoid) { }).e());
	}
	return self;
}

fn void SegmentTree.free(&self)
{
	self.tree.free();
	*self = { };
}

fn Monoid SegmentTree.get(&self, sz i) => self.tree[self.size + i - 1];

fn void SegmentTree.set(&self, sz i, Monoid v, sz x, sz lx, sz rx)
{
	if (rx == lx + 1)
	{
		self.tree[x] = v;
		return;
	}
	sz m = (lx + rx) / 2;
	if (i < m)
	{
		self.set(i, v, 2 * x + 1, lx, m);
	}
	else
	{
		self.set(i, v, 2 * x + 2, m, rx);
	}
	self.tree[x] = self.tree[2 * x + 1].op(self.tree[2 * x + 2]);
}
fn Monoid SegmentTree.range(&self, sz l, sz r, sz x, sz lx, sz rx)
{
	if (l >= rx || r <= lx) return ((Monoid) { }).e();
	if (l <= lx && rx <= r) return self.tree[x];
	sz m        = (lx + rx) / 2;
	Monoid resl = self.range(l, r, 2 * x + 1, lx, m);
	Monoid resr = self.range(l, r, 2 * x + 2, m, rx);
	return resl.op(resr);
}