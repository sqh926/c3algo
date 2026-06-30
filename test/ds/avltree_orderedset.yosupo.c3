// @title Ordered Set (AVL Tree)
// PROBLEM: https://judge.yosupo.jp/problem/ordered_set

import c3algo::ds::avltree;
import c3algo::io;

alias Set = avltree::AVLTree{int};
alias insert = avltree::insert{int};
alias erase = avltree::erase{int};
alias size = avltree::size{int};
alias kth = avltree::kth{int};
alias count_leq = avltree::count_leq{int};
alias floor = avltree::floor{int};
alias ceil = avltree::ceil{int};

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

	Set tree = null;
	for (int i = 0; i < n; i++)
	{
		insert(&tree, inp.read(int));
	}
	for (int i = 0; i < q; i++)
	{
		int kind = inp.read(int);
		int x    = inp.read(int);
		switch (kind)
		{
			case 0:
				insert(&tree, x);
			case 1:
				erase(&tree, x);
			case 2:
				if ((sz)x > size(&tree))
				{
					out.writeln(-1);
				}
				else
				{
					out.writeln(kth(&tree, (sz)x - 1));
				}
			case 3:
				out.writeln(count_leq(&tree, x));
			case 4:
				out.writeln(floor(&tree, x) ?? -1);
			default:
				out.writeln(ceil(&tree, x) ?? -1);
		}
	}
}
