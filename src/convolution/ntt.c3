// @title NTT
<*
 The number theoretic transform

 @require MOD > 2 : "The modulus must be an odd prime"
*>
module c3algo::convolution::ntt <MOD>;

import c3algo::numbertheory::modint;
import c3algo::numbertheory::factorize;
import c3algo::arith;
import std::core::mem::alloc;

alias Mint = modint::ModInt{MOD};
alias from = modint::from{MOD};

<*
 The longest transform this modulus admits
*>
const usz MAX_LENGTH = (usz)(((ulong)MOD - 1) & (0 - ((ulong)MOD - 1)));

<*
 The smallest generator of the multiplicative group.

 @return "The smallest primitive root modulo `MOD`"
*>
fn long primitive_root() @local
{
	ulong phi                 = (ulong)MOD - 1;
	factorize::UlongList facs = factorize::factorize(mem, phi);
	defer facs.free();

	ulong[64] primes;
	int cnt = 0;
	foreach (p : facs)
	{
		if (cnt == 0 || primes[cnt - 1] != p) primes[cnt++] = p;
	}

	for (ulong g = 2;; g++)
	{
		bool ok = true;
		for (int i = 0; i < cnt; i++)
		{
			if (arith::bpow(g, phi / primes[i], (ulong)MOD) == 1)
			{
				ok = false;
				break;
			}
		}
		if (ok) return (long)g;
	}
}

<*
 Transform in place.

 @param [inout] in : "The values to transform, a power of two of them"
 @param inverse : "Whether to run the inverse transform"

 @require in.len > 0 : "There is nothing to transform"
 @require (in.len & (in.len - 1)) == 0 : "The length has to be a power of two"
 @require in.len <= MAX_LENGTH : "This modulus has no root of unity of that order"
*>
fn void ntt_inplace(Mint[] in, bool inverse)
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

	static long root = 0;
	if (root == 0) root = primitive_root();

	static Mint[] w;
	if (half != 0 && w.len != half)
	{
		if (w.len != 0) mem::free(w);
		w = mem::new_array(Mint, half);
		Mint g    = from(root);
		Mint wlen = g.pow((MOD - 1) / n);
		Mint curw = from(1);
		for (int k = 0; k < half; k++)
		{
			w[k] = curw;
			curw *= wlen;
		}
	}

	for (int len = 2; len <= n; len *= 2)
	{
		int step = n / len;
		for (int i = 0; i < n; i += len)
		{
			for (int j = 0; j < len / 2; j++)
			{
				Mint u = in[i + j];
				Mint v = in[i + j + len / 2] * w[j * step];
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
 Convolve two sequences of residues modulo `MOD`, exactly.

 Unlike the floating point route there is no rounding to worry about here.

 @param [out] dst : "Where the result goes, at least `a.len + b.len - 1` long"
 @param [in] a : "The first sequence"
 @param [in] b : "The second sequence"
 @param [&inout] scratch : "The allocator for the transform buffers"

 @require a.len == 0 || b.len == 0 || dst.len >= a.len + b.len - 1 : "The result does not fit into dst"
 @require a.len == 0 || b.len == 0 || a.len + b.len - 1 <= MAX_LENGTH : "This modulus has no root of unity of that order"
*>
fn void convolution(int[] dst, int[] a, int[] b, Allocator scratch = mem)
{
	int na = (int)a.len;
	int nb = (int)b.len;
	if (na == 0 || nb == 0) return;

	int save = na + nb - 1;
	int n    = 1;
	while (n < save) n *= 2;

	Mint[] fa = alloc::new_array(scratch, Mint, n);
	Mint[] fb = alloc::new_array(scratch, Mint, n);
	defer alloc::free(scratch, fa);
	defer alloc::free(scratch, fb);
	for (int i = 0; i < na; i++) fa[i] = from(a[i]);
	for (int i = 0; i < nb; i++) fb[i] = from(b[i]);

	ntt_inplace(fa, false);
	ntt_inplace(fb, false);
	for (int i = 0; i < n; i++) fa[i] *= fb[i];
	ntt_inplace(fa, true);

	for (int k = 0; k < save; k++) dst[k] = (int)fa[k].val();
}