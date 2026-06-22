// PROBLEM: https://judge.yosupo.jp/problem/point_add_range_sum

import c3algo::ds::segtree;
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
	SegTree st;
	st.init(mem, (sz)n);
	for (int i = 0; i < n; i++)
	{
		int x = inp.read(int);
		st.set(i, x, 0, 0, (sz)n);
	}
	while (q-- > 0)
	{
		int kind = inp.read(int);
		if (kind == 0)
		{
			int p = inp.read(int);
			int x = inp.read(int);
			st.set(p, x, 0, 0, (sz)n);
		}
		else
		{
			int l = inp.read(int);
			int r = inp.read(int);
			out.writeln(st.sum(l, r, 0, 0, (sz)n));
		}
	}
}
