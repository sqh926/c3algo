// @title Union Find
// PROBLEM: https://judge.yosupo.jp/problem/unionfind

import c3algo::ds::unionfind;
import c3algo::io;

fn void main()
{
	FastInput inp @noinit;
	inp.init();
	defer inp.free();

	FastOutput out @noinit;
	out.init();
	defer out.free();

	int n = inp.read(int);
	int q = inp.read(int);

	UnionFind uf;
	uf.init((usz)n);
	defer uf.free();

	for (int i = 0; i < q; i++)
	{
		int t = inp.read(int);
		int u = inp.read(int);
		int v = inp.read(int);
		if (t == 0)
		{
			uf.unite(u, v);
		}
		else
		{
			out.writeln(uf.same(u, v) ? '1' : '0');
		}
	}
}
