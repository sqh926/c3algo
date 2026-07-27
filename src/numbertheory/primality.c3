// @title Primality Test (Miller-Rabin)
<*
 A Miller-Rabin test (deterministic for 64-bit integers).

 https://cp-algorithms.com/algebra/primality_tests.html
*>
module c3algo::numbertheory::primality;

import c3algo::arith;

<*
 Ask one base whether it can prove `n` composite.

 @param base : "The base to try, not a multiple of `n`"
 @param s : "How many twos `n - 1` carries"
 @param d : "The odd part of `n - 1`"
 @param n : "The number under test"

 @require n > 3 : "The small cases are not covered by this test"
 @require (n & 1) == 1 : "The number under test must be odd"
 @require s >= 1 : "An odd n - 1 would mean n is even"
 @require (d & 1) == 1 : "d has to be the odd part of n - 1"
 @require (d << s) == n - 1 : "d and s have to decompose n - 1"
 @require base % n != 0 : "A multiple of n witnesses nothing"

 @return "`true` if `base` proves `n` composite"
*>
macro miller_test(base, s, d, n) @local
{
	var $Mod = $Typeof(n);
	$Mod x = arith::bpow(base, d, n);
	if (x == 1 || x == n - 1) return false;
	for (var i = 1; i < s; i++)
	{
		x = arith::mulmod(x, x, n);
		if (x == n - 1) return false;
	}
	return true;
}

<*
 Test a number for primality.

 @param n : "The number to test"

 @require types::is_int($Typeof(n)) : "Only integers are prime or composite"

 @return "`true` if `n` is prime"
*>
macro is_prime(n)
{
	var $Mod = $Typeof(n);
	if (n < 2) return false;
	if (n == 2 || n == 3) return true;
	if (n % 2 == 0 || (n % 6 != 1 && n % 6 != 5)) return false;
	$Mod d = n - 1;
	int s  = 0;
	while ((d & 1) == 0)
	{
		d >>= 1;
		s++;
	}
	$Mod[*] bases = { 2, 325, 9375, 28178, 450775, 9780504, 1795265022 };
	foreach (base : bases)
	{
		if (base % n == 0) continue;
		if (miller_test(base, s, d, n)) return false;
	}
	return true;
}