// @title Algebraic concepts
module c3algo::algebra::concept;

macro bool @is_monoid($Type) @const => $defined((($Type) { }).op((($Type) { }))) && @has_identity($Type);

macro bool @is_group($Type) @const => @is_monoid($Type) && @has_inverse($Type);

macro bool @is_ring(
	$Type
) @const => $defined((($Type) { }) + (($Type) { })) && $defined((($Type) { }) * (($Type) { })) && $defined((($Type) { }).zero())
	&& $defined((($Type) { }).one());

macro bool @is_field($Type) @const => @is_ring($Type) && @has_inverse($Type);

macro bool @has_inverse($Type) @const => $defined((($Type) { }).inv());

macro bool @has_identity($Type) @const => $defined((($Type) { }).e());

// Action on monoid
macro bool @is_action($Act, $Mono) @const => @is_monoid($Act) && $defined((($Act) { }).act((($Mono) { })));

macro bool @is_ordered($Type) @const => $defined((($Type) { }) < (($Type) { }));

struct Less
{
	char unused;
}
macro bool Less.before(self, a, b) => less(a, b);

struct Greater
{
	char unused;
}
macro bool Greater.before(self, a, b) => greater(a, b);

macro bool @is_comparator($Cmp, $Type) @const => $defined((($Cmp) { }).before((($Type) { }), (($Type) { })));