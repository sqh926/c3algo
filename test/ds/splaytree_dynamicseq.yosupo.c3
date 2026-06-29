// @title Dynamic Sequence Range Affine Range Sum (Implicit Splay Tree)
// PROBLEM: https://judge.yosupo.jp/problem/dynamic_sequence_range_affine_range_sum

import c3algo::ds::splaytree;
import c3algo::algebra::affine;
import c3algo::numtheory::modint;
import c3algo::io;

alias Mint = ModInt{998244353};
alias Agg = SumLen{Mint};
alias Map = Affine{Mint};

alias Tree = splaytree::SplayTree{Agg, Map};
alias push_back = splaytree::push_back{Agg, Map};
alias insert = splaytree::insert{Agg, Map};
alias erase = splaytree::erase{Agg, Map};
alias reverse = splaytree::reverse{Agg, Map};
alias update = splaytree::update{Agg, Map};
alias range = splaytree::range{Agg, Map};

fn Map map(long a, long b)
{
	Map res @noinit;
	res.a.init(a);
	res.b.init(b);
	return res;
}

fn Agg agg(long a, long b)
{
	Agg res @noinit;
	res.sum.init(a);
	res.len.init(b);
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

	Tree t;
	for (int i = 0; i < n; i++)
	{
		push_back(&t, agg(inp.read(long), 1));
	}
	while (q-- > 0)
	{
		int kind = inp.read(int);
		switch (kind)
		{
			case 0:
				int i = inp.read(int);
				long x = inp.read(long);
				insert(&t, (sz)i, agg(x, 1));
			case 1:
				int i = inp.read(int);
				erase(&t, (sz)i);
			case 2:
				int l = inp.read(int);
				int r = inp.read(int);
				reverse(&t, (sz)l, (sz)r);
			case 3:
				int l = inp.read(int);
				int r = inp.read(int);
				long b = inp.read(long);
				long c = inp.read(long);
				update(&t, (sz)l, (sz)r, map(b, c));
			default:
				int l = inp.read(int);
				int r = inp.read(int);
				out.writeln(range(&t, (sz)l, (sz)r).sum.val());
		}
	}
}
