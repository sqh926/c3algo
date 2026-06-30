// @title Algebraic concepts
module c3algo::algebra::concept;

fn ichar ichar.zero(self) @inline => 0;
fn ichar ichar.one(self) @inline => 1;
fn char char.zero(self) @inline => 0;
fn char char.one(self) @inline => 1;
fn short short.zero(self) @inline => 0;
fn short short.one(self) @inline => 1;
fn ushort ushort.zero(self) @inline => 0;
fn ushort ushort.one(self) @inline => 1;
fn int int.zero(self) @inline => 0;
fn int int.one(self) @inline => 1;
fn uint uint.zero(self) @inline => 0;
fn uint uint.one(self) @inline => 1;
fn long long.zero(self) @inline => 0;
fn long long.one(self) @inline => 1;
fn ulong ulong.zero(self) @inline => 0;
fn ulong ulong.one(self) @inline => 1;
fn int128 int128.zero(self) @inline => 0;
fn int128 int128.one(self) @inline => 1;
fn uint128 uint128.zero(self) @inline => 0;
fn uint128 uint128.one(self) @inline => 1;

macro bool @is_monoid($Type) @const => $defined((($Type) { }).op((($Type) { }))) && $defined((($Type) { }).e());

macro bool @is_group($Type) @const => @is_monoid($Type) && $defined((($Type) { }).inv());

macro bool @is_ring(
	$Type
) @const => $defined((($Type) { }) + (($Type) { })) && $defined((($Type) { }) * (($Type) { }))
	&& $defined((($Type) { }).zero())
	&& $defined((($Type) { }).one());

macro bool @is_field($Type) @const => @is_ring($Type) && $defined((($Type) { }).inv());

// Action on monoid
macro bool @is_action($Act, $Mono) @const => @is_monoid($Act) && $defined((($Act) { }).act((($Mono) { })));

macro bool @is_ordered($Type) @const => $defined((($Type) { }) < (($Type) { }));
