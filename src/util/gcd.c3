// @title Fast gcd
module c3algo::util::gcd;

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
