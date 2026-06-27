module c3algo::ds::segtree <Monoid>;

import std::collections::list;


struct SegTree
{
	List{Monoid} tree;
	sz size;
	Monoid id;
}

fn SegTree* SegTree.init(&self, Allocator allocator, sz n, Monoid id)
{
	self.id = id;
	self.size = (sz)1;
	while (self.size < n) self.size *= 2;
	self.tree.init(allocator, 2 * self.size - 1);
	for (sz i = 0; i < 2 * self.size - 1; i++)
	{
		self.tree.push(id);
	}
	return self;
}

fn void SegTree.free(&self)
{
	self.tree.free();
	*self = { };
}

fn Monoid SegTree.get(&self, sz i) => self.tree[self.size + i - 1];

fn void SegTree.set(&self, sz i, Monoid v, sz x, sz lx, sz rx)
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
fn Monoid SegTree.exec_on_seg(&self, sz l, sz r, sz x, sz lx, sz rx)
{
	if (l >= rx || r <= lx) return self.id;
	if (l <= lx && rx <= r) return self.tree[x];
	sz m        = (lx + rx) / 2;
	Monoid resl = self.exec_on_seg(l, r, 2 * x + 1, lx, m);
	Monoid resr = self.exec_on_seg(l, r, 2 * x + 2, m, rx);
	return resl.op(resr);
}
