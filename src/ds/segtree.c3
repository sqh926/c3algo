module c3algo::ds::segtree;

import std::collections::list;

struct Node
{
	long value;
}

alias NodeList = List{Node};

fn Node* Node.init(&self, long value)
{
	self.value = value;
	return self;
}

fn Node Node.merge(&self, Node other) @operator(+)
{
	Node merged @noinit;
	merged.init(self.value + other.value);
	return merged;
}

struct SegTree
{
	NodeList tree;
	sz size;
}

fn SegTree* SegTree.init(&self, Allocator allocator, sz n)
{
	self.size = (sz)1;
	while (self.size < n) self.size *= 2;
	self.tree.init(allocator, 2 * self.size - 1);
	return self;
}

fn void SegTree.free(&self)
{
	self.tree.free();
	*self = { };
}

fn void SegTree.set(&self, sz i, long value, sz x, sz lx, sz rx)
{
	if (rx == lx + 1)
	{
		self.tree[x].value += value;
		return;
	}
	sz m = (lx + rx) / 2;
	if (i < m)
	{
		self.set(i, value, 2 * x + 1, lx, m);
	}
	else
	{
		self.set(i, value, 2 * x + 2, m, rx);
	}
	self.tree[x] = self.tree[2 * x + 1] + self.tree[2 * x + 2];
}
fn long SegTree.sum(&self, sz l, sz r, sz x, sz lx, sz rx)
{
	if (l >= rx || r <= lx) return 0;
	if (l <= lx && rx <= r) return self.tree[x].value;
	sz m = (lx + rx) / 2;
	return self.sum(l, r, 2 * x + 1, lx, m) + self.sum(l, r, 2 * x + 2, m, rx);
}
