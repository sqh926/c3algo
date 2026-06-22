// PROBLEM: https://judge.yosupo.jp/problem/point_add_range_sum

import c3algo::io;
import c3algo::ds::fenwick;

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

	FenwickTree ft;
	ft.init(mem, n);
	for (int i = 0; i < n; i++)
	{
		int x = inp.read(int);
		ft.set(i, (long)x);
	}
	while (q-- > 0)
	{
		int kind = inp.read(int);
		if (kind == 0)
		{
			int p = inp.read(int);
			int x = inp.read(int);
			ft.set(p, (long)x);
		}
		else
		{
			int l = inp.read(int);
			int r = inp.read(int);
			out.writeln(ft.range((sz)l, (sz)r));
		}
	}
}
