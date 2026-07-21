// @title Convolution (NTT, Mod 998244353)
// PROBLEM: https://judge.yosupo.jp/problem/convolution_mod

import c3algo::conv::ntt;
import c3algo::io;
import std::collections::list;

alias convolution = ntt::convolution{998244353};
alias IntList     = List{int};

fn void main()
{
	FastInput inp;
	inp.init();
	defer inp.free();
	FastOutput out;
	out.init();
	defer out.free();

	int n = inp.read(int);
	int m = inp.read(int);

	IntList a;
	IntList b;
	for (int i = 0; i < n; i++) a.push(inp.read(int));
	for (int i = 0; i < m; i++) b.push(inp.read(int));

	IntList res = convolution(a, b);
	for (int i = 0; i < res.len(); i++)
	{
		out.write(res[i]);
		out.sp();
	}
}
