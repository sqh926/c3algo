// @title Dynamic Tree Vertex Add Path Sum (Link-Cut Tree)
// PROBLEM: https://judge.yosupo.jp/problem/dynamic_tree_vertex_add_path_sum

import c3algo::collections::linkcuttree;
import c3algo::algebra;
import c3algo::io;

alias Sum = algebra::Sum{long};
alias Identity = algebra::Empty{long};
alias Tree = linkcuttree::LinkCutTree{Sum, Identity};

const int OP_RELINK = 0;
const int OP_ADD    = 1;

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

	Sum[] values = alloc::new_array(tmem, Sum, n);
	foreach (&v : values)
	{
		*v = (Sum) { .v = inp.read(long) };
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
			case OP_ADD:
				sz p = inp.read(sz);
				long x = inp.read(long);
				t.set(p, (Sum) { .v = t.get(p).v + x });
			default:
				sz u = inp.read(sz);
				sz v = inp.read(sz);
				out.writeln(t.path(u, v).v);
		}
	}
}