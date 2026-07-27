// @title A + B
// PROBLEM: https://judge.yosupo.jp/problem/aplusb

import c3algo::io;

fn void main()
{
	FastInput in;
	in.init(mem);
	defer in.free();
	FastOutput out;
	out.init(mem);
	defer out.free();

	long a = in.read(long);
	long b = in.read(long);
	out.write(a + b);
	out.nl();
}