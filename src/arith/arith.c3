// @title Arithmetic
<*
 Binary gcd, modular exponentiation and modular multiplication.
*>
module c3algo::arith;

import std::math;

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
		$Type mn   = math::min(x, y);
		$Type diff = math::max(x, y) - mn;
		az = diff.ctz();
		y = mn;
		x = diff;
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