// @title Factorize
// PROBLEM: https://judge.yosupo.jp/problem/factorize

import c3algo::io;
import c3algo::numtheory::factorize;


fn void main()
{
	FastInput inp;
	inp.init();
	defer inp.free();
	FastOutput out;
	out.init();
	defer out.free();

	int q = inp.read(int);
	while (q-- > 0)
	{
		ulong n = inp.read(ulong);
		UlongList factors = factorize::factorize(mem, n);
		out.write(factors.len());
		foreach (p : factors)
		{
			out.sp();
			out.write(p);
		}
		out.nl();
		factors.free();
	}
}
