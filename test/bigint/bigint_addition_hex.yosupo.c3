// @title Big Integer Addition (Hex)
// PROBLEM: https://judge.yosupo.jp/problem/addition_of_hex_big_integers

import c3algo::bigint;
import c3algo::io;

alias DynBigInt = bigint::DynBigInt{16};
alias from_string = bigint::from_string{16};

fn void main()
{
	FastInput inp;
	inp.init();
	defer inp.free();
	FastOutput out;
	out.init();
	defer out.free();

	int t = inp.read(int);
	for (int q = 0; q < t; q++)
	{
		@pool()
		{
			DynBigInt x = from_string(inp.read(String), tmem);
			DynBigInt y = from_string(inp.read(String), tmem);
			out.writeln((x + y).to_string(tmem));
		};
	}
}
