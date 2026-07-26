// @title Affine maps
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