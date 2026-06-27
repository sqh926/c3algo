// @title Treap
module c3algo::ds::treap;
import std::core::mem;

struct Node
{
	int prior;
	sz cnt;
	int value;
	long sm;
	bool rev;
	Node* left;
	Node* right;
}

alias Treap = Node*;

// https://github.com/WebDrake/xorshift/blob/master/xorshift.c
uint rng_state @local = 2463534242;

fn int rand_prior() @local
{
	rng_state ^= rng_state << 13;
	rng_state ^= rng_state >> 17;
	rng_state ^= rng_state << 5;
	return (int)(rng_state & 0x7fffffff);
}

fn Treap new_node(int value)
{
	Treap nd = mem::new(Node);
	nd.prior = rand_prior();
	nd.cnt = 1;
	nd.value = value;
	nd.sm = value;
	return nd;
}

fn long Node.sum(&self) @inline
{
	return self ? self.sm : 0;
}

fn sz Node.size(&self) @inline
{
	return self ? self.cnt : 0;
}

fn void Node.push(&self)
{
	if (!self) return;
	if (self.rev)
	{
		self.rev = false;
		if (self.left) self.left.rev = !self.left.rev;
		if (self.right) self.right.rev = !self.right.rev;
		@swap(self.left, self.right);
	}
}

fn void Node.pull(&self)
{
	self.cnt = self.left.size() + self.right.size() + 1;
	self.sm = self.left.sum() + self.right.sum() + self.value;
}

fn void split(Treap t, sz size, Treap* l, Treap* r)
{
	if (!t)
	{
		*l = null;
		*r = null;
		return;
	}
	t.push();
	if (t.left.size() >= size)
	{
		split(t.left, size, l, &t.left);
		*r = t;
	}
	else
	{
		split(t.right, size - t.left.size() - 1, &t.right, r);
		*l = t;
	}
	t.pull();
}

fn void merge(Treap* t, Treap l, Treap r)
{
	if (!l || !r)
	{
		*t = l ? l : r;
		return;
	}
	if (l.prior >= r.prior)
	{
		l.push();
		merge(&l.right, l.right, r);
		*t = l;
	}
	else
	{
		r.push();
		merge(&r.left, l, r.left);
		*t = r;
	}
	(*t).pull();
}

fn void append(Treap* t, int value)
{
	Treap nd = new_node(value);
	merge(t, *t, nd);
}

fn void rev(Treap* t, int lkey, int rkey)
{
	Treap l;
	Treap m;
	Treap r;
	split(*t, lkey, &l, &m);
	split(m, (sz)(rkey - lkey), &m, &r);
	if (m) m.rev = !m.rev;
	merge(t, l, m);
	merge(t, *t, r);
}

fn long range(Treap* t, int lkey, int rkey)
{
	Treap l;
	Treap m;
	Treap r;
	split(*t, lkey, &l, &m);
	split(m, (sz)(rkey - lkey), &m, &r);
	long res = m.sum();
	merge(t, l, m);
	merge(t, *t, r);
	return res;
}
