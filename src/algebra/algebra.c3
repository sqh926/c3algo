module c3algo::algebra <Elem>;

import c3algo::util::math;

struct Min
{
	Elem v;
}
fn Min Min.op(self, Min o) @inline => o.v < self.v ? o : self;

struct Max
{
	Elem v;
}
fn Max Max.op(self, Max o) @inline => o.v > self.v ? o : self;

struct Sum
{
	Elem v;
}
fn Sum Sum.op(self, Sum o) @inline => (Sum) { self.v + o.v };

struct Prod
{
	Elem v;
}
fn Prod Prod.op(self, Prod o) @inline => (Prod) { self.v * o.v };

struct Xor
{
	Elem v;
}
fn Xor Xor.op(self, Xor o) @inline => (Xor) { self.v ^ o.v };

struct Gcd
{
	Elem v;
}
fn Gcd Gcd.op(self, Gcd o) @inline
{
	return (Gcd) { math::gcd(self.v, o.v) };
}


module c3algo::algebra::affine <Elem>;

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
