// @title Modular Integer
<*
 Integers modulo a compile time constant.

 @require MOD > 0 : "Modulo must be greater than 0"
 @require types::is_int($Typeof(MOD)) : "Modulo must be an integer type"
 @require (ulong)MOD <= ulong::max / 8 / (ulong)MOD : "Modulo is too large, 8 * MOD ^ 2 must fit in 64 bits"
*>
module c3algo::numbertheory::modint <MOD>;

import std::math;
import std::io;

const ulong M @local = (ulong)MOD;

const ulong MODMOD8 @local = 8 * M * M;

<*
 A residue modulo `MOD`, below `MOD` unless you use unsafe functions.
*>
struct ModInt
{
	ulong x;
}

<*
 Reduce an integer into a `ModInt`, and leave one that already is a `ModInt` alone.
*>
macro ModInt coerce(v) @local
{
	$if types::is_int($Typeof(v)):
		return from((long)v);
	$else
		return v;
	$endif
}

<*
 @param x : "The value to reduce, negative allowed"

 @return "`x` modulo `MOD`"

 @ensure return.x < M
*>
fn ModInt from(long x)
{
	ModInt res @noinit;
	res.init(x);
	return res;
}

<*
 Replace the value with `x` reduced modulo `MOD`.

 @param x : "The value to reduce, negative allowed"

 @ensure self.x < M
*>
fn ModInt* ModInt.init(&self, long x)
{
	long r = x % MOD;
	if (r < 0) r += MOD;
	self.x = (ulong)r;
	return self;
}

<*
 @return "The residue"
*>
fn ulong ModInt.val(&self) @inline @nodiscard
{
	return self.x;
}


fn ModInt ModInt.zero(self) @inline => from(0);
fn ModInt ModInt.one(self) @inline => from(1);

<*
 @return "The modulus every value of this type is taken against"
*>
fn $Typeof(MOD) ModInt.mod(&self) @inline @nodiscard
{
	return MOD;
}

<*
 @param rhs : "A `ModInt` or an integer"

 @require self.x < M : "The value is mid accumulation, normalize() it first"
*>
macro ModInt ModInt.add_self(&self, rhs) @operator(+=)
{
	self.x += coerce(rhs).x;
	if (self.x >= M) self.x -= M;
	return *self;
}

<*
 @param rhs : "A `ModInt` or an integer"

 @require self.x < M : "The value is mid accumulation, normalize() it first"
*>
macro ModInt ModInt.sub_self(&self, rhs) @operator(-=)
{
	self.x = self.x + M - coerce(rhs).x;
	if (self.x >= M) self.x -= M;
	return *self;
}

<*
 @param rhs : "A `ModInt` or an integer"

 @require self.x < M : "The value is mid accumulation, normalize() it first"
*>
macro ModInt ModInt.mul_self(&self, rhs) @operator(*=)
{
	self.x = self.x * coerce(rhs).x % M;
	return *self;
}

<*
 Divide by inverting `rhs`, which needs `MOD` to be prime.

 @param rhs : "A `ModInt` or an integer, not zero"

 @require self.x < M : "The value is mid accumulation, normalize() it first"
*>
macro ModInt ModInt.div_self(&self, rhs) @operator(/=)
{
	*self *= coerce(rhs).inv();
	return *self;
}

<*
 @param rhs : "A `ModInt` or an integer"
*>
macro ModInt ModInt.add(&self, rhs) @operator(+) @nodiscard
{
	ModInt res = *self;
	return res += rhs;
}

<*
 @param rhs : "A `ModInt` or an integer"
*>
macro ModInt ModInt.sub(&self, rhs) @operator(-) @nodiscard
{
	ModInt res = *self;
	return res -= rhs;
}

<*
 @param rhs : "A `ModInt` or an integer"
*>
macro ModInt ModInt.mul(&self, rhs) @operator(*) @nodiscard
{
	ModInt res = *self;
	return res *= rhs;
}

<*
 Divide by inverting `rhs`, which needs `MOD` to be prime.

 @param rhs : "A `ModInt` or an integer, not zero"
*>
macro ModInt ModInt.div(&self, rhs) @operator(/) @nodiscard
{
	ModInt res = *self;
	return res /= rhs;
}

<*
 @param rhs : "A `ModInt` or an integer"

 @require self.x < M : "The value is mid accumulation, normalize() it first"
*>
macro bool ModInt.eq(&self, rhs) @operator(==) @nodiscard
{
	return self.x == coerce(rhs).x;
}

fn sz? ModInt.to_format(&self, Formatter* f) @dynamic
{
	return f.printf("%d", self.x);
}

<*
 @return "The residue that adds up to zero with `self`"

 @require self.x < M : "The value is mid accumulation, normalize() it first"
*>
fn ModInt ModInt.neg(&self) @nodiscard
{
	return from((long)(M - self.x));
}

<*
 Raise to a power by repeated squaring.

 @param p : "The exponent"

 @require self.x < M : "The value is mid accumulation, normalize() it first"
 @require p >= 0 || self.x != 0 : "Zero has no negative power"
 @require p > long::min : "The exponent may not be negated"

 @return "`self` raised to the power of `p`"
*>
fn ModInt ModInt.pow(&self, long p) @nodiscard
{
	if (p < 0) return self.inv().pow(-p);
	ModInt res  = from(1);
	ModInt base = *self;
	while (p)
	{
		if (p & 1) res *= base;
		base *= base;
		p >>= 1;
	}
	return res;
}

<*
 The multiplicative inverse by Fermat's little theorem, which needs `MOD` to be prime.

 @require self.x < M : "The value is mid accumulation, normalize() it first"
 @require self.x != 0 : "Zero has no inverse"

 @return "The residue that multiplies with `self` to one"
*>
fn ModInt ModInt.inv(&self) @nodiscard
{
	return self.pow(MOD - 2);
}

<*
 Add a raw value without reducing it.
 Don't use unless you know what you're doing.

 @param x : "The value to add"

 @require x <= ulong::max - self.x : "The accumulator would overflow"
*>
fn void ModInt.add_unsafe(&self, ulong x) @inline
{
	self.x += x;
}

<*
 Reduce self modulo `MODMOD8`.
 Don't use unless you know what you're doing.

 @ensure self.x < MODMOD8
*>
fn void ModInt.pseudonormalize(&self) @inline
{
	self.x = math::min(self.x, self.x - MODMOD8);
}

<*
 Reduce self modulo `MOD`.

 @ensure self.x < M
*>
fn void ModInt.normalize(&self) @inline
{
	if (self.x >= M) self.x %= M;
}