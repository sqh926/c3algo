// @title Random number generator
<*
 A xorshift64 generator

 https://en.wikipedia.org/wiki/Xorshift
*>
module c3algo::util::rng;

ulong state @local = 0xDEADBEEF;

<*
 Replace the generator state.

 @param value : "The new state"

 @require value != 0 : "A zero state would make xorshift emit only zeroes"
*>
fn void seed(ulong value) @inline
{
	state = value;
}

<*
 @return "A 'uniformly' distributed 64-bit value"
*>
fn ulong next()
{
	ulong x = state;
	x ^= x << 13;
	x ^= x >> 7;
	x ^= x << 17;
	state = x;
	return x;
}

<*
 @return "A 'uniformly' distributed 32-bit value"
*>
fn uint next32() @inline => (uint)(next() >> 32);