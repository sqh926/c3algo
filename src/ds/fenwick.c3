// @title Fenwick Tree
module c3algo::ds::fenwick;

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


struct FenwickTree
{
	NodeList tree;
}

fn FenwickTree* FenwickTree.init(&self, Allocator allocator, sz n)
{
	self.tree.init(allocator, n);
	for (sz i = 0; i < n; i++)
	{
		self.tree.push({ .value = 0 });
	}
	return self;
}

fn void FenwickTree.free(&self)
{
	self.tree.free();
}

fn void FenwickTree.set(&self, sz i, long value)
{
	for (; i < self.tree.len(); i = i | (i + 1))
	{
		self.tree[i].value += value;
	}
}

fn long FenwickTree.pref(&self, sz r)
{
	long sum = 0;
	for (; r > 0; r = r & (r - 1))
	{
		sum += self.tree[r - 1].value;
	}
	return sum;
}


fn long FenwickTree.range(&self, sz l, sz r)
{
	return self.pref(r) - self.pref(l);
}
