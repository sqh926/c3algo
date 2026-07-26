// @title Union Find
// PROBLEM: https://judge.yosupo.jp/problem/unionfind

import c3algo::collections::unionfind;
import c3algo::io;

const int OP_UNITE = 0;

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

	UnionFind uf;
	uf.init(mem, n);
	defer uf.free();

	while (queries-- > 0)
	{
		int kind = inp.read(int);
		sz u     = inp.read(sz);
		sz v     = inp.read(sz);
		if (kind == OP_UNITE)
		{
			uf.unite(u, v);
		}
		else
		{
			out.writeln(uf.same(u, v) ? '1' : '0');
		}
	}
}