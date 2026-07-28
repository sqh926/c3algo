module c3algo::bigint <RADIX>;

import std::collections::list;
import std::math;
import std::core::mem::alloc;
import c3algo::convolution::fft;

const ulong BASE         = RADIX == 10 ? 10_000_000_000_000_000UL : 1UL << 60;
// Cannot directly use FFT with such a big base, so, for multiplication use the smaller one
const ulong FFT_BASE     = RADIX == 10 ? 10_000UL : 1UL << 15;
const sz CHUNKS          = RADIX == 10 ? 4 : 4;
const int DIGIT_LENGTH   = RADIX == 10 ? 16 : 15;
const String DIGIT_CHARS = "0123456789abcdef";

// chosen so that their product fits in ulong
const ulong PIECE_BASE = RADIX == 10 ? 100_000_000UL : 1UL << 15;
const sz PIECES        = RADIX == 10 ? 2 : 4;
// Below this many digits the divisor is handled by long division instead of more recursion
const sz DIV_LIMIT     = 4;

alias fft_conv = fft::convolution{double};
alias ULongList = List{ulong};

struct DynBigInt
{
	ULongList digits;
	bool negative;
}

<*
 Initialize to zero.

 @param [&inout] allocator : "The allocator the digits live in, inherited by every result computed from this number"

 @require !self.is_initialized() : "The DynBigInt must not be initialized"

 @ensure self.is_initialized(), self.is_zero()
*>
fn DynBigInt* DynBigInt.init(&self, Allocator allocator)
{
	self.digits.allocator = allocator;
	return self;
}

<*
 Initialize from a string of digits in this radix, with an optional leading sign.

 @param [&inout] allocator : "The allocator the digits live in"
 @param [in] text : "The digits to read"

 @require !self.is_initialized() : "The DynBigInt must not be initialized"
*>
fn DynBigInt* DynBigInt.init_with(&self, Allocator allocator, String text)
{
	self.init(allocator);
	sz i = 0;
	if (text.len > 0 && (text[0] == '-' || text[0] == '+'))
	{
		if (text[0] == '-') self.negative = true;
		i = 1;
	}
	self.digits.reserve(((sz)text.len - i + DIGIT_LENGTH - 1) / DIGIT_LENGTH);
	for (sz end = (sz)text.len; end > i; end -= DIGIT_LENGTH)
	{
		sz start = end - DIGIT_LENGTH;
		if (start < i) start = i;
		ulong digit = 0;
		for (sz j = start; j < end; j++)
		{
			digit = digit * RADIX + digit_val(text[j]);
		}
		self.digits.push(digit);
	}
	self.normalize();
	return self;
}

<*
 Initialize to zero with the temp allocator.

 @require !self.is_initialized() : "The DynBigInt must not be initialized"
*>
fn DynBigInt* DynBigInt.tinit(&self) @inline => self.init(tmem);

<*
 Initialize from a string of digits with the temp allocator.

 @param [in] text : "The digits to read"

 @require !self.is_initialized() : "The DynBigInt must not be initialized"
*>
fn DynBigInt* DynBigInt.tinit_with(&self, String text) @inline => self.init_with(tmem, text);

<*
 @return "`true` if the digits have an allocator to live in"
*>
fn bool DynBigInt.is_initialized(&self) @inline => self.digits.allocator != null;

<*
 Release the digits and leave the number uninitialized.

 @ensure !self.is_initialized()
*>
fn void DynBigInt.free(&self)
{
	if (!self.is_initialized()) return;
	self.digits.free();
	*self = { };
}

fn bool DynBigInt.is_zero(&self) @inline => self.digits.len() == 0;

fn void DynBigInt.normalize(&self)
{
	while (self.digits.len() > 0 && self.digits[self.digits.len() - 1] == 0) self.digits.remove_last();
	if (self.digits.len() == 0) self.negative = false;
}

fn void assign_digits(ULongList* dst, ULongList* src) @local
{
	dst.clear();
	dst.push_all(src.array_view());
}

fn int cmp_digits(ULongList* a, ULongList* b) @local
{
	if (a.len() != b.len()) return a.len() < b.len() ? -1 : 1;
	for (sz i = a.len() - 1; i >= 0; i--)
	{
		if (a.[i] != b.[i]) return a.[i] < b.[i] ? -1 : 1;
	}
	return 0;
}

fn void add_digits_inplace(ULongList* dst, ULongList* src)
{
	ulong carry = 0;
	for (sz i = 0; i < src.len(); ++i)
	{
		if (i >= dst.len()) dst.push(0);
		dst.[i] += src.[i] + carry;
		if (dst.[i] >= BASE)
		{
			dst.[i] -= BASE;
			carry = 1;
		}
		else
		{
			carry = 0;
		}
	}
	sz i = src.len();
	while (carry)
	{
		if (i >= dst.len()) dst.push(0);
		dst.[i] += 1;
		if (dst.[i] >= BASE)
		{
			dst.[i] = 0;
			i++;
		}
		else
		{
			break;
		}
	}
}

// dst -= src, dst >= src
fn void sub_digits_inplace(ULongList* dst, ULongList* src)
{
	ulong borrow = 0;
	for (sz i = 0; i < src.len(); i++)
	{
		if (dst.[i] < src.[i] + borrow)
		{
			dst.[i] += BASE - src.[i] - borrow;
			borrow = 1;
		}
		else
		{
			dst.[i] -= src.[i] + borrow;
			borrow = 0;
		}
	}
	for (sz i = src.len(); borrow; i++)
	{
		if (dst.[i] == 0)
		{
			dst.[i] = BASE - 1;
		}
		else
		{
			dst.[i] -= 1;
			borrow = 0;
		}
	}
}

// dst = src - dst, src >= dst
fn void rsub_digits_inplace(ULongList* dst, ULongList* src)
{
	dst.reserve(src.len() - dst.len());
	ulong borrow = 0;
	sz i         = 0;
	for (; i < dst.len(); i++)
	{
		ulong sub = dst.[i] + borrow;
		if (src.[i] < sub)
		{
			dst.[i] = src.[i] + BASE - sub;
			borrow = 1;
		}
		else
		{
			dst.[i] = src.[i] - sub;
			borrow = 0;
		}
	}
	for (; i < src.len(); i++)
	{
		if (borrow && src.[i] == 0)
		{
			dst.push(BASE - 1);
		}
		else
		{
			dst.push(src.[i] - borrow);
			borrow = 0;
		}
	}
}

fn void split_small(long[] dst, ULongList* src) @local
{
	for (sz i = 0; i < src.len(); i++)
	{
		ulong val = src.[i];
		for (sz j = 0; j < CHUNKS; j++)
		{
			dst[CHUNKS * i + j] = (long)(val % FFT_BASE);
			val /= FFT_BASE;
		}
	}
}

fn void add_signed_into(DynBigInt* r, DynBigInt* a, bool a_neg, DynBigInt* b, bool b_neg) @local
{
	if (a_neg == b_neg)
	{
		if (r == b) @swap(a, b);
		if (r != a) assign_digits(&r.digits, &a.digits);
		add_digits_inplace(&r.digits, &b.digits);
		r.negative = a_neg;
	}
	else
	{
		int c = cmp_digits(&a.digits, &b.digits);
		if (c == 0)
		{
			r.digits.clear();
			r.negative = false;
			return;
		}
		if (c < 0)
		{
			@swap(a, b);
			@swap(a_neg, b_neg);
		}
		if (r == b)
		{
			rsub_digits_inplace(&r.digits, &a.digits);
		}
		else
		{
			if (r != a) assign_digits(&r.digits, &a.digits);
			sub_digits_inplace(&r.digits, &b.digits);
		}
		r.negative = a_neg;
	}
	r.normalize();
}

// r may alias a or b
fn void add_into(DynBigInt* r, DynBigInt* a, DynBigInt* b)
{
	add_signed_into(r, a, a.negative, b, b.negative);
}

// r may alias a or b
fn void sub_into(DynBigInt* r, DynBigInt* a, DynBigInt* b)
{
	add_signed_into(r, a, a.negative, b, !b.negative);
}

fn void split_pieces(ulong[] dst, ULongList* src) @local
{
	for (sz i = 0; i < src.len(); i++)
	{
		ulong val = src.[i];
		for (sz j = 0; j < PIECES; j++)
		{
			dst[PIECES * i + j] = val % PIECE_BASE;
			val /= PIECE_BASE;
		}
	}
}

fn void mul_naive_into(DynBigInt* r, DynBigInt* a, DynBigInt* b) @local
{
	sz la = a.digits.len();
	sz lb = b.digits.len();
	@pool()
	{
		sz na      = la * PIECES;
		sz nb      = lb * PIECES;
		ulong[] pa = alloc::new_array(tmem, ulong, na);
		ulong[] pb = alloc::new_array(tmem, ulong, nb);
		split_pieces(pa, &a.digits);
		split_pieces(pb, &b.digits);
		ulong[] acc = alloc::new_array(tmem, ulong, na + nb);
		for (sz i = 0; i < na; i++)
		{
			ulong x = pa[i];
			if (x == 0) continue;
			ulong carry = 0;
			for (sz j = 0; j < nb; j++)
			{
				ulong cur = acc[i + j] + x * pb[j] + carry;
				acc[i + j] = cur % PIECE_BASE;
				carry = cur / PIECE_BASE;
			}
			for (sz k = i + nb; carry > 0; k++)
			{
				ulong cur = acc[k] + carry;
				acc[k] = cur % PIECE_BASE;
				carry = cur / PIECE_BASE;
			}
		}
		r.digits.clear();
		r.digits.reserve(la + lb);
		for (sz i = 0; i < na + nb; i += PIECES)
		{
			ulong digit = 0;
			ulong shift = 1;
			for (sz j = 0; j < PIECES; j++)
			{
				digit += acc[i + j] * shift;
				shift *= PIECE_BASE;
			}
			r.digits.push(digit);
		}
	};
}

fn bool naive_is_better(sz la, sz lb) @local
{
	sz length = 1;
	sz log    = 0;
	while (length < CHUNKS * (la + lb))
	{
		length *= 2;
		log++;
	}
	return 5 * la * lb <= 2 * length * log;
}

// r must not alias a or b
fn void mul_into(DynBigInt* r, DynBigInt* a, DynBigInt* b)
{
	assert(r != a && r != b);
	if (a.is_zero() || b.is_zero())
	{
		r.digits.clear();
		r.negative = false;
		return;
	}
	bool neg = a.negative != b.negative;
	if (a.digits.len() == 1 || b.digits.len() == 1)
	{
		DynBigInt* longer = a.digits.len() == 1 ? b : a;
		ulong single      = a.digits.len() == 1 ? a.digits[0] : b.digits[0];
		assign_digits(&r.digits, &longer.digits);
		mul_small_inplace(r, single);
		r.negative = neg;
		r.normalize();
		return;
	}
	if (naive_is_better(a.digits.len(), b.digits.len()))
	{
		mul_naive_into(r, a, b);
		r.negative = neg;
		r.normalize();
		return;
	}
	@pool()
	{
		sz la     = CHUNKS * a.digits.len();
		sz lb     = CHUNKS * b.digits.len();
		long[] sa = alloc::new_array(tmem, long, la);
		long[] sb = alloc::new_array(tmem, long, lb);
		split_small(sa, &a.digits);
		split_small(sb, &b.digits);
		while (la > 1 && sa[la - 1] == 0) la--;
		while (lb > 1 && sb[lb - 1] == 0) lb--;
		long[] conv = alloc::new_array(tmem, long, la + lb - 1);
		fft_conv(conv, sa[:la], sb[:lb], tmem);

		r.digits.clear();
		r.digits.reserve(a.digits.len() + b.digits.len() + 1);
		long carry  = 0;
		ulong limb  = 0;
		ulong shift = 1;
		for (sz i = 0; i < conv.len || carry; i++)
		{
			if (i < conv.len) carry += conv[i];
			limb += (ulong)(carry % (long)FFT_BASE) * shift;
			carry /= (long)FFT_BASE;
			shift *= FFT_BASE;
			if (shift == BASE)
			{
				r.digits.push(limb);
				limb = 0;
				shift = 1;
			}
		}
		if (shift != 1) r.digits.push(limb);
	};
	r.negative = neg;
	r.normalize();
}

fn DynBigInt DynBigInt.copy(&self)
{
	DynBigInt r;
	r.init(self.digits.allocator);
	r.negative = self.negative;
	r.digits.push_all(self.digits.array_view());
	return r;
}

fn DynBigInt DynBigInt.neg(&self) @operator(-)
{
	DynBigInt r = self.copy();
	r.negative = r.is_zero() ? false : !r.negative;
	return r;
}

fn DynBigInt DynBigInt.add(&self, DynBigInt o) @operator(+)
{
	DynBigInt r;
	r.init(self.digits.allocator);
	add_into(&r, self, &o);
	return r;
}

fn DynBigInt DynBigInt.sub(&self, DynBigInt o) @operator(-)
{
	DynBigInt r;
	r.init(self.digits.allocator);
	sub_into(&r, self, &o);
	return r;
}

fn DynBigInt DynBigInt.mul(&self, DynBigInt o) @operator(*)
{
	DynBigInt r;
	r.init(self.digits.allocator);
	mul_into(&r, self, &o);
	return r;
}

<*
 The quotient, truncated toward zero. The remainder is computed alongside it and dropped, so
 reach for `divmod` when both halves are wanted.

 @require !o.is_zero() : "Division by zero"
*>
fn DynBigInt DynBigInt.div(&self, DynBigInt o) @operator(/)
{
	DynBigInt quot;
	quot.init(self.digits.allocator);
	DynBigInt rem;
	rem.init(self.digits.allocator);
	defer rem.free();
	self.divmod(&o, &quot, &rem);
	return quot;
}

<*
 The remainder, taking the sign of the dividend. The quotient is computed alongside it and
 dropped, so reach for `divmod` when both halves are wanted.

 @require !o.is_zero() : "Division by zero"
*>
fn DynBigInt DynBigInt.mod(&self, DynBigInt o) @operator(%)
{
	DynBigInt quot;
	quot.init(self.digits.allocator);
	defer quot.free();
	DynBigInt rem;
	rem.init(self.digits.allocator);
	self.divmod(&o, &quot, &rem);
	return rem;
}

fn ulong digit_val(char c) @local @inline
{
	if (c <= '9') return (ulong)(c - '0');
	if (c >= 'a') return (ulong)(c - 'a' + 10);
	return (ulong)(c - 'A' + 10);
}


fn String DynBigInt.to_string(&self, Allocator allocator)
{
	if (self.is_zero())
	{
		char[] buf = alloc::new_array(allocator, char, 1);
		buf[0] = '0';
		return (String)buf;
	}
	sz n       = self.digits.len();
	sz cap     = n * DIGIT_LENGTH + 1;
	char[] buf = alloc::new_array(allocator, char, cap);
	sz pos     = cap;
	for (sz i = 0; i < n - 1; i++)
	{
		ulong v = self.digits[i];
		for (int d = 0; d < DIGIT_LENGTH; d++)
		{
			buf[--pos] = DIGIT_CHARS[v % RADIX];
			v /= RADIX;
		}
	}
	ulong top = self.digits[n - 1];
	while (top > 0)
	{
		buf[--pos] = DIGIT_CHARS[top % RADIX];
		top /= RADIX;
	}
	if (self.negative) buf[--pos] = '-';
	return (String)buf[pos..];
}

<*
 Divide by a single digit.

 @param d : "The divisor, which must fit in a single digit"
 @param [&out] quot : "The quotient, which may alias the dividend and must be zero otherwise"
 @param [&out] rem : "The magnitude of the remainder, whose sign is the sign of the dividend"

 @require d != 0 : "Division by zero"
 @require d < BASE : "The divisor must fit in a single digit"
 @require quot.digits.len() == 0 || quot == self : "The quotient must be zero or alias the dividend"
*>
fn void DynBigInt.divmod_small(&self, ulong d, DynBigInt* quot, ulong* rem)
{
	sz n = self.digits.len();
	if (n == 0)
	{
		*rem = 0;
		return;
	}
	while (quot.digits.len() < n) quot.digits.push(0);
	ulong r = 0;
	for (sz i = n - 1; i >= 0; i--)
	{
		uint128 c = (uint128)r * BASE + self.digits[i];
		quot.digits[i] = (ulong)(c / d);
		r = (ulong)(c % d);
	}
	quot.negative = self.negative;
	quot.normalize();
	*rem = r;
}

<*
 The digits of `a` in the range [lo, hi) read as a number of their own.
 borrows instead of copying.
*>
fn DynBigInt window(DynBigInt* a, sz lo, sz hi) @local
{
	DynBigInt r;
	r.init(a.digits.allocator);
	sz len = a.digits.len();
	if (hi > len) hi = len;
	while (hi > lo && a.digits[hi - 1] == 0) hi--;
	if (lo >= hi) return r;
	r.digits.entries = a.digits.entries + lo;
	r.digits.size = hi - lo;
	r.digits.capacity = hi - lo;
	return r;
}

<*
 Set `r` to `high * BASE^k + low`
 @require low.digits.len() <= k : "The low half must fit below the shift"
*>
fn void join_blocks(DynBigInt* r, DynBigInt* low, DynBigInt* high, sz k) @local
{
	r.digits.clear();
	r.negative = false;
	if (high.is_zero())
	{
		r.digits.push_all(low.digits.array_view());
		r.normalize();
		return;
	}
	r.digits.reserve(k + high.digits.len());
	r.digits.push_all(low.digits.array_view());
	for (sz i = low.digits.len(); i < k; i++)
	{
		r.digits.push(0);
	}
	r.digits.push_all(high.digits.array_view());
}

<*
 Multiply by BASE to the power `k`, shifting the digits up in place.
*>
fn void shl_blocks(DynBigInt* a, sz k) @local
{
	if (k == 0 || a.is_zero()) return;
	sz n = a.digits.len();
	for (sz i = 0; i < k; i++)
	{
		a.digits.push(0);
	}
	for (sz i = n - 1; i >= 0; i--)
	{
		a.digits[i + k] = a.digits[i];
	}
	for (sz i = 0; i < k; i++)
	{
		a.digits[i] = 0;
	}
}

<*
 Subtract one from a positive number in place.
*>
fn void dec_one(DynBigInt* a) @local
{
	for (sz i = 0; i < a.digits.len(); i++)
	{
		if (a.digits[i] > 0)
		{
			a.digits[i]--;
			break;
		}
		a.digits[i] = BASE - 1;
	}
	a.normalize();
}

<*
 Long division for a divisor short enough that further recursion doesn't worth it.

 https://github.com/hcs0/Hackers-Delight/blob/master/divmnu64.c.txt

 @require b.digits.len() > 0 : "Division by zero"
 @require b.digits.len() <= DIV_LIMIT : "The divisor must be short enough for the stack buffer"
 @require a.digits.len() <= 2 * DIV_LIMIT : "The dividend must fit twice the divisor"
 @require b.digits[b.digits.len() - 1] >= BASE / 2 : "The divisor must be normalized"
*>
fn void naive_divide(DynBigInt* a, DynBigInt* b, DynBigInt* quot, DynBigInt* rem)
{
	sz nb = b.digits.len();
	sz na = a.digits.len();
	quot.digits.clear();
	rem.digits.clear();
	if (na < nb)
	{
		rem.digits.push_all(a.digits.array_view());
		rem.normalize();
		return;
	}
	ulong[] v = b.digits.array_view();
	ulong[2 * DIV_LIMIT + 2] buffer;
	ulong[] u = buffer[:na + 1];
	for (sz i = 0; i < na; i++)
	{
		u[i] = a.digits[i];
	}


	{
		while (quot.digits.len() < na - nb + 1) quot.digits.push(0);

		for (sz j = na - nb; j >= 0; j--)
		{
			uint128 head = (uint128)u[j + nb] * BASE + u[j + nb - 1];
			uint128 qhat = head / v[nb - 1];
			uint128 rhat = head % v[nb - 1];
			while (qhat >= BASE || (nb > 1 && qhat * v[nb - 2] > rhat * BASE + u[j + nb - 2]))
			{
				qhat--;
				rhat += v[nb - 1];
				if (rhat >= BASE) break;
			}

			ulong borrow = 0;
			for (sz i = 0; i < nb; i++)
			{
				uint128 piece = qhat * v[i] + borrow;
				ulong low     = (ulong)(piece % BASE);
				borrow = (ulong)(piece / BASE);
				if (u[j + i] < low)
				{
					u[j + i] += BASE - low;
					borrow++;
				}
				else
				{
					u[j + i] -= low;
				}
			}
			long deficit = (long)u[j + nb] - (long)borrow;

			while (deficit < 0)
			{
				qhat--;
				ulong carry = 0;
				for (sz i = 0; i < nb; i++)
				{
					ulong sum = u[j + i] + v[i] + carry;
					carry = sum >= BASE ? 1 : 0;
					u[j + i] = carry != 0 ? sum - BASE : sum;
				}
				deficit += (long)carry;
			}
			u[j + nb] = (ulong)deficit;
			quot.digits[j] = (ulong)qhat;
		}
		for (sz i = 0; i < nb; i++)
		{
			rem.digits.push(u[i]);
		}
	}
	quot.normalize();
	rem.normalize();
}

<*
 Divide `a` of at most 2n digits by `b` of at most n digits.

 @param [&in] a : "The dividend"
 @param [&in] b : "The divisor"
 @param n : "A power of two bounding the length of the divisor and half the dividend"
 @param quot : "The quotient, which must be zero on entry"
 @param rem : "The remainder, which must be zero on entry"

 @require n > 0 : "The block length must be positive"
 @require !a.negative && !b.negative : "The core works on magnitudes, signs belong to the caller"
 @require b.digits.len() > 0 : "Division by zero"
 @require b.digits.len() <= n : "The divisor must fit in n digits"
 @require a.digits.len() <= 2 * n : "The dividend must fit in 2n digits"
 @require quot.digits.len() == 0, rem.digits.len() == 0 : "The results must be zero"
*>
fn void div21(DynBigInt* a, DynBigInt* b, sz n, DynBigInt* quot, DynBigInt* rem)
{
	if (b.digits.len() <= DIV_LIMIT)
	{
		naive_divide(a, b, quot, rem);
		return;
	}
	Allocator allocator = a.digits.allocator;
	sz m                = n / 2;

	DynBigInt a123 = window(a, m, a.digits.len());
	DynBigInt q1;
	q1.init(allocator);
	DynBigInt r1;
	r1.init(allocator);
	div32(&a123, b, m, &q1, &r1);

	DynBigInt a4 = window(a, 0, m);
	DynBigInt tail;
	tail.init(allocator);
	join_blocks(&tail, &a4, &r1, m);

	DynBigInt q2;
	q2.init(allocator);
	div32(&tail, b, m, &q2, rem);

	join_blocks(quot, &q2, &q1, m);
}

<*
 Divide `a` of at most 3n digits by `b` of at most 2n digits.

 @param [&in] a : "The dividend"
 @param [&in] b : "The divisor"
 @param n : "A power of two bounding the quotient length and half the divisor"
 @param quot : "The quotient, which must be zero on entry"
 @param rem : "The remainder, which must be zero on entry"

 @require n > 0 : "The block length must be positive"
 @require !a.negative && !b.negative : "The core works on magnitudes, signs belong to the caller"
 @require b.digits.len() > 0 : "Division by zero"
 @require b.digits.len() <= 2 * n : "The divisor must fit in 2n digits"
 @require a.digits.len() <= 3 * n : "The dividend must fit in 3n digits"
 @require quot.digits.len() == 0, rem.digits.len() == 0 : "The results must be zero"
*>
fn void div32(DynBigInt* a, DynBigInt* b, sz n, DynBigInt* quot, DynBigInt* rem)
{
	if (b.digits.len() <= n)
	{
		div21(a, b, n, quot, rem);
		return;
	}
	Allocator allocator = a.digits.allocator;
	sz k                = b.digits.len() - n;

	DynBigInt b1  = window(b, k, b.digits.len());
	DynBigInt b2  = window(b, 0, k);
	DynBigInt a12 = window(a, k, a.digits.len());
	DynBigInt a3  = window(a, 0, k);
	DynBigInt r1;
	r1.init(allocator);

	DynBigInt a1 = window(&a12, n, a12.digits.len());
	if (cmp_digits(&a1.digits, &b1.digits) >= 0)
	{
		for (sz i = 0; i < n; i++)
		{
			quot.digits.push(BASE - 1);
		}
		DynBigInt b1_shifted = b1.copy();
		shl_blocks(&b1_shifted, n);
		sub_into(&r1, &a12, &b1_shifted);
		add_into(&r1, &r1, &b1);
	}
	else
	{
		div21(&a12, &b1, n, quot, &r1);
	}

	DynBigInt d;
	d.init(allocator);
	mul_into(&d, quot, &b2);

	DynBigInt rhat;
	rhat.init(allocator);
	join_blocks(&rhat, &a3, &r1, k);
	sub_into(rem, &rhat, &d);
	while (rem.negative)
	{
		add_into(rem, rem, b);
		dec_one(quot);
	}
}

<*
 Multiply by a single digit in place.
*>
fn void mul_small_inplace(DynBigInt* a, ulong d) @local
{
	if (d == 1 || a.is_zero()) return;
	ulong carry = 0;
	for (sz i = 0; i < a.digits.len(); i++)
	{
		uint128 cur = (uint128)a.digits[i] * d + carry;
		a.digits[i] = (ulong)(cur % BASE);
		carry = (ulong)(cur / BASE);
	}
	while (carry > 0)
	{
		a.digits.push(carry % BASE);
		carry /= BASE;
	}
	a.normalize();
}

<*
 The smallest power of two that is at least `x`.
*>
fn sz next_pow2(sz x) @local
{
	sz p = 1;
	while (p < x) p *= 2;
	return p;
}

<*
 Divide by `b`.
 https://pure.mpg.de/rest/items/item_1819444_4/component/file_2599480/content

 @param [&in] b : "The divisor"
 @param quot : "The quotient, which must be zero on entry"
 @param rem : "The remainder, which takes the sign of the dividend and must be zero on entry"

 @require !b.is_zero() : "Division by zero"
 @require quot != rem : "The results must be distinct"
 @require quot.digits.len() == 0, rem.digits.len() == 0 : "The results must be zero"
*>
fn void DynBigInt.divmod(&self, DynBigInt* b, DynBigInt* quot, DynBigInt* rem)
{
	bool quot_negative = self.negative != b.negative;
	bool rem_negative  = self.negative;

	if (b.digits.len() == 1)
	{
		ulong r;
		self.divmod_small(b.digits[0], quot, &r);
		quot.negative = quot_negative;
		quot.normalize();
		if (r != 0) rem.digits.push(r);
		rem.negative = rem_negative;
		rem.normalize();
		return;
	}
	if (cmp_digits(&self.digits, &b.digits) < 0)
	{
		assign_digits(&rem.digits, &self.digits);
		rem.negative = rem_negative;
		rem.normalize();
		return;
	}

	@pool()
	{
		ulong factor = BASE / (b.digits[b.digits.len() - 1] + 1);
		DynBigInt shifted_a;
		shifted_a.init(tmem);
		DynBigInt shifted_b;
		shifted_b.init(tmem);
		assign_digits(&shifted_a.digits, &self.digits);
		assign_digits(&shifted_b.digits, &b.digits);
		mul_small_inplace(&shifted_a, factor);
		mul_small_inplace(&shifted_b, factor);

		sz n   = next_pow2(shifted_b.digits.len());
		sz pad = n - shifted_b.digits.len();
		shl_blocks(&shifted_a, pad);
		shl_blocks(&shifted_b, pad);

		sz t = (shifted_a.digits.len() + n - 1) / n;
		DynBigInt z;
		z.init(tmem);
		DynBigInt q;
		q.init(tmem);
		for (sz i = t - 1; i >= 0; i--)
		{
			DynBigInt a_i = window(&shifted_a, i * n, (i + 1) * n);
			DynBigInt window;
			window.init(tmem);
			join_blocks(&window, &a_i, &z, n);

			DynBigInt q_i;
			q_i.init(tmem);
			DynBigInt r_i;
			r_i.init(tmem);
			div21(&window, &shifted_b, n, &q_i, &r_i);
			assign_digits(&z.digits, &r_i.digits);

			DynBigInt merged;
			merged.init(tmem);
			join_blocks(&merged, &q_i, &q, n);
			assign_digits(&q.digits, &merged.digits);
		}
		assign_digits(&quot.digits, &q.digits);

		DynBigInt r0 = window(&z, pad, z.digits.len());
		ulong dropped;
		r0.divmod_small(factor, rem, &dropped);
	};
	quot.negative = quot_negative;
	quot.normalize();
	rem.negative = rem_negative;
	rem.normalize();
}
