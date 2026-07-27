// @title FFT
<*
 The complex fast Fourier transform, and the convolutions built on top of it.
*>
module c3algo::convolution::fft <Real>;

import std::math::complex, std::math, std::time;
import c3algo::arith;

alias Ftype = ComplexNumber{Real};

<*
 Transform in place.

 @param [inout] in : "The values to transform, a power of two of them"
 @param inverse : "Whether to run the inverse transform"

 @require in.len > 0 : "There is nothing to transform"
 @require (in.len & (in.len - 1)) == 0 : "The length has to be a power of two"
*>
fn void fft_inplace(Ftype[] in, bool inverse)
{
	int n    = (int)in.len;
	int half = n >> 1;

	static int[] rev;
	if (rev.len != n)
	{
		if (rev.len != 0) mem::free(rev);
		rev = mem::new_array(int, n);
		for (int i = 0; i < n; i++)
		{
			rev[i] = (rev[i >> 1] >> 1) | ((i & 1) == 0 ? 0 : half);
		}
	}
	for (int i = 0; i < n; i++)
	{
		if (i < rev[i]) @swap(in[i], in[rev[i]]);
	}

	static Ftype[] w;
	if (half != 0 && w.len != half)
	{
		if (w.len != 0) mem::free(w);
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

<*
 Convolve two integer sequences.

 @param [out] dst : "Where the result goes, at least `a.len + b.len - 1` long"
 @param [in] a : "The first sequence"
 @param [in] b : "The second sequence"
 @param [&inout] scratch : "The allocator for the transform buffers"

 @require a.len == 0 || b.len == 0 || dst.len >= a.len + b.len - 1 : "The result does not fit into dst"
*>
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

<*
 @param [in] values : "The values to look over"
 @param limit : "The modulus they are meant to be reduced against"

 @return "`true` if every value is a residue modulo `limit`"
*>
macro bool are_residues(int[] values, int limit) @local
{
	foreach (v : values)
	{
		if (v < 0 || v >= limit) return false;
	}
	return true;
}

fn ulong splitmix64(ulong x) @local
{
	x += 0x9E3779B97F4A7C15;
	x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9;
	x = (x ^ (x >> 27)) * 0x94D049BB133111EB;
	return x ^ (x >> 31);
}

<*
 Scale a sequence by consecutive powers of `factor` and split every value across the two axes.

 @param [out] dst : "Where the split values go"
 @param [in] src : "The residues to load"
 @param factor : "The base of the powers each value gets scaled by"
 @param mod : "The modulus"
 @param cut : "Where a value is split, the square root of the modulus rounded up"
*>
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

<*
 Convolve two sequences of residues modulo any `mod` that fits in an `int`.

 https://codeforces.com/blog/entry/142860

 @param [out] dst : "Where the result goes, at least `a.len + b.len - 1` long"
 @param [in] a : "The first sequence, residues modulo `mod`"
 @param [in] b : "The second sequence, residues modulo `mod`"
 @param mod : "The modulus, prime, so that the scaling factor can be inverted"
 @param [&inout] scratch : "The allocator for the transform buffers"

 @require mod > 1 : "The modulus must be greater than one"
 @require a.len == 0 || b.len == 0 || dst.len >= a.len + b.len - 1 : "The result does not fit into dst"
 @require are_residues(a, mod) && are_residues(b, mod) : "Every input has to be reduced already"
*>
fn void convolution_mod(int[] dst, int[] a, int[] b, int mod, Allocator scratch = mem)
{
	int save = (int)a.len + (int)b.len - 1;
	if (save <= 0) return;
	int n = 1;
	while (n < save) n *= 2;

	long cut = (long)math::ceil(math::sqrt(mod));

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
	fft_inplace(fa[..], false);
	fft_inplace(fb[..], false);

	Ftype norm_real = { .r = 2.0 * n, .c = 0 };
	Ftype norm_imag = { .r = 0, .c = 2.0 * n };
	for (int i = 0; i < n; i++)
	{
		int j = (n - i) & (n - 1);
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