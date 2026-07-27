// @title Integer Factorization (Pollard's rho)
<*
 Complete factorization by Pollard's rho, with Brent's batching.

 https://cp-algorithms.com/algebra/factorization.html
*>
module c3algo::numbertheory::factorize;

import c3algo::arith;
import c3algo::random;
import c3algo::numbertheory::primality;
import std::collections::list;
import std::sort;

alias UlongList = List{ulong};

<*
 One step of the pseudorandom walk, `x * x + c` modulo `n`.

 @param x : "The current member of the sequence"
 @param c : "The additive constant of the walk"
 @param n : "The modulus"

 @require x < n : "The value must be reduced already"
 @require c < n : "The constant must be reduced already"

 @ensure return < n
*>
fn ulong f(ulong x, ulong c, ulong n) @local @inline
{
	ulong r = arith::mulmod(x, x, n);
	return r >= n - c ? r - (n - c) : r + c;
}

<*
 Find one non trivial divisor of a composite `n`.

 @param n : "The number to split, odd and composite"

 @require n > 2 : "There is nothing to split below three"
 @require (n & 1) == 1 : "An even number should have its twos taken off first"
 @require !primality::is_prime(n) : "A prime has no non trivial divisor and the walk would never end"

 @return "A divisor of `n`, neither one nor `n`"

 @ensure return > 1 && return < n
 @ensure n % return == 0
*>
fn ulong get_divisor(ulong n) @local
{
	const int BATCH = 128;
	while (true)
	{
		ulong a = random::next() % (n - 1) + 1;
		ulong b = a;
		ulong c = random::next() % (n - 2) + 2;
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
				q = arith::mulmod(q, diff, n);
			}
			g = arith::gcd(q, n);
		}

		if (g == n)
		{
			g = 1;
			while (g == 1)
			{
				pa = f(pa, c, n);
				pb = f(f(pb, c, n), c, n);
				ulong diff = pa > pb ? pa - pb : pb - pa;
				g = arith::gcd(diff, n);
			}
		}
		if (g != n) return g;
	}
}

<*
 Split `n` apart recursively, appending every prime it is made of.

 @param n : "The number to split"
 @param [&inout] out : "Where the prime factors are appended, in no particular order"
*>
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

<*
 @param factors : "The factors to check"
 @param n : "The number they are supposed to multiply to"

 @return "`true` if every factor is prime and together they make `n`"
*>
macro bool is_factorization_of(UlongList factors, ulong n) @local
{
	ulong product = 1;
	foreach (p : factors)
	{
		if (!primality::is_prime(p)) return false;
		product *= p;
	}
	return product == n;
}

<*
 Factor a number completely.

 @param [&inout] allocator : "The allocator for the returned list"
 @param n : "The number to factor"

 @require n > 0 : "Zero has no factorization"

 @return "The prime factors in ascending order, with multiplicity; empty for one"

 @ensure is_factorization_of(return, n)
*>
fn UlongList factorize(Allocator allocator, ulong n)
{
	UlongList res;
	res.init(allocator);
	factorize_into(n, &res);
	quicksort(&res);
	return res;
}