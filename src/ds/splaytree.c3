// @title Implicit Splay Tree
<*
 @require concept::@is_monoid(Monoid)
 @require concept::@is_action(Action, Monoid)
*>
module c3algo::ds::splaytree <Monoid, Action>;
import c3algo::algebra::concept;

const int L = 0;
const int R = 1;

struct Node
{
	Monoid val;
	Monoid agg;
	Action lazy;
	bool rev;
	sz size;
	Node* parent;
	Node*[2] child;
}
alias SplayTree = Node*;

fn SplayTree new_node(Monoid v)
{
	Node* n = mem::new(Node);
	n.val = v;
	n.agg = v;
	n.lazy = ((Action) { }).e();
	n.size = 1;
	return n;
}

fn sz safe_size(SplayTree t) @inline => t ? t.size : 0;
fn Monoid safe_agg(SplayTree t) @inline => t ? t.agg : ((Monoid) { }).e();

fn void apply(SplayTree t, Action f) @inline
{
	t.val = f.act(t.val);
	t.agg = f.act(t.agg);
	t.lazy = t.lazy.op(f);
}

fn void pull(SplayTree t)
{
	t.agg = safe_agg(t.child[L]).op(t.val).op(safe_agg(t.child[R]));
	t.size = 1 + safe_size(t.child[L]) + safe_size(t.child[R]);
}

fn void push(SplayTree t)
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

fn void rotate(SplayTree x)
{
	Node* p = x.parent;
	Node* g = p.parent;
	int dir = p.child[R] == x ? R : L;
	int opp = dir ^ 1;
	p.child[dir] = x.child[opp];
	if (x.child[opp]) x.child[opp].parent = p;
	x.child[opp] = p;
	p.parent = x;
	x.parent = g;
	if (g)
	{
		if (g.child[L] == p)
		{
			g.child[L] = x;
		}
		else
		{
			g.child[R] = x;
		}
	}
	pull(p);
	pull(x);
}

fn void splay(SplayTree x)
{
	while (x.parent)
	{
		Node* p = x.parent;
		if (p.parent)
		{
			bool same = (p.parent.child[L] == p) == (p.child[L] == x);
			if (same)
			{
				rotate(p);
			}
			else
			{
				rotate(x);
			}
		}
		rotate(x);
	}
}

fn SplayTree kth_node(SplayTree t, sz k)
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

fn void split(SplayTree t, sz k, SplayTree* a, SplayTree* b)
{
	if (k == 0)
	{
		*a = null;
		*b = t;
		return;
	}
	if (k >= safe_size(t))
	{
		*a = t;
		*b = null;
		return;
	}
	SplayTree x = kth_node(t, k - 1);
	splay(x);
	SplayTree right = x.child[R];
	x.child[R] = null;
	if (right) right.parent = null;
	pull(x);
	*a = x;
	*b = right;
}

fn void merge(SplayTree* t, SplayTree a, SplayTree b)
{
	if (!a || !b)
	{
		(*t) = a ? a : b;
		return;
	}
	SplayTree x = a;
	push(x);
	while (x.child[R])
	{
		x = x.child[R];
		push(x);
	}
	splay(x);
	x.child[R] = b;
	b.parent = x;
	pull(x);
	*t = x;
}

fn void push_back(SplayTree* t, Monoid v)
{
	merge(t, *t, new_node(v));
}

fn void insert(SplayTree* t, sz pos, Monoid v)
{
	SplayTree a;
	SplayTree b;
	split(*t, pos, &a, &b);
	merge(t, a, new_node(v));
	merge(t, *t, b);
}

fn void erase(SplayTree* t, sz pos)
{
	SplayTree a;
	SplayTree m;
	SplayTree b;
	split(*t, pos, &a, &b);
	split(b, 1, &m, &b);
	if (m) mem::free(m);
	merge(t, a, b);
}

fn Monoid range(SplayTree* t, sz l, sz r)
{
	SplayTree a;
	SplayTree b;
	SplayTree c;
	split(*t, l, &a, &b);
	split(b, r - l, &b, &c);
	Monoid res = safe_agg(b);
	merge(t, a, b);
	merge(t, *t, c);
	return res;
}

fn void update(SplayTree* t, sz l, sz r, Action f)
{
	SplayTree a;
	SplayTree b;
	SplayTree c;
	split(*t, l, &a, &b);
	split(b, r - l, &b, &c);
	if (b) apply(b, f);
	merge(t, a, b);
	merge(t, *t, c);
}

fn void reverse(SplayTree* t, sz l, sz r)
{
	SplayTree a;
	SplayTree b;
	SplayTree c;
	split(*t, l, &a, &b);
	split(b, r - l, &b, &c);
	if (b) b.rev = !b.rev;
	merge(t, a, b);
	merge(t, *t, c);
}

fn SplayTree kth(SplayTree* t, sz k)
{
	SplayTree x = kth_node(*t, k);
	if (x)
	{
		splay(x);
		*t = x;
	}
	return x;
}
