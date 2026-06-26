<*
 @require SIZE > 0 : "The size of the bitset in bits must be at least 1"
 @require SIZE / (uint::size * 8) < uint::max
*>
// Cannot put Word ^^^ here instead of uint
module c3algo::ds::bitset <SIZE>;

alias Word = uint;

const BITS   = Word::size * 8;
const BLOCKS = (SIZE + BITS - 1) / BITS;
const TAIL   = SIZE % BITS;

struct BitSet
{
	Word[BLOCKS] data;
}

<*
 Clear the padding bits in the last word (those beyond SIZE).
*>
fn void clear_tail(BitSet* self) @inline @local
{
	$if TAIL != 0:
		self.data[BLOCKS - 1] &= ((Word)1 << TAIL) - 1;
	$endif
}

<*
 Set a bit in the bitset.

 @param i : "The index to set"

 @require i < SIZE && i >= 0 : "Index was out of range"
*>
fn void BitSet.set(&self, sz i) @inline
{
	sz q   = i / BITS;
	uint r = (uint)(i % BITS);
	self.data[q] |= (Word)1 << r;
}

<*
 Unset (clear) a bit in the bitset.

 @param i : "The index to unset"

 @require i < SIZE && i >= 0 : "Index was out of range"
*>
fn void BitSet.unset(&self, sz i) @inline
{
	sz q   = i / BITS;
	uint r = (uint)(i % BITS);
	self.data[q] &= ~((Word)1 << r);
}

<*
 Flip a bit in the bitset.

 @param i : "The index to flip"

 @require i < SIZE && i >= 0 : "Index was out of range"
*>
fn void BitSet.flip(&self, sz i) @inline
{
	sz q   = i / BITS;
	uint r = (uint)(i % BITS);
	self.data[q] ^= (Word)1 << r;
}

<*
 Get a particular bit in the bitset.

 @param i : "The index of the bit"

 @require i < SIZE && i >= 0 : "Index was out of range"
 @pure
*>
fn bool BitSet.get(&self, sz i) @operator([]) @inline @nodiscard
{
	sz q   = i / BITS;
	uint r = (uint)(i % BITS);
	return self.data[q] & ((Word)1 << r) != 0;
}

<*
 Change a particular bit in the bitset.

 @param i : "The index of the bit"
 @param value : "The value to set the bit to"

 @require i < SIZE && i >= 0 : "Index was out of range"
*>
fn void BitSet.set_bool(&self, sz i, bool value) @operator([]=) @inline
{
	if (value) return self.set(i);
	self.unset(i);
}

<*
 Sets all bits in the bitset.
*>
fn void BitSet.set_all(&self)
{
	foreach (&x : self.data) *x = (Word)-1;
	clear_tail(self);
}

<*
 Clears all bits in the bitset.
*>
fn void BitSet.unset_all(&self)
{
	foreach (&x : self.data) *x = (Word)0;
}

<*
 Flips all bits in the bitset.
*>
fn void BitSet.flip_all(&self)
{
	foreach (&x : self.data) *x = ~*x;
	clear_tail(self);
}

<*
 @return "Returns the number of bits set"
 @pure
*>
fn sz BitSet.cardinality(&self) @nodiscard
{
	sz n;
	foreach (x : self.data)
	{
		n += x.popcount();
	}
	return n;
}

<*
 @return "Returns true if any bit is set, false otherwise"
 @pure
*>
fn bool BitSet.any_set(&self) @nodiscard @inline
{
	foreach (x : self.data)
	{
		if (x != 0)
		{
			return true;
		}
	}
	return false;
}

<*
 @return "Returns true if no bits are set, false otherwise"
 @pure
*>
fn bool BitSet.none_set(&self) @nodiscard @inline
{
	return !self.any_set();
}

<*
 @return "Returns index of lowest set bit or SIZE if none bits are set"
 @pure
*>
fn sz BitSet.min_bit_set(&self) @nodiscard
{
	foreach (i, x : self.data)
	{
		if (x == (Word)0) continue;
		sz r = i * BITS + x.ctz();
		return r < SIZE ? r : (sz)SIZE;
	}
	return SIZE;
}

<*
 @return "Returns the number of bits"
 @pure
*>
fn sz BitSet.len(&self) @operator(len) @inline @nodiscard
{
	return BLOCKS * BITS;
}

<*
 Perform xor over all bits, mutating itself.

 @param [&in] set : "The bitset to xor with"
*>
fn void BitSet.xor_assign(&self, BitSet* set @noalias) @inline
{
	foreach (i, &x : self.data)
	{
		*x ^= set.data[i];
	}
}

<*
 Perform or over all bits, mutating itself.

 @param [&in] set : "The bitset to or with"
*>
fn void BitSet.or_assign(&self, BitSet* set @noalias) @inline
{
	foreach (i, &x : self.data)
	{
		*x |= set.data[i];
	}
}

<*
 Perform & over all bits, mutating itself.

 @param [&in] set : "The bitset to & with"
*>
fn void BitSet.and_assign(&self, BitSet* set @noalias) @inline
{
	foreach (i, &x : self.data)
	{
		*x &= set.data[i];
	}
}

<*
 Perform xor over all bits from a starting index onwards, mutating itself.

 @param [&in] set : "The bitset to xor with"
 @param hint : "Lowest index of set that is not zero"
 @return "The resulting bitset"

 @require hint < SIZE && hint >= 0 : "Index was out of range"
*>
fn BitSet BitSet.xor_hint(&self, BitSet* set @noalias, sz hint) @inline
{
	for (sz i = hint / BITS; i < BLOCKS; i++)
	{
		self.data[i] ^= set.data[i];
	}
	return *self;
}

<*
 Perform xor over all bits, mutating itself.

 @param set : "The bitset to xor with"
 @return "The resulting bitset"
*>
macro BitSet BitSet.xor_self(&self, BitSet set) @operator(^=)
{
	self.xor_hint(&set, 0);
	return *self;
}

<*
 Perform or over all bits, mutating itself.

 @param set : "The bitset to or with"
 @return "The resulting bitset"
*>
macro BitSet BitSet.or_self(&self, BitSet set) @operator(|=)
{
	self.or_assign(&set);
	return *self;
}

<*
 Perform & over all bits, mutating itself.

 @param set : "The bit set to & with"
 @return "The resulting bitset"
*>
macro BitSet BitSet.and_self(&self, BitSet set) @operator(&=)
{
	self.and_assign(&set);
	return *self;
}

<*
 Perform xor over all bits, returning a new bitset.

 @param set : "The bit set to xor with"
 @return "The resulting bitset"

 @pure
*>
macro BitSet BitSet.xor(&self, BitSet set) @operator(^) @nodiscard
{
	BitSet new_set = *self;
	return new_set ^= set;
}

<*
 Perform or over all bits, returning a new bitset.

 @param set : "The bit set to or with"
 @return "The resulting bitset"

 @pure
*>
macro BitSet BitSet.or(&self, BitSet set) @operator(|) @nodiscard
{
	BitSet new_set = *self;
	return new_set |= set;
}

<*
 Perform & over all bits, returning a new bitset.

 @param set : "The bit set to & with"
 @return "The resulting bitset"

 @pure
*>
macro BitSet BitSet.and(&self, BitSet set) @operator(&) @nodiscard
{
	BitSet new_set = *self;
	return new_set &= set;
}

<*
 Shift all bits towards higher indices, mutating itself.

 @param shift : "The number of positions to shift left"

 @require shift >= 0 : "Shift must be a positive number"
*>
fn void BitSet.shl_assign(&self, sz shift)
{
	if (shift >= SIZE)
	{
		self.unset_all();
		return;
	}
	sz block_shift = shift / BITS;
	uint bit_shift = (uint)(shift % BITS);

	if (block_shift > 0)
	{
		sz cnt = BLOCKS - block_shift;
		self.data[block_shift:cnt] = self.data[0:cnt];
		self.data[0:block_shift] = 0;
	}

	if (bit_shift > 0)
	{
		for (sz i = BLOCKS - 1; i >= 0; i--)
		{
			self.data[i] <<= bit_shift;
			if (i > 0) self.data[i] |= self.data[i - 1] >> (BITS - bit_shift);
		}
	}
	clear_tail(self);
}

<*
 Shift all bits towards lower indices, mutating itself.

 @param shift : "The number of positions to shift right"
 @require shift >= 0 : "Shift must be a positive number"
*>
fn void BitSet.shr_assign(&self, sz shift)
{
	if (shift >= SIZE)
	{
		self.unset_all();
		return;
	}
	sz block_shift = shift / BITS;
	uint bit_shift = (uint)(shift % BITS);

	if (block_shift > 0)
	{
		sz cnt = BLOCKS - block_shift;
		self.data[0:cnt] = self.data[block_shift:cnt];
		self.data[cnt:block_shift] = 0;
	}

	if (bit_shift > 0)
	{
		for (sz i = 0; i < BLOCKS; i++)
		{
			self.data[i] >>= bit_shift;
			if (i + 1 < BLOCKS) self.data[i] |= self.data[i + 1] << (BITS - bit_shift);
		}
	}
}

<*
 Shift left in place.

 @param shift : "The number of positions to shift left"
 @return "The resulting bitset"

 @require shift >= 0 : "Shift must be a positive number"
*>
macro BitSet BitSet.shl_self(&self, sz shift) @operator(<<=)
{
	self.shl_assign(shift);
	return *self;
}

<*
 Shift right in place.

 @param shift : "The number of positions to shift right"
 @return "The resulting bitset"

 @require shift >= 0 : "Shift must be a positive number"
*>
macro BitSet BitSet.shr_self(&self, sz shift) @operator(>>=)
{
	self.shr_assign(shift);
	return *self;
}

<*
 Shift left, returning a new bitset.

 @param shift : "The number of positions to shift left"
 @return "The resulting bitset"

 @require shift >= 0 : "Shift must be a positive number"
 @pure
*>
macro BitSet BitSet.shl(&self, sz shift) @operator(<<) @nodiscard
{
	BitSet new_set = *self;
	return new_set <<= shift;
}

<*
 Shift right, returning a new bitset.

 @param shift : "The number of positions to shift right"
 @return "The resulting bitset"

 @require shift >= 0 : "Shift must be a positive number"
 @pure
*>
macro BitSet BitSet.shr(&self, sz shift) @operator(>>) @nodiscard
{
	BitSet new_set = *self;
	return new_set >>= shift;
}
