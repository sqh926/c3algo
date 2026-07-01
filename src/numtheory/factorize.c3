// @title Integer Factorization (Pollard's rho)
module c3algo::numtheory::factorize;

import c3algo::util::math;
import c3algo::numtheory::primality;
import std::collections::list;
import std::sort;

alias UlongList = List{ulong};

ulong rng_state @local = 0xdeadbeef;

fn ulong next_rand() @local
{
	ulong x = rng_state;
	x ^= x << 13;
	x ^= x >> 7;
	x ^= x << 17;
	rng_state = x;
	return x;
}


fn ulong f(ulong x, ulong c, ulong n) @local @inline
{
	ulong r = math::mulmod(x, x, n) + c;
	if (r >= n) r -= n;
	return r;
}

fn ulong get_divisor(ulong n) @local
{
	const int BATCH = 128;
	while (true)
	{
		ulong a = next_rand() % (n - 1) + 1;
		ulong b = a;
		ulong c = next_rand() % (n - 2) + 2;
		ulong pa;
		ulong pb;
		ulong g = 1;

		while (g == 1)
		{
			pa = a;
			pb = b;
			ulong q = 1;
			for (int i = 0; i < BATCH; i++)
			{
				a = f(a, c, n);
				b = f(f(b, c, n), c, n);
				ulong diff = a > b ? a - b : b - a;
				q = math::mulmod(q, diff, n);
			}
			g = math::gcd(q, n);
		}

		if (g == n)
		{
			g = 1;
			while (g == 1)
			{
				pa = f(pa, c, n);
				pb = f(f(pb, c, n), c, n);
				ulong diff = pa > pb ? pa - pb : pb - pa;
				g = math::gcd(diff, n);
			}
		}
		if (g != n) return g;
	}
}

fn void factorize_into(ulong n, UlongList* out) @local
{
	if (n <= 1) return;
	if (primality::is_prime(n))
	{
		out.push(n);
		return;
	}
	if (n % 2 == 0)
	{
		out.push(2);
		factorize_into(n / 2, out);
		return;
	}
	ulong d = get_divisor(n);
	factorize_into(d, out);
	factorize_into(n / d, out);
}

fn UlongList factorize(Allocator allocator, ulong n)
{
	UlongList res;
	res.init(allocator);
	factorize_into(n, &res);
	quicksort(&res);
	return res;
}
