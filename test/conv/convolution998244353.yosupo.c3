// @title Convolution (Mod 998244353)
// PROBLEM: https://judge.yosupo.jp/problem/convolution_mod

import c3algo::conv::fft;
import c3algo::io;
import c3algo::util::math;
import std::collections::list;
import std::math;
import std::math::complex;
import std::time;

alias Real = double;
alias Ftype = fft::Ftype{Real};
alias fft = fft::fft_inplace{Real};
alias IntList = List{int};

const int MOD  = 998244353;
const long CUT = 31623;

fn ulong splitmix64(ulong x)
{
	x += 0x9E3779B97F4A7C15;
	x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9;
	x = (x ^ (x >> 27)) * 0x94D049BB133111EB;
	return x ^ (x >> 31);
}

fn void load(Ftype[] dst, IntList src, long factor)
{
	long f = 1;
	for (int i = 0; i < src.len(); i++)
	{
		long v = (long)src[i] * f % MOD;
		dst[i] = { .r = (Real)(v / CUT), .c = (Real)(v % CUT) };
		f = f * factor % MOD;
	}
}

fn IntList mult(IntList a, IntList b)
{
	int save = (int)a.len() + (int)b.len() - 1;
	int n    = 1;
	while (n < save) n *= 2;

	int factor   = 1 + (int)(splitmix64((ulong)time::now()) % (ulong)(MOD - 1));
	long ifactor = math::bpow(factor, MOD - 2, MOD);

	Ftype[] fa   = mem::new_array(Ftype, n);
	Ftype[] fb   = mem::new_array(Ftype, n);
	Ftype[] outl = mem::new_array(Ftype, n);
	Ftype[] outs = mem::new_array(Ftype, n);
	load(fa, a, factor);
	load(fb, b, factor);

	fft(fa[..], false);
	fft(fb[..], false);

	Ftype norm_real = { .r = 2.0 * n, .c = 0 };
	Ftype norm_imag = { .r = 0, .c = 2.0 * n };
	for (int i = 0; i < n; i++)
	{
		int j = (n - i) & (n - 1);
		outl[j] = (fa[i] + fa[j].conjugate()) * fb[i] / norm_real;
		outs[j] = (fa[i] - fa[j].conjugate()) * fb[i] / norm_imag;
	}
	fft(outl[..], false);
	fft(outs[..], false);

	IntList res;
	long fk = 1;
	for (int k = 0; k < save; k++)
	{
		long av  = (long)math::round(outl[k].r);
		long bv  = (long)math::round(outl[k].c) + (long)math::round(outs[k].r);
		long cv  = (long)math::round(outs[k].c);
		long val = ((av % MOD * CUT + bv) % MOD * CUT + cv) % MOD;
		val = (val + MOD) % MOD * fk % MOD;
		fk = fk * ifactor % MOD;
		res.push((int)val);
	}
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

	int n = inp.read(int);
	int m = inp.read(int);

	IntList a;
	IntList b;
	for (int i = 0; i < n; i++) a.push(inp.read(int));
	for (int i = 0; i < m; i++) b.push(inp.read(int));

	IntList res = mult(a, b);
	for (int i = 0; i < res.len(); i++)
	{
		out.write(res[i]);
		out.sp();
	}
}
