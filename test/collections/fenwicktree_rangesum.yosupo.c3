// @title Point Add Range Sum (Fenwick Tree)
// PROBLEM: https://judge.yosupo.jp/problem/point_add_range_sum

import c3algo::algebra;
import c3algo::io;
import c3algo::collections::fenwicktree;

alias SumLong = Sum{long};
alias Fen = FenwickTree{SumLong};

const int OP_ADD = 0;

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

	SumLong[] values = alloc::new_array(tmem, SumLong, n);
	foreach (&v : values)
	{
		*v = (SumLong) { inp.read(long) };
	}

	Fen ft;
	ft.init_with(mem, values);
	defer ft.free();

	while (queries-- > 0)
	{
		int kind = inp.read(int);
		if (kind == OP_ADD)
		{
			sz p   = inp.read(sz);
			long x = inp.read(long);
			ft.add(p, (SumLong) { x });
		}
		else
		{
			sz l = inp.read(sz);
			sz r = inp.read(sz);
			out.writeln(ft.range(l, r).v);
		}
	}
}