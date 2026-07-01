// @title Dynamic Tree Vertex Set Path Composite (Link-Cut Tree)
// PROBLEM: https://judge.yosupo.jp/problem/dynamic_tree_vertex_set_path_composite

import c3algo::ds::lctree;
import c3algo::algebra::affine;
import c3algo::numtheory::modint;
import c3algo::io;

alias Mint = ModInt{998244353};
alias Func = Affine{Mint};
alias Empty = c3algo::algebra::Empty{long};

alias Node = lctree::Node{Func, Empty};
alias new_node = lctree::new_node{Func, Empty};
alias link = lctree::link{Func, Empty};
alias cut = lctree::cut{Func, Empty};
alias path_query = lctree::path_query{Func, Empty};
alias point_set = lctree::point_set{Func, Empty};

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

	int n = inp.read(int);
	int q = inp.read(int);

	Node*[] node = mem::new_array(Node*, (usz)n);
	defer mem::free(node);
	for (int i = 0; i < n; i++)
	{
		long a = inp.read(long);
		long b = inp.read(long);
		node[i] = new_node(func(a, b));
	}
	for (int i = 0; i < n - 1; i++)
	{
		int u = inp.read(int);
		int v = inp.read(int);
		link(node[u], node[v]);
	}
	while (q-- > 0)
	{
		int kind = inp.read(int);
		switch (kind)
		{
			case 0:
				int u = inp.read(int);
				int v = inp.read(int);
				int w = inp.read(int);
				int x = inp.read(int);
				cut(node[u], node[v]);
				link(node[w], node[x]);
			case 1:
				int p = inp.read(int);
				long c = inp.read(long);
				long d = inp.read(long);
				point_set(node[p], func(c, d));
			default:
				int u = inp.read(int);
				int v = inp.read(int);
				long x = inp.read(long);
				Func f = path_query(node[u], node[v]);
				Mint r = f.a * x + f.b;
				out.writeln(r.val());
		}
	}
}
