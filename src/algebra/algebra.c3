// @title Monoids
module c3algo::algebra <Elem>;

import c3algo::util::math;
import c3algo::algebra::concept;

struct Min
{
	Elem v;
}
fn Min Min.op(self, Min o) @inline => o.v < self.v ? o : self;
fn Min Min.e(self) @inline => (Min) { Elem::max };

struct Max
{
	Elem v;
}
fn Max Max.op(self, Max o) @inline => o.v > self.v ? o : self;
fn Max Max.e(self) @inline => (Max) { Elem::min };

struct Sum
{
	Elem v;
}
fn Sum Sum.op(self, Sum o) @inline => (Sum) { self.v + o.v };
fn Sum Sum.e(self) @inline => (Sum) { };
fn Sum Sum.inv(self) @inline => (Sum) { -self.v };

struct Prod
{
	Elem v;
}
fn Prod Prod.op(self, Prod o) @inline => (Prod) { self.v * o.v };
fn Prod Prod.e(self) @inline
{
	Elem t;
	return (Prod) { t.one() };
}

struct Xor
{
	Elem v;
}
fn Xor Xor.op(self, Xor o) @inline => (Xor) { self.v ^ o.v };
fn Xor Xor.e(self) @inline => (Xor) { };
fn Xor Xor.inv(self) @inline => self;

struct Gcd
{
	Elem v;
}
fn Gcd Gcd.op(self, Gcd o) @inline
{
	return (Gcd) { math::gcd(self.v, o.v) };
}
fn Gcd Gcd.e(self) @inline => (Gcd) { };


struct Empty
{
	char unused;
}
macro Empty.act(self, m) => m;
fn Empty Empty.op(self, Empty o) @inline => self;
fn Empty Empty.e(self) @inline => (Empty) { };

<*
 @require concept::@is_ring(Elem) : "Affine requires Elem to be a Ring (needs zero(), one())"
*>
module c3algo::algebra::affine <Elem>;

import c3algo::algebra::concept;

struct Affine
{
	Elem a;
	Elem b;
}
fn Affine Affine.op(self, Affine o) @inline
{
	Elem na = o.a * self.a;
	Elem ab = o.a * self.b;
	Elem nb = ab + o.b;
	return (Affine) { na, nb };
}
fn Affine Affine.e(self) @inline
{
	Elem t;
	return (Affine) { t.one(), t.zero() };
}


struct SumLen
{
	Elem sum;
	Elem len;
}
fn SumLen SumLen.op(self, SumLen o) @inline => (SumLen) { self.sum + o.sum, self.len + o.len };
fn SumLen SumLen.e(self) @inline => (SumLen) { };

fn SumLen Affine.act(self, SumLen x) @inline => (SumLen) { self.a * x.sum + self.b * x.len, x.len };
