// @title Point Set Range Composite
// PROBLEM: https://judge.yosupo.jp/problem/point_set_range_composite

import c3algo::collections::segmenttree;
import c3algo::algebra::action;
import c3algo::numbertheory::modint;
import c3algo::io;

alias Mint = ModInt{998244353};
alias Aff = Affine{Mint};
alias Seg = SegmentTree{Aff};

const int OP_SET = 0;

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
	inp.init(mem);
	defer inp.free();

	FastOutput out;
	out.init(mem);
	defer out.free();

	sz n       = inp.read(sz);
	sz queries = inp.read(sz);

	Seg st;
	st.init(mem, n);
	defer st.free();

	for (sz i = 0; i < n; i++)
	{
		long a = inp.read(long);
		long b = inp.read(long);
		st.set(i, affine(a, b));
	}

	while (queries-- > 0)
	{
		int kind = inp.read(int);
		if (kind == OP_SET)
		{
			sz p   = inp.read(sz);
			long c = inp.read(long);
			long d = inp.read(long);
			st.set(p, affine(c, d));
		}
		else
		{
			sz l     = inp.read(sz);
			sz r     = inp.read(sz);
			long x   = inp.read(long);
			Aff f    = st.range(l, r);
			Mint res = f.a * x;
			res += f.b;
			out.writeln(res.val());
		}
	}
}