// @title Point Add Range Sum (Segment Tree)
// PROBLEM: https://judge.yosupo.jp/problem/point_add_range_sum

import c3algo::algebra;
import c3algo::collections::segmenttree;
import c3algo::io;

alias SumLong = Sum{long};
alias Seg = SegmentTree{SumLong};

const int OP_ADD = 0;

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

	SumLong[] values = alloc::new_array(tmem, SumLong, n);
	foreach (&v : values)
	{
		*v = (SumLong) { inp.read(long) };
	}

	Seg st;
	st.init_with(mem, values);
	defer st.free();

	while (queries-- > 0)
	{
		int kind = inp.read(int);
		if (kind == OP_ADD)
		{
			sz p   = inp.read(sz);
			long x = inp.read(long);
			st.set(p, st.get(p).op((SumLong) { x }));
		}
		else
		{
			sz l = inp.read(sz);
			sz r = inp.read(sz);
			out.writeln(st.range(l, r).v);
		}
	}
}