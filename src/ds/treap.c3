// @title Implicit Treap

// An implicit treap is a simple variation of an ordinary treap
// which can be viewed as a dynamic array that supports
// the following operations in O(logn):
// - Inserting an element in any position
// - Removing an element from any position
// - Finding sum, minimum or maximum element in a given range.
// - Addition, painting in a given range
// - Reversing elements in a given range
<*
 @require concept::@is_monoid(Monoid)
 @require concept::@is_action(Action, Monoid)
*>
module c3algo::ds::implicittreap <Monoid, Action>;
import c3algo::algebra::concept;

const int L = 0;
const int R = 1;

struct Node
{
	Monoid val;
	Monoid agg;
	Action lazy;
	bool rev;
	int prior;
	sz size;
	Node*[2] child;
}
alias ImplicitTreap = Node*;

// https://github.com/WebDrake/xorshift/blob/master/xorshift.c
uint rng_state @local = 2463534242;

fn int rand_prior() @local
{
	rng_state ^= rng_state << 13;
	rng_state ^= rng_state >> 17;
	rng_state ^= rng_state << 5;
	return (int)(rng_state & 0x7fffffff);
}

fn ImplicitTreap new_node(Monoid v)
{
	ImplicitTreap n = mem::new(Node);
	n.val = v;
	n.agg = v;
	n.lazy = ((Action) { }).e();
	n.prior = rand_prior();
	n.size = 1;
	return n;
}

fn sz safe_size(ImplicitTreap t) @inline => t ? t.size : 0;
fn Monoid safe_agg(ImplicitTreap t) @inline => t ? t.agg : ((Monoid) { }).e();

fn void apply(ImplicitTreap t, Action f) @inline
{
	t.val = f.act(t.val);
	t.agg = f.act(t.agg);
	t.lazy = t.lazy.op(f);
}

fn void pull(ImplicitTreap t) @inline
{
	t.agg = safe_agg(t.child[L]).op(t.val).op(safe_agg(t.child[R]));
	t.size = 1 + safe_size(t.child[L]) + safe_size(t.child[R]);
}

fn void push(ImplicitTreap t)
{
	if (t.rev)
	{
		@swap(t.child[L], t.child[R]);
		if (t.child[L]) t.child[L].rev ^= true;
		if (t.child[R]) t.child[R].rev ^= true;
		t.rev = false;
	}
	if (t.child[L]) apply(t.child[L], t.lazy);
	if (t.child[R]) apply(t.child[R], t.lazy);
	t.lazy = ((Action) { }).e();
}

fn void merge(ImplicitTreap* t, ImplicitTreap l, ImplicitTreap r)
{
	if (!l || !r)
	{
		*t = l ? l : r;
		return;
	}
	if (l.prior >= r.prior)
	{
		push(l);
		merge(&l.child[R], l.child[R], r);
		*t = l;
	}
	else
	{
		push(r);
		merge(&r.child[L], l, r.child[L]);
		*t = r;
	}
	pull(*t);
}

fn void split(ImplicitTreap t, sz k, ImplicitTreap* l, ImplicitTreap* r)
{
	if (!t)
	{
		(*l) = (*r) = null;
		return;
	}
	push(t);
	if (safe_size(t.child[L]) < k)
	{
		split(t.child[R], k - safe_size(t.child[L]) - 1, &t.child[R], r);
		*l = t;
	}
	else
	{
		split(t.child[L], k, l, &t.child[L]);
		*r = t;
	}
	pull(t);
}

fn void push_back(ImplicitTreap* t, Monoid v) @inline
{
	merge(t, *t, new_node(v));
}

fn void insert(ImplicitTreap* t, sz at, Monoid v)
{
	ImplicitTreap l;
	ImplicitTreap r;
	split(*t, at, &l, &r);
	merge(t, l, new_node(v));
	merge(t, *t, r);
}

fn void erase(ImplicitTreap* t, sz at)
{
	ImplicitTreap l;
	ImplicitTreap m;
	ImplicitTreap r;
	split(*t, at, &l, &r);
	split(r, 1, &m, &r);
	if (m) mem::free(m);
	merge(t, l, r);
}


fn ImplicitTreap kth(ImplicitTreap t, sz k)
{
	while (t)
	{
		push(t);
		sz ls = safe_size(t.child[L]);
		if (k == ls) return t;
		if (k < ls)
		{
			t = t.child[L];
		}
		else
		{
			k -= ls + 1;
			t = t.child[R];
		}
	}
	return null;
}

fn Monoid range(ImplicitTreap* t, sz l, sz r)
{
	ImplicitTreap a;
	ImplicitTreap b;
	ImplicitTreap c;
	split(*t, l, &a, &b);
	split(b, r - l, &b, &c);
	Monoid res = safe_agg(b);
	merge(t, a, b);
	merge(t, *t, c);
	return res;
}

fn void update(ImplicitTreap* t, sz l, sz r, Action f)
{
	ImplicitTreap a;
	ImplicitTreap b;
	ImplicitTreap c;
	split(*t, l, &a, &b);
	split(b, r - l, &b, &c);
	if (b) apply(b, f);
	merge(t, a, b);
	merge(t, *t, c);
}
fn void reverse(ImplicitTreap* t, sz l, sz r)
{
	ImplicitTreap a;
	ImplicitTreap b;
	ImplicitTreap c;
	split(*t, l, &a, &b);
	split(b, r - l, &b, &c);
	if (b) b.rev = !b.rev;
	merge(t, a, b);
	merge(t, *t, c);
}
