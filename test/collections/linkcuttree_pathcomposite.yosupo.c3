// @title Dynamic Tree Vertex Set Path Composite (Link-Cut Tree)
// PROBLEM: https://judge.yosupo.jp/problem/dynamic_tree_vertex_set_path_composite

import c3algo::collections::linkcuttree;
import c3algo::algebra;
import c3algo::algebra::affine;
import c3algo::numbertheory::modint;
import c3algo::io;

alias Mint = ModInt{998244353};
alias Func = Affine{Mint};
alias Identity = algebra::Empty{long};
alias Tree = linkcuttree::LinkCutTree{Func, Identity};

const int OP_RELINK = 0;
const int OP_SET    = 1;

fn Func func(long a, long b)
{
	Func res @noinit;
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

	Func[] values = alloc::new_array(tmem, Func, n);
	foreach (&v : values)
	{
		long a = inp.read(long);
		long b = inp.read(long);
		*v = func(a, b);
	}

	Tree t;
	t.init_with(mem, values);
	defer t.free();

	for (sz i = 0; i < n - 1; i++)
	{
		sz u = inp.read(sz);
		sz v = inp.read(sz);
		t.link(u, v);
	}

	while (queries-- > 0)
	{
		switch (inp.read(int))
		{
			case OP_RELINK:
				sz u = inp.read(sz);
				sz v = inp.read(sz);
				sz w = inp.read(sz);
				sz x = inp.read(sz);
				t.cut(u, v);
				t.link(w, x);
			case OP_SET:
				sz p = inp.read(sz);
				long c = inp.read(long);
				long d = inp.read(long);
				t.set(p, func(c, d));
			default:
				sz u = inp.read(sz);
				sz v = inp.read(sz);
				long x = inp.read(long);
				Func f = t.path(u, v);
				Mint r = f.a * x + f.b;
				out.writeln(r.val());
		}
	}
}