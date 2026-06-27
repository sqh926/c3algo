// @title Lazy Segment Tree
<*
 @require concept::@is_monoid(Monoid)
 @require concept::@is_action(Action, Monoid)
*>
module c3algo::ds::lazyseg <Monoid, Action>;

import std::collections::list;
import c3algo::algebra::concept;

struct LazySeg
{
	List{Monoid} tree;
	List{Action} lazy;
	sz size;
}

fn LazySeg* LazySeg.init(&self, Allocator allocator, sz n)
{
	self.size = 1;
	while (self.size < n) self.size *= 2;
	sz total = 2 * self.size - 1;
	self.tree.init(allocator, total);
	self.lazy.init(allocator, total);
	for (sz i = 0; i < total; i++)
	{
		self.tree.push(((Monoid) { }).e());
		self.lazy.push(((Action) { }).e());
	}
	return self;
}

fn void LazySeg.free(&self)
{
	self.tree.free();
	self.lazy.free();
	*self = { };
}

fn Monoid LazySeg.get(&self, sz i, sz x, sz lx, sz rx)
{
	if (rx - lx == 1) return self.tree[x];
	self.push(x);
	sz m = (lx + rx) / 2;
	if (i < m) return self.get(i, 2 * x + 1, lx, m);
	return self.get(i, 2 * x + 2, m, rx);
}

fn void LazySeg.apply_node(&self, sz x, Action f) @inline
{
	self.tree[x] = f.act(self.tree[x]);
	self.lazy[x] = self.lazy[x].op(f);
}

fn void LazySeg.push(&self, sz x) @inline
{
	self.apply_node(2 * x + 1, self.lazy[x]);
	self.apply_node(2 * x + 2, self.lazy[x]);
	self.lazy[x] = ((Action) { }).e();
}

fn void LazySeg.set(&self, sz i, Monoid v, sz x, sz lx, sz rx)
{
	if (rx - lx == 1)
	{
		self.tree[x] = v;
		return;
	}
	self.push(x);
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

fn void LazySeg.update(&self, sz l, sz r, Action f, sz x, sz lx, sz rx)
{
	if (l >= rx || r <= lx) return;
	if (l <= lx && rx <= r)
	{
		self.apply_node(x, f);
		return;
	}
	self.push(x);
	sz m = (lx + rx) / 2;
	self.update(l, r, f, 2 * x + 1, lx, m);
	self.update(l, r, f, 2 * x + 2, m, rx);
	self.tree[x] = self.tree[2 * x + 1].op(self.tree[2 * x + 2]);
}

fn Monoid LazySeg.range(&self, sz l, sz r, sz x, sz lx, sz rx)
{
	if (l >= rx || r <= lx) return ((Monoid) { }).e();
	if (l <= lx && rx <= r) return self.tree[x];
	self.push(x);
	sz m        = (lx + rx) / 2;
	Monoid resl = self.range(l, r, 2 * x + 1, lx, m);
	Monoid resr = self.range(l, r, 2 * x + 2, m, rx);
	return resl.op(resr);
}
