// @title Big Integer Multiplication (Hex)
// PROBLEM: https://judge.yosupo.jp/problem/multiplication_of_hex_big_integers

import c3algo::bigint;
import c3algo::io;

alias DynBigInt = bigint::DynBigInt{16};

fn void main()
{
	FastInput inp;
	inp.init(mem);
	defer inp.free();
	FastOutput out;
	out.init(mem);
	defer out.free();

	int t = inp.read(int);
	for (int q = 0; q < t; q++)
	{
		@pool()
		{
			DynBigInt x;
			x.tinit_with(inp.read(String));
			DynBigInt y;
			y.tinit_with(inp.read(String));
			out.writeln((x * y).to_string(tmem));
		};
	}
}
