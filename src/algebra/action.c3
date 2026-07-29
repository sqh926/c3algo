// @title Actions
<*
 An action needs three functions.

     fn A A.op(self, A other)   action composition
     fn A A.e(self)             the action that changes nothing
     fn M A.act(self, M m)      apply action to a monoid

 @require concept::@is_ring(Elem) : "Affine requires Elem to be a Ring (needs zero(), one())"
*>
module c3algo::algebra::action <Elem>;

import c3algo::algebra::concept;
import c3algo::algebra::monoid;
import c3algo::algebra::ring;

alias Fold = monoid::SumLen{Elem};

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
fn Fold Affine.act(self, Fold x) @inline => (Fold) { self.a * x.sum + self.b * x.len, x.len };

<*
 The action that leaves everything as it is.
*>
struct Identity
{
	char unused;
}
macro Identity.act(self, m) => m;
fn Identity Identity.op(self, Identity o) @inline => self;
fn Identity Identity.e(self) @inline => (Identity) { };