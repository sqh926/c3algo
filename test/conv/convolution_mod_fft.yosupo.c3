// @title Convolution (FFT, Mod 1000000007)
// PROBLEM: https://judge.yosupo.jp/problem/convolution_mod_1000000007

import c3algo::conv::fft;
import c3algo::io;
import std::collections::list;

alias Real = double;
alias convolution_mod = fft::convolution_mod{Real};
alias IntList = List{int};

const int MOD = 1000000007;

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

	IntList res = convolution_mod(a, b, MOD);
	for (int i = 0; i < res.len(); i++)
	{
		out.write(res[i]);
		out.sp();
	}
}
