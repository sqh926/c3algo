// @title Point Add Range Sum (Segment Tree)
// PROBLEM: https://judge.yosupo.jp/problem/point_add_range_sum

import c3algo::algebra;
import c3algo::ds::segtree;
import c3algo::io;

alias SumLong = Sum{long};
alias Seg = SegTree{SumLong};

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
	Seg st @noinit;
	st.init(mem, (sz)n, (SumLong) { 0 });
	for (int i = 0; i < n; i++)
	{
		int x = inp.read(int);
		st.set(i, (SumLong) { x }, 0, 0, st.size);
	}
	while (q-- > 0)
	{
		int kind = inp.read(int);
		if (kind == 0)
		{
			int p = inp.read(int);
			int x = inp.read(int);
			st.set(p, st.get(p).op((SumLong) { x }), 0, 0, st.size);
		}
		else
		{
			int l = inp.read(int);
			int r = inp.read(int);
			out.writeln(st.exec_on_seg(l, r, 0, 0, st.size).v);
		}
	}
}
