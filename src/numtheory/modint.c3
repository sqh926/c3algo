// @title Modular Integer
<*
 @require MOD > 0 : "Modulo must be greater than 0"
 @require types::is_int($Typeof(MOD)) : "Modulo must be an integer type"
*>
module c3algo::numtheory::modint <MOD>;

import std::math;
import std::io;

const ulong M       = (ulong)MOD;
const ulong MODMOD8 = 8 * M * M;

struct ModInt
{
	ulong x;
}

macro ModInt coerce(v)
{
	$if types::is_int($Typeof(v)):
		return from((long)v);
	$else
		return v;
	$endif
}

fn ModInt from(long x)
{
	ModInt res @noinit;
	res.init(x);
	return res;
}

fn ModInt* ModInt.init(&self, long x)
{
	long r = x % MOD;
	if (r < 0) r += MOD;
	self.x = (ulong)r;
	return self;
}

fn ulong ModInt.val(&self) @inline @nodiscard
{
	return self.x;
}

fn $Typeof(MOD) ModInt.mod(&self) @inline @nodiscard
{
	return MOD;
}

macro ModInt ModInt.add_self(&self, rhs) @operator(+=)
{
	self.x += coerce(rhs).x;
	if (self.x >= M) self.x -= M;
	return *self;
}

macro ModInt ModInt.sub_self(&self, rhs) @operator(-=)
{
	self.x = self.x + M - coerce(rhs).x;
	if (self.x >= M) self.x -= M;
	return *self;
}

macro ModInt ModInt.mul_self(&self, rhs) @operator(*=)
{
	self.x = self.x * coerce(rhs).x % M;
	return *self;
}

macro ModInt ModInt.div_self(&self, rhs) @operator(/=)
{
	*self *= coerce(rhs).inv();
	return *self;
}

macro ModInt ModInt.add(&self, rhs) @operator(+) @nodiscard
{
	ModInt res = *self;
	return res += rhs;
}

macro ModInt ModInt.sub(&self, rhs) @operator(-) @nodiscard
{
	ModInt res = *self;
	return res -= rhs;
}

macro ModInt ModInt.mul(&self, rhs) @operator(*) @nodiscard
{
	ModInt res = *self;
	return res *= rhs;
}

macro ModInt ModInt.div(&self, rhs) @operator(/) @nodiscard
{
	ModInt res = *self;
	return res /= rhs;
}

macro bool ModInt.eq(&self, rhs) @operator(==) @nodiscard
{
	return self.x == coerce(rhs).x;
}

fn sz? ModInt.to_format(&self, Formatter* f) @dynamic
{
	return f.printf("%d", self.x);
}

fn ModInt ModInt.neg(&self) @nodiscard
{
	return from((long)(M - self.x));
}

fn ModInt ModInt.pow(&self, long p) @nodiscard
{
	p = p % (MOD - 1) + (p >= 0 ? 0 : MOD - 1);
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

fn ModInt ModInt.inv(&self) @nodiscard
{
	return self.pow(MOD - 2);
}

fn void ModInt.add_unsafe(&self, ulong x) @inline
{
	self.x += x;
}

fn void ModInt.pseudonormalize(&self) @inline
{
	self.x = math::min(self.x, self.x - MODMOD8);
}

fn void ModInt.normalize(&self) @inline
{
	if (self.x >= M) self.x %= M;
}
