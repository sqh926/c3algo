// @title Range Reverse Range Sum (Implicit Splay Tree)
// PROBLEM: https://judge.yosupo.jp/problem/range_reverse_range_sum

import c3algo::ds::splaytree;
import c3algo::algebra;
import c3algo::io;

alias Sum = algebra::Sum{long};
struct Empty
{
	char unused;
}
fn Sum Empty.act(self, Sum m) @inline => m;
fn Empty Empty.op(self, Empty o) @inline => self;
fn Empty Empty.e(self) @inline => (Empty) { };

alias Tree = splaytree::SplayTree{Sum, Empty};
alias push_back = splaytree::push_back{Sum, Empty};
alias range = splaytree::range{Sum, Empty};
alias reverse = splaytree::reverse{Sum, Empty};

fn void main()
{
	FastInput inp;
	inp.init();
	defer inp.free();
	FastOutput out;
	out.init();
	defer out.free();

	int n = inp.read(int);
	int q = inp.read(int);

	Tree t;
	for (int i = 0; i < n; i++)
	{
		push_back(&t, (Sum) { inp.read(long) });
	}
	while (q-- > 0)
	{
		int kind = inp.read(int);
		int l    = inp.read(int);
		int r    = inp.read(int);
		if (kind == 0)
		{
			reverse(&t, (sz)l, (sz)r);
		}
		else
		{
			out.writeln(range(&t, (sz)l, (sz)r).v);
		}
	}
}
