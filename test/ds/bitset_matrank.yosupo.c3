// PROBLEM: https://judge.yosupo.jp/problem/matrix_det_mod_2

import std::io;
import c3algo::io;
import c3algo::ds::bitset;

const MAXN = 1 << 12;
alias Row = BitSet{MAXN};

Row[MAXN] a;
int[MAXN] lead;

fn void main()
{
	FastInput inp;
	inp.init();
	defer inp.free();

	int n = inp.read(int);
	for (int i = 0; i < n; i++)
	{
		String s = inp.read_string();
		foreach (k, c : s) if (c == '1') a[i].set(k);

		for (int j = 0; j < i; j++)
		{
			if (a[i][lead[j]]) a[i].xor_hint(&a[j], lead[j]);
		}
		lead[i] = (int)a[i].min_bit_set();
		if (lead[i] >= n)
		{
			io::printn("0");
			return;
		}
	}
	io::printn("1");
}
