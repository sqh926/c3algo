// @title Dynamic Tree Vertex Add Path Sum (Link-Cut Tree)
// PROBLEM: https://judge.yosupo.jp/problem/dynamic_tree_vertex_add_path_sum

import c3algo::collections::linkcuttree;
import c3algo::algebra;
import c3algo::io;

alias Sum = algebra::Sum{long};
alias Empty = algebra::Empty{long};

alias Node = linkcuttree::Node{Sum, Empty};
alias new_node = linkcuttree::new_node{Sum, Empty};
alias link = linkcuttree::link{Sum, Empty};
alias cut = linkcuttree::cut{Sum, Empty};
alias path_query = linkcuttree::path_query{Sum, Empty};
alias point_set = linkcuttree::point_set{Sum, Empty};

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
		node[i] = new_node((Sum) { inp.read(long) });
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
				long x = inp.read(long);
				point_set(node[p], (Sum) { node[p].val.v + x });
			default:
				int u = inp.read(int);
				int v = inp.read(int);
				out.writeln(path_query(node[u], node[v]).v);
		}
	}
}