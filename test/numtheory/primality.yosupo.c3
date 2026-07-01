// @title Primality Test
// PROBLEM: https://judge.yosupo.jp/problem/primality_test

import c3algo::io;
import c3algo::numtheory::primality;


fn void main()
{
	FastInput inp;
	inp.init();
	defer inp.free();
	FastOutput out;
	out.init();
	defer out.free();

	int t = inp.read(int);
	while (t-- > 0)
	{
		ulong n = inp.read(ulong);
		out.writeln((primality::is_prime(n) ? "Yes" : "No"));
	}
}
