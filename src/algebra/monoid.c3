// @title Monoids
<*
 Monoid is any struct with op() and e().
*>
module c3algo::algebra::monoid <Elem>;

import c3algo::arith;
import c3algo::algebra::concept;
import c3algo::algebra::ring;

macro bool @comparable() @const @local => concept::@is_ordered(Elem) &&& $defined(Elem::max, Elem::min);
macro bool @bitwise() @const @local => $defined(((Elem) { }) ^ ((Elem) { }));
macro bool @euclidean() @const @local => $defined(((Elem) { }).ctz());

struct Min
{
	Elem v;
}
fn Min Min.op(self, Min o) @inline @if(@comparable()) => o.v < self.v ? o : self;
fn Min Min.e(self) @inline @if(@comparable()) => (Min) { Elem::max };

struct Max
{
	Elem v;
}
fn Max Max.op(self, Max o) @inline @if(@comparable()) => o.v > self.v ? o : self;
fn Max Max.e(self) @inline @if(@comparable()) => (Max) { Elem::min };

struct Sum
{
	Elem v;
}
fn Sum Sum.op(self, Sum o) @inline => (Sum) { self.v + o.v };
fn Sum Sum.e(self) @inline => (Sum) { };
fn Sum Sum.inv(self) @inline
{
	Elem t;
	return (Sum) { t.zero() - self.v };
}

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
fn Xor Xor.op(self, Xor o) @inline @if(@bitwise()) => (Xor) { self.v ^ o.v };
fn Xor Xor.e(self) @inline @if(@bitwise()) => (Xor) { };
fn Xor Xor.inv(self) @inline @if(@bitwise()) => self;

struct Gcd
{
	Elem v;
}
fn Gcd Gcd.op(self, Gcd o) @inline @if(@euclidean())
{
	return (Gcd) { arith::gcd(self.v, o.v) };
}
fn Gcd Gcd.e(self) @inline @if(@euclidean()) => (Gcd) { };

struct SumLen
{
	Elem sum;
	Elem len;
}
fn SumLen SumLen.op(self, SumLen o) @inline => (SumLen) { self.sum + o.sum, self.len + o.len };
fn SumLen SumLen.e(self) @inline => (SumLen) { };