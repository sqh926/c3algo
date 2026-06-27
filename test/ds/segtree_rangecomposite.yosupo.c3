// @title Point Set Range Composite
// PROBLEM: https://judge.yosupo.jp/problem/point_set_range_composite

import c3algo::ds::segtree;
import c3algo::algebra::affine;
import c3algo::numtheory::modint;
import c3algo::io;

alias Mint = ModInt{998244353};
alias Aff = Affine{Mint};
alias Seg = SegTree{Aff};

fn Aff affine(long a, long b)
{
	Aff f;
	f.a.init(a);
	f.b.init(b);
	return f;
}

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
	st.init(mem, (sz)n);
	for (int i = 0; i < n; i++)
	{
		long a = inp.read(long);
		long b = inp.read(long);
		st.set(i, affine(a, b), 0, 0, st.size);
	}

	while (q-- > 0)
	{
		int kind = inp.read(int);
		if (kind == 0)
		{
			int p  = inp.read(int);
			long c = inp.read(long);
			long d = inp.read(long);
			st.set(p, affine(c, d), 0, 0, st.size);
		}
		else
		{
			int l    = inp.read(int);
			int r    = inp.read(int);
			long x   = inp.read(long);
			Aff f    = st.range(l, r, 0, 0, st.size);
			Mint res = f.a * x;
			res += f.b;
			out.writeln(res.val());
		}
	}
}
