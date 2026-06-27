// @title Math
module c3algo::util::math;

import std::math;
import std::core::types;
import std::core::env;

macro _gcd(a, b)
{
	if (a == 0) return math::abs(b);
	if (b == 0) return math::abs(a);

	var $Type = $Typeof(a);
	$Type x = math::abs(a);
	$Type y = math::abs(b);

	int az    = x.ctz();
	int bz    = y.ctz();
	int shift = math::min(az, bz);
	y >>= bz;

	while (x != 0)
	{
		x >>= az;
		$Type diff = y - x;
		az = diff.ctz();
		y = math::min(x, y);
		x = math::abs(diff);
	}
	return y << shift;
}

macro gcd(...)
{
	$Typeof($vaarg[0]) result = $vaarg[0];
	$for var $i = 1; $i < $vaarg.len; $i++:
		$if $defined(result.gcd):
			result = result.gcd($vaarg[$i]);
		$else
			result = _gcd($vaarg[$i], result);
		$endif
	$endfor
	return result;
}


macro mulmod(a, b, m)
{
	var $Mod = $Typeof(m);
	$switch:
		$case !types::is_int($Mod):
			return (a * b) % m;
		$case $Mod::size <= 4:
			$if types::is_signed($Mod):
				return ($Mod)((long)a * (long)b % (long)m);
			$else
				return ($Mod)((ulong)a * (ulong)b % (ulong)m);
			$endif
		$case $Mod::size <= 8:
			$if env::X86_64:
				return ($Mod)mulmod_u64((ulong)a, (ulong)b, (ulong)m);
			$else
				$if types::is_signed($Mod):
					return ($Mod)((int128)a * (int128)b % (int128)m);
				$else
					return ($Mod)((uint128)a * (uint128)b % (uint128)m);
				$endif
			$endif
		$default:
			$Mod result = 0;
			$Mod x      = a % m;
			var y = b;
			while (y != 0)
			{
				if (y & 1)
				{
					result += x;
					if (result >= m) result -= m;
				}
				x += x;
				if (x >= m) x -= m;
				y >>= 1;
			}
			return result;
	$endswitch
}


fn ulong mulmod_u64(ulong a, ulong b, ulong m) @local @inline
{
	uint128 prod = (uint128)a * b;
	ulong hi     = (ulong)(prod >> 64);
	ulong lo     = (ulong)prod;
	ulong r;
	asm
	{
		movq $rax, lo;
		movq $rdx, hi;
		divq m;
		movq r, $rdx;
	}
	return r;
}


macro bpow(a, n, m)
{
	var $Mod = $Typeof(m);
	$Mod result = 1;
	$Mod base   = a % m;
	var exp = n;
	while (exp != 0)
	{
		if (exp & 1) result = mulmod(result, base, m);
		base = mulmod(base, base, m);
		exp >>= 1;
	}
	return result;
}


macro miller_test(base, s, d, n)
{
	var $Mod = $Typeof(n);
	$Mod x = bpow(base, d, n);
	if (x == 1 || x == n - 1) return false;
	for (var i = 1; i < s; i++)
	{
		x = mulmod(x, x, n);
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
