// @title Ordered Set (AVL Tree)
// PROBLEM: https://judge.yosupo.jp/problem/ordered_set

import c3algo::collections::avltree;
import c3algo::io;

alias Set = avltree::AVLTree{int};

const int OP_INSERT    = 0;
const int OP_ERASE     = 1;
const int OP_KTH       = 2;
const int OP_COUNT_LEQ = 3;
const int OP_FLOOR     = 4;

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

	Set set;
	set.init(mem);
	defer set.free();

	for (sz i = 0; i < n; i++)
	{
		set.insert(inp.read(int));
	}

	while (queries-- > 0)
	{
		int kind = inp.read(int);
		int x    = inp.read(int);
		switch (kind)
		{
			case OP_INSERT:
				set.insert(x);
			case OP_ERASE:
				set.erase(x);
			case OP_KTH:
				if ((sz)x > set.len())
				{
					out.writeln(-1);
				}
				else
				{
					out.writeln(set.kth((sz)x - 1));
				}
			case OP_COUNT_LEQ:
				out.writeln(set.count_leq(x));
			case OP_FLOOR:
				out.writeln(set.floor(x) ?? -1);
			default:
				out.writeln(set.ceil(x) ?? -1);
		}
	}
}