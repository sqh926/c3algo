// @title Big Integer Division (hex)
// PROBLEM: https://judge.yosupo.jp/problem/division_of_hex_big_integers

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
			DynBigInt quot;
			quot.tinit();
			DynBigInt rem;
			rem.tinit();
			x.divmod(&y, &quot, &rem);
			out.write(quot.to_string(tmem));
			out.sp();
			out.writeln(rem.to_string(tmem));
		};
	}
}