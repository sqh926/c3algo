// @title NTT
module c3algo::conv::ntt <MOD>;

import c3algo::numtheory::modint;
import c3algo::numtheory::factorize;
import c3algo::util::bpow;
import std::collections::list;

alias Mint = modint::ModInt{MOD};
alias from = modint::from{MOD};
alias IntList = List{int};

fn long primitive_root() @local
{
	ulong phi                 = (ulong)MOD - 1; // assuming `MOD` is prime.
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
			if (bpow::bpow(g, phi / primes[i], (ulong)MOD) == 1)
			{
				ok = false;
				break;
			}
		}
		if (ok) return (long)g;
	}
}

fn void ntt_inplace(Mint[] in, bool inverse)
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

	static long root = 0;
	if (root == 0) root = primitive_root();

	static Mint[] w;
	if (w.len != n)
	{
		if (w.len != 0) mem::free(w);
		int half = n / 2;
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

fn IntList convolution(IntList a, IntList b)
{
	IntList res;
	if (a.len() == 0 || b.len() == 0) return res;

	int save = (int)a.len() + (int)b.len() - 1;
	int n    = 1;
	while (n < save) n *= 2;

	Mint[] fa = mem::new_array(Mint, n);
	Mint[] fb = mem::new_array(Mint, n);
	defer mem::free(fa);
	defer mem::free(fb);
	for (int i = 0; i < a.len(); i++) fa[i] = from(a[i]);
	for (int i = 0; i < b.len(); i++) fb[i] = from(b[i]);

	ntt_inplace(fa, false);
	ntt_inplace(fb, false);
	for (int i = 0; i < n; i++) fa[i] *= fb[i];
	ntt_inplace(fa, true);

	for (int k = 0; k < save; k++) res.push((int)fa[k].val());
	return res;
}
