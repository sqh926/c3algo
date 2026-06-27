// @title Range Affine Range Sum (Lazy Segment Tree)
// PROBLEM: https://judge.yosupo.jp/problem/range_affine_range_sum

import c3algo::ds::lazyseg;
import c3algo::algebra::affine;
import c3algo::numtheory::modint;
import c3algo::io;
import std::core::mem;

alias Mint = ModInt{998244353};
alias Agg = SumLen{Mint};
alias Map = Affine{Mint};
alias Seg = LazySeg{Agg, Map};

fn Map map(long a, long b)
{
	Map res @noinit;
	res.a.init(a);
	res.b.init(b);
	return res;
}

fn Agg agg(long a, long b)
{
	Agg res @noinit;
	res.sum.init(a);
	res.len.init(b);
	return res;
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
	defer st.free();

	for (int i = 0; i < n; i++)
	{
		long a = inp.read(long);
		st.set(i, agg(a, 1), 0, 0, st.size);
	}


	while (q-- > 0)
	{
		int kind = inp.read(int);
		if (kind == 0)
		{
			int l  = inp.read(int);
			int r  = inp.read(int);
			long b = inp.read(long);
			long c = inp.read(long);
			st.update((sz)l, (sz)r, map(b, c), 0, 0, st.size);
		}
		else
		{
			int l = inp.read(int);
			int r = inp.read(int);
			out.writeln(st.range((sz)l, (sz)r, 0, 0, st.size).sum.val());
		}
	}
}
