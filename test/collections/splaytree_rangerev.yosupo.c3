// @title Range Reverse Range Sum (Implicit Splay Tree)
// PROBLEM: https://judge.yosupo.jp/problem/range_reverse_range_sum

import c3algo::collections::splaytree;
import c3algo::algebra;
import c3algo::io;

alias Sum = algebra::Sum{long};

struct Identity
{
	char unused;
}
fn Sum Identity.act(self, Sum m) @inline => m;
fn Identity Identity.op(self, Identity other) @inline => self;
fn Identity Identity.e(self) @inline => (Identity) { };

alias Tree = splaytree::SplayTree{Sum, Identity};

const int OP_REVERSE = 0;

fn void main()
{
	FastInput inp;
	inp.init();
	defer inp.free();

	FastOutput out;
	out.init();
	defer out.free();

	sz n       = inp.read(sz);
	sz queries = inp.read(sz);

	Tree t;
	t.init(mem);
	defer t.free();

	for (sz i = 0; i < n; i++)
	{
		t.push_back((Sum) { .v = inp.read(long) });
	}

	while (queries-- > 0)
	{
		int kind = inp.read(int);
		sz l     = inp.read(sz);
		sz r     = inp.read(sz);
		if (kind == OP_REVERSE)
		{
			t.reverse(l, r);
		}
		else
		{
			out.writeln(t.range(l, r).v);
		}
	}
}