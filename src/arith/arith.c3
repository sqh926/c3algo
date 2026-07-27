// @title Arithmetic
<*
 Binary gcd, modular multiplication and modular exponentiation.
*>
module c3algo::arith;

import std::math;

<*
 The binary gcd

 @return "The greatest common divisor of `a` and `b`, never negative"
*>
macro binary_gcd(a, b) @local
{
	var $Type = $Typeof(a);
	$Type x = a;
	$Type y = b;
	$if types::is_signed($Type):
		if (x < 0) x = -x;
		if (y < 0) y = -y;
	$endif

	if (x == 0) return y;
	if (y == 0) return x;

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

<*
 @return "The greatest common divisor of every argument"
*>
macro gcd(...)
{
	$Typeof($vaarg[0]) result = $vaarg[0];
	$for var $i = 1; $i < $vaarg.len; $i++:
		$if $defined(result.gcd):
			result = result.gcd($vaarg[$i]);
		$else
			result = binary_gcd($vaarg[$i], result);
		$endif
	$endfor
	return result;
}

<*
 Multiply two residues modulo `m`.

 Both operands have to be reduced already

 @param a : "The first factor, below `m`"
 @param b : "The second factor, below `m`"
 @param m : "The modulus"

 @require m > 0 : "The modulus must be positive"
 @require a < m : "The first factor must be reduced already"
 @require b < m : "The second factor must be reduced already"

 @return "`a * b` modulo `m`"
*>
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
			return ($Mod)mulmod_u64((ulong)a, (ulong)b, (ulong)m);
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

<*
 The remainder of a 128 bit product divided by a 64 bit modulus, out of two 64 bit divisions.

 https://github.com/hcs0/Hackers-Delight/blob/master/divlu.c.txt

 @param a : "The first factor, below `m`"
 @param b : "The second factor, below `m`"
 @param m : "The modulus"

 @require m > 0 : "The modulus must be positive"
 @require a < m : "The first factor must be reduced already"
 @require b < m : "The second factor must be reduced already"

 @ensure return < m
*>
fn ulong mulmod_u64(ulong a, ulong b, ulong m) @local @inline
{
	const ulong BASE = 1UL << 32;

	uint128 product = (uint128)a * b;
	ulong u1        = (ulong)(product >> 64);
	ulong u0        = (ulong)product;

	int s     = (int)m.clz();
	ulong v   = m << s;
	ulong vn1 = v >> 32;
	ulong vn0 = v & 0xFFFFFFFF;

	ulong un32 = s == 0 ? u1 : (u1 << s) | (u0 >> (64 - s));
	ulong un10 = u0 << s;
	ulong un1  = un10 >> 32;
	ulong un0  = un10 & 0xFFFFFFFF;

	ulong q1   = un32 / vn1;
	ulong rhat = un32 - q1 * vn1;
	while (q1 >= BASE || q1 * vn0 > BASE * rhat + un1)
	{
		q1--;
		rhat += vn1;
		if (rhat >= BASE) break;
	}

	ulong un21 = un32 * BASE + un1 - q1 * v;
	ulong q0   = un21 / vn1;
	rhat = un21 - q0 * vn1;
	while (q0 >= BASE || q0 * vn0 > BASE * rhat + un0)
	{
		q0--;
		rhat += vn1;
		if (rhat >= BASE) break;
	}

	return (un21 * BASE + un0 - q0 * v) >> s;
}

<*
 Raise to a power modulo `m` by repeated squaring.

 @param a : "The base"
 @param n : "The exponent, not negative"
 @param m : "The modulus"

 @require n >= 0 : "A negative exponent would never terminate"
 @require m > 0 : "The modulus must be positive"

 @return "`a` to the power of `n` modulo `m`"
*>
macro bpow(a, n, m)
{
	var $Mod = $Typeof(m);
	$Mod base = a % m;
	$if types::is_signed($Mod):
		if (base < 0) base += m;
	$endif
	$Mod result = 1 % m;
	var exp = n;
	while (exp != 0)
	{
		if (exp & 1) result = mulmod(result, base, m);
		base = mulmod(base, base, m);
		exp >>= 1;
	}
	return result;
}