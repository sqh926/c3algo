// @title Range Affine Range Sum (Lazy Segment Tree)
// PROBLEM: https://judge.yosupo.jp/problem/range_affine_range_sum

import c3algo::collections::lazysegmenttree;
import c3algo::algebra::affine;
import c3algo::numbertheory::modint;
import c3algo::io;

alias Mint = ModInt{998244353};
alias Elem = SumLen{Mint};
alias Map = Affine{Mint};
alias Seg = LazySegmentTree{Elem, Map};

const int OP_AFFINE = 0;

fn Elem elem(long value)
{
	Elem res @noinit;
	res.sum.init(value);
	res.len.init(1);
	return res;
}

fn Map affine_map(long a, long b)
{
	Map res @noinit;
	res.a.init(a);
	res.b.init(b);
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

	sz n       = inp.read(sz);
	sz queries = inp.read(sz);

	Elem[] values = alloc::new_array(tmem, Elem, n);
	foreach (&v : values)
	{
		*v = elem(inp.read(long));
	}

	Seg st;
	st.init_with(mem, values);
	defer st.free();

	while (queries-- > 0)
	{
		int kind = inp.read(int);
		sz l     = inp.read(sz);
		sz r     = inp.read(sz);
		if (kind == OP_AFFINE)
		{
			long a = inp.read(long);
			long b = inp.read(long);
			st.update(l, r, affine_map(a, b));
		}
		else
		{
			out.writeln(st.range(l, r).sum.val());
		}
	}
}