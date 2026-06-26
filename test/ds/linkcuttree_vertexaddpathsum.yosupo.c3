// PROBLEM: https://judge.yosupo.jp/problem/dynamic_tree_vertex_add_path_sum

import c3algo::io;
import c3algo::ds::linkcuttree;
import std::core::mem;

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

	Node[] node = mem::new_array(Node, (usz)n);
	for (int i = 0; i < n; i++)
	{
		long a = (long)inp.read(int);
		node[i].val = a;
		node[i].sum = a;
	}
	for (int i = 0; i < n - 1; i++)
	{
		int u = inp.read(int);
		int v = inp.read(int);
		linkcuttree::link(&node[u], &node[v]);
	}
	while (q-- > 0)
	{
		int kind = inp.read(int);
		if (kind == 0)
		{
			int u = inp.read(int);
			int v = inp.read(int);
			int w = inp.read(int);
			int x = inp.read(int);
			linkcuttree::cut(&node[u], &node[v]);
			linkcuttree::link(&node[w], &node[x]);
		}
		else if (kind == 1)
		{
			int p = inp.read(int);
			int x = inp.read(int);
			linkcuttree::add(&node[p], (long)x);
		}
		else
		{
			int u = inp.read(int);
			int v = inp.read(int);
			out.writeln(linkcuttree::path_sum(&node[u], &node[v]));
		}
	}
}
