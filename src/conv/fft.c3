// @title FFT
module c3algo::conv::fft <Real>;

import std::math::complex, std::math, std::time;
import c3algo::arith;

alias Ftype = ComplexNumber{Real};

fn void fft_inplace(Ftype[] in, bool inverse)
{
	int n    = (int)in.len;
	int logn = n.ctz();
	static int[] rev;
	if (rev.len != n)
	{
		if (rev.len != 0) mem::free(rev);
		rev = mem::new_array(int, n);
		for (int i = 0; i < n; i++)
		{
			rev[i] = (rev[i >> 1] >> 1) | ((i & 1) << (logn - 1));
		}
	}
	for (int i = 0; i < n; i++)
	{
		if (i < rev[i]) @swap(in[i], in[rev[i]]);
	}
	static Ftype[] w;
	if (w.len != n / 2)
	{
		if (w.len != 0) mem::free(w);
		int half = n / 2;
		w = mem::new_array(Ftype, half);
		for (int k = 0; k < half; k++)
		{
			Real ang = 2 * (Real)math::PI * k / n;
			w[k] = { .r = (Real)math::cos(ang), .c = (Real)math::sin(ang) };
		}
	}

	for (int len = 2; len <= n; len *= 2)
	{
		int step = n / len;
		for (int i = 0; i < n; i += len)
		{
			for (int j = 0; j < len / 2; j++)
			{
				Ftype u = in[i + j];
				Ftype v = in[i + j + len / 2] * w[j * step];
				in[i + j] = u + v;
				in[i + j + len / 2] = u - v;
			}
		}
	}
	if (inverse)
	{
		in[0] /= n;
		in[n / 2] /= n;
		for (int i = 1; i < n / 2; i++)
		{
			in[i] /= n;
			in[n - i] /= n;
			@swap(in[i], in[n - i]);
		}
	}
}

fn void convolution(long[] dst, long[] a, long[] b, Allocator scratch = mem)
{
	int la   = (int)a.len;
	int lb   = (int)b.len;
	int save = la + lb - 1;
	if (save <= 0) return;
	int n = 1;
	while (n < save) n *= 2;

	Ftype[] h = alloc::new_array(scratch, Ftype, n);
	defer alloc::free(scratch, h);
	for (int i = 0; i < la; i++) h[i].r = (Real)a[i];
	for (int i = 0; i < lb; i++) h[i].c = (Real)b[i];
	fft_inplace(h[..], false);

	Ftype[] c = alloc::new_array(scratch, Ftype, n);
	defer alloc::free(scratch, c);
	Ftype m = { .r = 0, .c = -0.25 };
	for (int k = 0; k < n; k++)
	{
		int j    = (n - k) & (n - 1);
		Ftype hj = h[j].conjugate();
		c[k] = (h[k] + hj) * (h[k] - hj) * m;
	}
	fft_inplace(c[..], true);

	for (int k = 0; k < save; k++) dst[k] = (long)math::round(c[k].r);
}

fn ulong splitmix64(ulong x) @local
{
	x += 0x9E3779B97F4A7C15;
	x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9;
	x = (x ^ (x >> 27)) * 0x94D049BB133111EB;
	return x ^ (x >> 31);
}

fn void load(Ftype[] dst, int[] src, long factor, int mod, long cut) @local
{
	long f  = 1;
	int len = (int)src.len;
	for (int i = 0; i < len; i++)
	{
		long v = (long)src[i] * f % mod;
		dst[i] = { .r = (Real)(v / cut), .c = (Real)(v % cut) };
		f = f * factor % mod;
	}
}

fn void convolution_mod(int[] dst, int[] a, int[] b, int mod, Allocator scratch = mem)
{
	int save = (int)a.len + (int)b.len - 1;
	if (save <= 0) return;
	int n = 1;
	while (n < save) n *= 2;

	long cut = (long)math::ceil(math::sqrt(mod));

	// https://codeforces.com/blog/entry/142860
	// helps to add randomness to the input
	int factor   = 1 + (int)(splitmix64((ulong)time::now()) % (ulong)(mod - 1));
	long ifactor = arith::bpow(factor, mod - 2, mod);

	Ftype[] fa   = alloc::new_array(scratch, Ftype, n);
	Ftype[] fb   = alloc::new_array(scratch, Ftype, n);
	Ftype[] outl = alloc::new_array(scratch, Ftype, n);
	Ftype[] outs = alloc::new_array(scratch, Ftype, n);
	defer alloc::free(scratch, fa);
	defer alloc::free(scratch, fb);
	defer alloc::free(scratch, outl);
	defer alloc::free(scratch, outs);
	load(fa, a, factor, mod, cut);
	load(fb, b, factor, mod, cut);
	// it is possible to combine two of those fft's in one
	// but precision is a problem
	fft_inplace(fa[..], false);
	fft_inplace(fb[..], false);

	Ftype norm_real = { .r = 2.0 * n, .c = 0 };
	Ftype norm_imag = { .r = 0, .c = 2.0 * n };
	for (int i = 0; i < n; i++)
	{
		int j = (n - i) & (n - 1);
		// j behaves the same way as -i (n - i) % n
		outl[j] = (fa[i] + fa[j].conjugate()) * fb[i] / norm_real;
		outs[j] = (fa[i] - fa[j].conjugate()) * fb[i] / norm_imag;
	}
	fft_inplace(outl[..], false);
	fft_inplace(outs[..], false);

	long fk = 1;
	for (int k = 0; k < save; k++)
	{
		long av  = (long)math::round(outl[k].r);
		long bv  = (long)math::round(outl[k].c) + (long)math::round(outs[k].r);
		long cv  = (long)math::round(outs[k].c);
		long val = ((av % mod * cut + bv) % mod * cut + cv) % mod;
		val = (val + mod) % mod * fk % mod;
		fk = fk * ifactor % mod;
		dst[k] = (int)val;
	}
}