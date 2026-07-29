// @title FFT
<*
 The complex fast Fourier transform.

 All the optimization tricks used here, are taken from this article:
 https://codeforces.com/blog/entry/142860
*>
module c3algo::convolution::fft <Real>;

import std::math::complex, std::math;
import c3algo::arith, c3algo::random;

alias Ftype = ComplexNumber{Real};

macro Ftype mul_i(Ftype v) @local => { .r = -v.c, .c = v.r };

// we all love simd <3
alias Pair = Real[<4>];

<*
 L3 cache size ;-)
*>
const int CHUNK = 1 << 16;

macro Pair pair_load(Ftype* p) @local => mem::load((Pair*)p, @alignof(*p));
macro void pair_store(Ftype* p, Pair v) @local => mem::store((Pair*)p, v, @alignof(*p));
macro Pair pair_mul_i(Pair v) @local => swizzle(v, 1, 0, 3, 2) * (Pair) { -1, 1, -1, 1 };

macro Pair pair_mul(Pair v, Ftype w) @local
{
	Pair t = v * w.r;
	Pair s = swizzle(v, 1, 0, 3, 2) * w.c;
	return swizzle2(t - s, t + s, 0, 5, 2, 7);
}

<*
 `table[k] = exp(i * pi * f(k))`, `f(k)` the bits of `k` mirrored.

 @param count : "How many constants are needed, half the length of the transform"

 @require count > 0 : "There is nothing to transform"
*>
fn Ftype[] eval_points(int count) @local
{
	static Ftype[] table;
	if (table.len >= (sz)count) return table;

	if (table.len) mem::free(table);
	table = mem::new_array(Ftype, (sz)count);
	table[0] = { .r = 1, .c = 0 };
	int j = 0;
	for (int k = 1; k < count; k++)
	{
		int bit = count >> 1;
		for (; (j & bit) != 0; bit >>= 1)
		{
			j ^= bit;
		}
		j ^= bit;
		if (k & 1)
		{
			table[k] = { .r = -table[k - 1].c, .c = table[k - 1].r };
			continue;
		}
		Real ang = (Real)(math::PI * j / count);
		table[k] = { .r = (Real)math::cos(ang), .c = (Real)math::sin(ang) };
	}
	return table;
}

fn void fft_pass(Ftype[] in, Ftype[] w, int from, int to, int len, int shift) @local
{
	int quarter = len >> 2;
	for (int i = from; i < to; i += len)
	{
		int node = i >> shift;
		Ftype c  = w[node];
		Ftype d  = w[2 * node];
		for (int j = i; j < i + quarter; j += 2)
		{
			Pair a  = pair_load(&in[j]);
			Pair b  = pair_load(&in[j + quarter]);
			Pair cc = pair_mul(pair_load(&in[j + 2 * quarter]), c);
			Pair cd = pair_mul(pair_load(&in[j + 3 * quarter]), c);
			Pair x  = a + cc;
			Pair y  = pair_mul(b + cd, d);
			Pair z  = a - cc;
			Pair t  = pair_mul_i(pair_mul(b - cd, d));
			pair_store(&in[j], x + y);
			pair_store(&in[j + quarter], x - y);
			pair_store(&in[j + 2 * quarter], z + t);
			pair_store(&in[j + 3 * quarter], z - t);
		}
	}
}

fn void fft_manual(Ftype[] in, Ftype[] w, int from, int to, int len) @local
{
	if (len == 4)
	{
		for (int i = from; i < to; i += 4)
		{
			Ftype c  = w[i >> 2];
			Ftype d  = w[i >> 1];
			Ftype a  = in[i];
			Ftype b  = in[i + 1];
			Ftype cc = in[i + 2] * c;
			Ftype cd = in[i + 3] * c;
			Ftype x  = a + cc;
			Ftype y  = (b + cd) * d;
			Ftype z  = a - cc;
			Ftype t  = mul_i((b - cd) * d);
			in[i] = x + y;
			in[i + 1] = x - y;
			in[i + 2] = z + t;
			in[i + 3] = z - t;
		}
		return;
	}
	if (len == 2)
	{
		for (int i = from; i < to; i += 2)
		{
			Ftype u = in[i];
			Ftype v = in[i + 1] * w[i >> 1];
			in[i] = u + v;
			in[i + 1] = u - v;
		}
	}
}

<*
 Evaluate in place, leaving the values in the order the splits produce them (bitreverse order).

 @param [inout] in : "The coefficients to evaluate, a power of two of them"

 @require in.len > 0 : "There is nothing to transform"
 @require (in.len & (in.len - 1)) == 0 : "The length has to be a power of two"
*>
fn void fft_inplace(Ftype[] in)
{
	int n = (int)in.len;
	if (n == 1) return;
	Ftype[] w = eval_points(n >> 1);

	int shift = 0;
	while ((1 << shift) < n) shift++;

	int len = n;
	for (; len > CHUNK; len >>= 2, shift -= 2) fft_pass(in, w, 0, n, len, shift);

	for (int i = 0; i < n; i += len)
	{
		int l = len;
		int s = shift;
		for (; l >= 8; l >>= 2, s -= 2) fft_pass(in, w, i, i + len, l, s);
		fft_manual(in, w, i, i + len, l);
	}
}

fn void ifft_pass(Ftype[] in, Ftype[] w, int from, int to, int len, int shift) @local
{
	int quarter = len >> 2;
	for (int i = from; i < to; i += len)
	{
		int node = i >> shift;
		Ftype c  = w[node].conjugate();
		Ftype d  = w[2 * node].conjugate();
		for (int j = i; j < i + quarter; j += 2)
		{
			Pair u0 =  pair_load(&in[j]);
			Pair u1 =  pair_load(&in[j + quarter]);
			Pair u2 =  pair_load(&in[j + 2 * quarter]);
			Pair u3 =  pair_load(&in[j + 3 * quarter]);
			Pair x  =  u0 + u1;
			Pair y  =  pair_mul(u0 - u1, d);
			Pair z  =  u2 + u3;
			Pair t  = -pair_mul_i(pair_mul(u2 - u3, d));
			pair_store(&in[j], x + z);
			pair_store(&in[j + quarter], y + t);
			pair_store(&in[j + 2 * quarter], pair_mul(x - z, c));
			pair_store(&in[j + 3 * quarter], pair_mul(y - t, c));
		}
	}
}

fn void ifft_manual(Ftype[] in, Ftype[] w, int from, int to, int len) @local
{
	if (len == 4)
	{
		for (int i = from; i < to; i += 4)
		{
			Ftype c  =  w[i >> 2].conjugate();
			Ftype d  =  w[i >> 1].conjugate();
			Ftype u0 =  in[i];
			Ftype u1 =  in[i + 1];
			Ftype u2 =  in[i + 2];
			Ftype u3 =  in[i + 3];
			Ftype x  =  u0 + u1;
			Ftype y  =  (u0 - u1) * d;
			Ftype z  =  u2 + u3;
			Ftype t  = -mul_i((u2 - u3) * d);
			in[i] = x + z;
			in[i + 1] = y + t;
			in[i + 2] = (x - z) * c;
			in[i + 3] = (y - t) * c;
		}
		return;
	}
	if (len == 2)
	{
		for (int i = from; i < to; i += 2)
		{
			Ftype u = in[i];
			Ftype v = in[i + 1];
			in[i] = u + v;
			in[i + 1] = (u - v) * w[i >> 1].conjugate();
		}
	}
}

<*
 Interpolate in place, undoing `fft_inplace`.

 @param [inout] in : "The evaluations, in the order `fft_inplace` left them"

 @require in.len > 0 : "There is nothing to transform"
 @require (in.len & (in.len - 1)) == 0 : "The length has to be a power of two"
*>
fn void ifft_inplace(Ftype[] in)
{
	int n = (int)in.len;
	if (n == 1) return;
	Ftype[] w = eval_points(n >> 1);

	int len   = n;
	int shift = 0;
	while ((1 << shift) < n) shift++;
	while (len > CHUNK)
	{
		len >>= 2;
		shift -= 2;
	}

	int deep   = len;
	int dshift = shift;
	while (deep >= 8)
	{
		deep >>= 2;
		dshift -= 2;
	}

	for (int i = 0; i < n; i += len)
	{
		ifft_manual(in, w, i, i + len, deep);
		int l = deep << 2;
		int s = dshift + 2;
		for (; l <= len; l <<= 2, s += 2) ifft_pass(in, w, i, i + len, l, s);
	}

	int top = shift + 2;
	for (int l = len << 2; l <= n; l <<= 2, top += 2) ifft_pass(in, w, 0, n, l, top);

	Real scale = (Real)1 / n;
	foreach (&v : in) *v = *v * scale;
}

fn void unpack(Ftype[] h, int p, int q) @local @inline
{
	Ftype t  = { .r = 0, .c = -0.25 };
	Ftype hp = h[p];
	Ftype hq = h[q];
	Ftype cp = hp.conjugate();
	Ftype cq = hq.conjugate();
	h[p] = (hp + cq) * (hp - cq) * t;
	h[q] = (hq + cp) * (hq - cp) * t;
}

<*
 Convolve two integer sequences.

 @param [out] dst : "Where the result goes, at least `a.len + b.len - 1` long"
 @param [in] a : "The first sequence"
 @param [in] b : "The second sequence"
 @param [&inout] scratch : "The allocator for the transform buffer"

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
	fft_inplace(h[..]);

	unpack(h, 0, 0);
	if (n > 1) unpack(h, 1, 1);
	for (int block = 2; block < n; block <<= 1)
	{
		int r = 2 * block - 1;
		for (int l = block; l < r; l++, r--) unpack(h, l, r);
	}
	ifft_inplace(h[..]);

	for (int k = 0; k < save; k++) dst[k] = (long)math::round(h[k].r);
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

<*
 Scale a sequence by consecutive powers of `factor`.

 @param [out] dst : "Where the split values go"
 @param [in] src : "The residues to load"
 @param factor : "The i of the powers each value gets scaled by"
 @param bar : "The modulus"
 @param cut : "Where a value is split, the square root of the modulus rounded up"
*>
fn void load(Ftype[] dst, int[] src, ulong factor, Barrett bar, long cut) @local
{
	Real width = (Real)cut;
	Real inv   = (Real)1 / width;
	long half  = (long)(bar.mod + 1) / 2;
	ulong f    = 1;
	int len    = (int)src.len;
	for (int i = 0; i < len; i++)
	{
		long v = (long)bar.mul((ulong)src[i], f);
		if (v >= half) v -= (long)bar.mod;
		Real x  = (Real)v;
		Real hi = math::round(x * inv);
		dst[i] = { .r = hi, .c = x - hi * width };
		f = bar.mul(f, factor);
	}
}

fn void mix(Ftype[] fa, Ftype[] fb, int p, int q) @local @inline
{
	Ftype ap = fa[p];
	Ftype aq = fa[q];
	Ftype bp = fb[p];
	Ftype bq = fb[q];

	Ftype sump = ap + aq.conjugate();
	Ftype sumq = aq + ap.conjugate();
	Ftype difp = ap - aq.conjugate();
	Ftype difq = aq - ap.conjugate();

	fa[p] = sump * (Real)0.5 * bp;
	fa[q] = sumq * (Real)0.5 * bq;
	fb[p] = (Ftype) { .r = (Real)0.5 * difp.c, .c = (Real)-0.5 * difp.r } * bp;
	fb[q] = (Ftype) { .r = (Real)0.5 * difq.c, .c = (Real)-0.5 * difq.r } * bq;
}

<*
 Convolve two sequences of residues modulo any `mod` that fits in an `int`.

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

	Barrett bar   = arith::barrett((ulong)mod);
	int factor    = 1 + (int)(random::next() % (ulong)(mod - 1));
	ulong ifactor = (ulong)arith::bpow(factor, mod - 2, mod);

	Ftype[] fa = alloc::new_array(scratch, Ftype, n);
	Ftype[] fb = alloc::new_array(scratch, Ftype, n);
	defer alloc::free(scratch, fa);
	defer alloc::free(scratch, fb);
	load(fa, a, (ulong)factor, bar, cut);
	load(fb, b, (ulong)factor, bar, cut);
	fft_inplace(fa[..]);
	fft_inplace(fb[..]);

	mix(fa, fb, 0, 0);
	if (n > 1) mix(fa, fb, 1, 1);
	for (int block = 2; block < n; block <<= 1)
	{
		int hi = 2 * block - 1;
		for (int lo = block; lo < hi; lo++, hi--) mix(fa, fb, lo, hi);
	}
	ifft_inplace(fa[..]);
	ifft_inplace(fb[..]);

	ulong fk = 1;
	for (int k = 0; k < save; k++)
	{
		long av  = (long)math::round(fa[k].r);
		long bv  = (long)math::round(fa[k].c) + (long)math::round(fb[k].r);
		long cv  = (long)math::round(fb[k].c);
		long val = bar.reduce_signed(bar.reduce_signed(av) * cut + bv);
		val = bar.reduce_signed(val * cut + cv);
		dst[k] = (int)bar.mul((ulong)val, fk);
		fk = bar.mul(fk, ifactor);
	}
}
