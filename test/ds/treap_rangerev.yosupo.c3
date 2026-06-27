// @title Range Reverse Range Sum
// PROBLEM: https://judge.yosupo.jp/problem/range_reverse_range_sum

import c3algo::ds::treap;
import c3algo::io;


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

	Treap t = null;
	for (int i = 0; i < n; i++)
	{
		int x = inp.read(int);
		treap::append(&t, x);
	}
	while (q-- > 0)
	{
		int kind = inp.read(int);
		int l    = inp.read(int);
		int r    = inp.read(int);
		if (kind == 0)
		{
			treap::rev(&t, l, r);
		}
		else
		{
			out.writeln(treap::range(&t, l, r));
		}
	}
}
