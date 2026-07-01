// @title Primality Test (Miller-Rabin)
module c3algo::numtheory::primality;

import c3algo::util::math;


macro miller_test(base, s, d, n)
{
	var $Mod = $Typeof(n);
	$Mod x = math::bpow(base, d, n);
	if (x == 1 || x == n - 1) return false;
	for (var i = 1; i < s; i++)
	{
		x = math::mulmod(x, x, n);
		if (x == n - 1) return false;
	}
	return true;
}


macro is_prime(n)
{
	var $Mod = $Typeof(n);
	if (n < 2) return false;
	if (n == 2 || n == 3) return true;
	if (n % 2 == 0 || (n % 6 != 1 && n % 6 != 5)) return false;
	// n - 1 = d * 2^s
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
