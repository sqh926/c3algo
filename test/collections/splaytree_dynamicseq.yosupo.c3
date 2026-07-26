// @title Dynamic Sequence Range Affine Range Sum (Implicit Splay Tree)
// PROBLEM: https://judge.yosupo.jp/problem/dynamic_sequence_range_affine_range_sum

import c3algo::collections::splaytree;
import c3algo::algebra::affine;
import c3algo::numbertheory::modint;
import c3algo::io;

alias Mint = ModInt{998244353};
alias Elem = SumLen{Mint};
alias Map = Affine{Mint};
alias Tree = splaytree::SplayTree{Elem, Map};

const int OP_INSERT  = 0;
const int OP_ERASE   = 1;
const int OP_REVERSE = 2;
const int OP_AFFINE  = 3;
const int OP_SUM     = 4;

fn Elem elem(long value)
{
	Elem res @noinit;
	res.sum.init(value);
	res.len.init(1);
	return res;
}

fn Map affine_map(long a, long b)
{
	Map res @noinit;
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

	Tree t;
	t.init(mem);
	defer t.free();

	for (sz i = 0; i < n; i++)
	{
		t.push_back(elem(inp.read(long)));
	}

	while (queries-- > 0)
	{
		switch (inp.read(int))
		{
			case OP_INSERT:
				sz at = inp.read(sz);
				long value = inp.read(long);
				t.insert(at, elem(value));
			case OP_ERASE:
				sz at = inp.read(sz);
				t.erase(at);
			case OP_REVERSE:
				sz l = inp.read(sz);
				sz r = inp.read(sz);
				t.reverse(l, r);
			case OP_AFFINE:
				sz l = inp.read(sz);
				sz r = inp.read(sz);
				long a = inp.read(long);
				long b = inp.read(long);
				t.update(l, r, affine_map(a, b));
			case OP_SUM:
				sz l = inp.read(sz);
				sz r = inp.read(sz);
				out.writeln(t.range(l, r).sum.val());
			default:
				unreachable();
		}
	}
}