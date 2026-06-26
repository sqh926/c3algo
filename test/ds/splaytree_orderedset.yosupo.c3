// PROBLEM: https://judge.yosupo.jp/problem/ordered_set

import c3algo::io;
import c3algo::ds::splaytree;

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

	SplayTree tree = null;

	for (int i = 0; i < n; i++)
	{
		int x = inp.read(int);
		splaytree::insert(&tree, x);
	}
	for (int i = 0; i < q; i++)
	{
		int kind = inp.read(int);
		int x    = inp.read(int);
		if (kind == 0)
		{
			splaytree::insert(&tree, x);
		}
		else if (kind == 1)
		{
			splaytree::erase(&tree, x);
		}
		else if (kind == 2)
		{
			sz s = tree.size();
			if ((sz)x > s)
			{
				out.writeln(-1);
			}
			else
			{
				out.writeln(splaytree::kth(&tree, (sz)x - 1));
			}
		}
		else if (kind == 3)
		{
			out.writeln(splaytree::count_leq(&tree, x));
		}
		else if (kind == 4)
		{
			out.writeln(splaytree::floor(&tree, x));
		}
		else
		{
			out.writeln(splaytree::ceil(&tree, x));
		}
	}
}
