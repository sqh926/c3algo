// @title Big Integer
<*
 An arbitrary precision integer.

 INSTANTIATE
     import c3algo::bigint;

     alias BigInt = bigint::DynBigInt {10};

 API
     DynBigInt* init(Allocator allocator)                zero
     DynBigInt* init_with(Allocator allocator, String s) parsed from text, sign allowed
     DynBigInt* tinit() / tinit_with(String s)           the same on the temp allocator
     void free()
     bool is_initialized()
     bool is_zero()
     DynBigInt copy()
     + - * / % and unary -
     DynBigInt sqrt()                                    integer square root
     void sqrt_into(DynBigInt* root)
     void divmod(DynBigInt* b, DynBigInt* quot, DynBigInt* rem)
     void divmod_small(ulong d, DynBigInt* quot, ulong* rem)
     String to_string(Allocator allocator)
     void add_into / sub_into / mul_into(DynBigInt* r, DynBigInt* a, DynBigInt* b)

     The operators allocate a result every time. In a loop prefer the into forms.

 USE
     BigInt a;
     BigInt b;
     a.init_with(mem, "123456789012345678901234567890");
     b.init_with(mem, "-98765432109876543210");
     defer a.free();
     defer b.free();

     BigInt c = a * b;
     out.writeln(c.to_string(mem));
*>
module c3algo::bigint <RADIX>;

import std::collections::list;
import std::math;
import c3algo::convolution::fft;

const ulong BASE = RADIX == 10 ? 10_000_000_000_000_000UL : 1UL << 60;

<*
 The base used for the FFT product, small enough that the convolution stays exact in doubles
*>
const ulong FFT_BASE = RADIX == 10 ? 10_000UL : 1UL << 15;
const sz CHUNKS          = 4;
const int DIGIT_LENGTH   = RADIX == 10 ? 16 : 15;
const String DIGIT_CHARS = "0123456789abcdef";

<*
 The base of the naive product, small enough that a piece product fits in a ulong
*>
const ulong PIECE_BASE = RADIX == 10 ? 100_000_000UL : 1UL << 20;
const sz PIECES = RADIX == 10 ? 2 : 3;

<*
 Up to this many digits the divisor is handled by long division instead of more recursion
*>
const sz DIV_LIMIT = 4;

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

<*
 a + b + carry, leaving the carry out in `carry`
*>
macro ulong add_carry(ulong a, ulong b, ulong* carry) @local
{
	ulong sum = a + b + *carry;
	if (sum >= BASE)
	{
		*carry = 1;
		return sum - BASE;
	}
	*carry = 0;
	return sum;
}

<*
 a - b - borrow, leaving the borrow out in `borrow`
*>
macro ulong sub_borrow(ulong a, ulong b, ulong* borrow) @local
{
	ulong sub = b + *borrow;
	if (a >= sub)
	{
		*borrow = 0;
		return a - sub;
	}
	*borrow = 1;
	return a + BASE - sub;
}

<*
 Pad with zeros up to `n` digits
*>
fn void pad_digits(ULongList* dst, sz n) @local @inline
{
	if (dst.len() >= n) return;
	dst.reserve(n - dst.len());
	while (dst.len() < n) dst.push(0);
}

<*
 dst += src
*>
fn void add_digits_inplace(ULongList* dst, ULongList* src)
{
	pad_digits(dst, src.len());
	ulong[] a   = dst.array_view();
	ulong[] b   = src.array_view();
	ulong carry = 0;
	for (sz i = 0; i < b.len; i++)
	{
		a[i] = add_carry(a[i], b[i], &carry);
	}
	for (sz i = b.len; carry != 0; i++)
	{
		if (i == a.len)
		{
			dst.push(carry);
			return;
		}
		a[i] = add_carry(a[i], 0, &carry);
	}
}

<*
 dst -= src, dst >= src
*>
fn void sub_digits_inplace(ULongList* dst, ULongList* src)
{
	ulong[] a    = dst.array_view();
	ulong[] b    = src.array_view();
	ulong borrow = 0;
	for (sz i = 0; i < b.len; i++)
	{
		a[i] = sub_borrow(a[i], b[i], &borrow);
	}
	for (sz i = b.len; borrow != 0; i++)
	{
		a[i] = sub_borrow(a[i], 0, &borrow);
	}
}

<*
 dst = src - dst, src >= dst
*>
fn void rsub_digits_inplace(ULongList* dst, ULongList* src)
{
	dst.reserve(src.len() - dst.len());
	ulong[] a    = dst.array_view();
	ulong[] b    = src.array_view();
	ulong borrow = 0;
	for (sz i = 0; i < a.len; i++)
	{
		a[i] = sub_borrow(b[i], a[i], &borrow);
	}
	for (sz i = a.len; i < b.len; i++)
	{
		dst.push(sub_borrow(b[i], 0, &borrow));
	}
}

<*
 r = a + b ignoring signs, r may alias a or b
*>
fn void add_unsigned_into(DynBigInt* r, DynBigInt* a, DynBigInt* b) @local
{
	if (r == b) @swap(a, b);
	if (r != a) assign_digits(&r.digits, &a.digits);
	add_digits_inplace(&r.digits, &b.digits);
}

<*
 r = a - b ignoring signs, a >= b, r may alias a or b
*>
fn void sub_unsigned_into(DynBigInt* r, DynBigInt* a, DynBigInt* b) @local
{
	if (r == b)
	{
		rsub_digits_inplace(&r.digits, &a.digits);
		return;
	}
	if (r != a) assign_digits(&r.digits, &a.digits);
	sub_digits_inplace(&r.digits, &b.digits);
}

<*
 r = a + b with the signs passed separately, r may alias a or b
*>
fn void add_signed_into(DynBigInt* r, DynBigInt* a, bool a_neg, DynBigInt* b, bool b_neg) @local
{
	if (a_neg == b_neg)
	{
		add_unsigned_into(r, a, b);
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
		sub_unsigned_into(r, a, b);
	}
	r.negative = a_neg;
	r.normalize();
}

<*
 r = a + b, r may alias a or b
*>
fn void add_into(DynBigInt* r, DynBigInt* a, DynBigInt* b) @inline
{
	add_signed_into(r, a, a.negative, b, b.negative);
}

<*
 r = a - b, r may alias a or b
*>
fn void sub_into(DynBigInt* r, DynBigInt* a, DynBigInt* b) @inline
{
	add_signed_into(r, a, a.negative, b, !b.negative);
}

macro split_digits($Piece, dst, ULongList* src, $base, $count) @local
{
	for (sz i = 0; i < src.len(); i++)
	{
		ulong val = src.[i];
		for (sz j = 0; j < $count; j++)
		{
			dst[$count * i + j] = ($Piece)(val % $base);
			val /= $base;
		}
	}
}

macro ulong join_pieces(ulong[] pieces, $base, $count) @local
{
	ulong digit = 0;
	ulong shift = 1;
	for (sz j = 0; j < $count; j++)
	{
		digit += pieces[j] * shift;
		shift *= $base;
	}
	return digit;
}

<*
 r = a * b, r must not alias a or b
*>
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
		split_digits(ulong, pa, &a.digits, PIECE_BASE, PIECES);
		split_digits(ulong, pb, &b.digits, PIECE_BASE, PIECES);
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
			r.digits.push(join_pieces(acc[i:PIECES], PIECE_BASE, PIECES));
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

<*
 r = a * b, r must not alias a or b

 @require r != a, r != b : "The result must not alias an operand"
*>
fn void mul_into(DynBigInt* r, DynBigInt* a, DynBigInt* b)
{
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
		split_digits(long, sa, &a.digits, FFT_BASE, CHUNKS);
		split_digits(long, sb, &b.digits, FFT_BASE, CHUNKS);
		while (la > 1 && sa[la - 1] == 0) la--;
		while (lb > 1 && sb[lb - 1] == 0) lb--;
		long[] conv = alloc::new_array(tmem, long, la + lb - 1);
		fft_conv(conv, sa[:la], sb[:lb], tmem);

		r.digits.clear();
		r.digits.reserve(a.digits.len() + b.digits.len() + 1);
		long carry  = 0;
		ulong digit = 0;
		ulong shift = 1;
		for (sz i = 0; i < conv.len || carry != 0; i++)
		{
			if (i < conv.len) carry += conv[i];
			digit += (ulong)(carry % (long)FFT_BASE) * shift;
			carry /= (long)FFT_BASE;
			shift *= FFT_BASE;
			if (shift == BASE)
			{
				r.digits.push(digit);
				digit = 0;
				shift = 1;
			}
		}
		if (shift != 1) r.digits.push(digit);
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
 @param [&out] rem : "The absolute value of the remainder, whose sign is the sign of the dividend"

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
	pad_digits(&quot.digits, n);
	ulong[] q = quot.digits.array_view();
	ulong[] a = self.digits.array_view();
	ulong r   = 0;
	for (sz i = n - 1; i >= 0; i--)
	{
		uint128 c = (uint128)r * BASE + a[i];
		q[i] = (ulong)(c / d);
		r = (ulong)(c % d);
	}
	quot.negative = self.negative;
	quot.normalize();
	*rem = r;
}

<*
 A fresh zero living in `allocator`
*>
fn DynBigInt empty(Allocator allocator) @local
{
	DynBigInt r;
	r.init(allocator);
	return r;
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
	pad_digits(&r.digits, k);
	r.digits.push_all(high.digits.array_view());
}

<*
 Multiply by BASE to the power `k`, shifting the digits up in place.
*>
fn void shl_blocks(DynBigInt* a, sz k) @local
{
	if (k == 0 || a.is_zero()) return;
	sz n = a.digits.len();
	pad_digits(&a.digits, n + k);
	ulong[] d = a.digits.array_view();
	for (sz i = n - 1; i >= 0; i--)
	{
		d[i + k] = d[i];
	}
	d[:k] = 0;
}

<*
 Subtract one from a positive number in place.
*>
fn void dec_one(DynBigInt* a) @local
{
	ulong[] d    = a.digits.array_view();
	ulong borrow = 1;
	for (sz i = 0; borrow != 0; i++)
	{
		d[i] = sub_borrow(d[i], 0, &borrow);
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
	u[:na] = a.digits.array_view()[..];

	pad_digits(&quot.digits, na - nb + 1);
	ulong[] q = quot.digits.array_view();

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
			ulong taken   = 0;
			u[j + i] = sub_borrow(u[j + i], (ulong)(piece % BASE), &taken);
			borrow = (ulong)(piece / BASE) + taken;
		}
		long deficit = (long)u[j + nb] - (long)borrow;

		while (deficit < 0)
		{
			qhat--;
			ulong carry = 0;
			for (sz i = 0; i < nb; i++)
			{
				u[j + i] = add_carry(u[j + i], v[i], &carry);
			}
			deficit += (long)carry;
		}
		u[j + nb] = (ulong)deficit;
		q[j] = (ulong)qhat;
	}
	rem.digits.push_all(u[:nb]);
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
 @require !a.negative && !b.negative : "The core works on unsigned values, signs belong to the caller"
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
	DynBigInt q1   = empty(allocator);
	DynBigInt r1   = empty(allocator);
	div32(&a123, b, m, &q1, &r1);

	DynBigInt a4   = window(a, 0, m);
	DynBigInt tail = empty(allocator);
	join_blocks(&tail, &a4, &r1, m);

	DynBigInt q2 = empty(allocator);
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
 @require !a.negative && !b.negative : "The core works on unsigned values, signs belong to the caller"
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
	DynBigInt r1  = empty(allocator);

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

	DynBigInt d = empty(allocator);
	mul_into(&d, quot, &b2);

	DynBigInt rhat = empty(allocator);
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
 Set `a` to `BASE^k`.
*>
fn void set_block_pow(DynBigInt* a, sz k) @local
{
	a.digits.clear();
	a.negative = false;
	a.digits.reserve(k + 1);
	for (sz i = 0; i < k; i++)
	{
		a.digits.push(0);
	}
	a.digits.push(1);
}

<*
 @require d < BASE : "The value must fit in a single digit"
*>
fn int cmp_small(DynBigInt* a, ulong d) @local
{
	if (a.digits.len() > 1) return 1;
	ulong v = a.is_zero() ? 0 : a.digits[0];
	if (v == d) return 0;
	return v < d ? -1 : 1;
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
		ulong factor        = BASE / (b.digits[b.digits.len() - 1] + 1);
		DynBigInt shifted_a = empty(tmem);
		DynBigInt shifted_b = empty(tmem);
		assign_digits(&shifted_a.digits, &self.digits);
		assign_digits(&shifted_b.digits, &b.digits);
		mul_small_inplace(&shifted_a, factor);
		mul_small_inplace(&shifted_b, factor);

		sz n   = next_pow2(shifted_b.digits.len());
		sz pad = n - shifted_b.digits.len();
		shl_blocks(&shifted_a, pad);
		shl_blocks(&shifted_b, pad);

		sz t        = (shifted_a.digits.len() + n - 1) / n;
		DynBigInt z = empty(tmem);
		pad_digits(&quot.digits, t * n);
		ulong[] qd = quot.digits.array_view();
		for (sz i = t - 1; i >= 0; i--)
		{
			DynBigInt a_i   = window(&shifted_a, i * n, (i + 1) * n);
			DynBigInt block = empty(tmem);
			join_blocks(&block, &a_i, &z, n);

			DynBigInt q_i = empty(tmem);
			DynBigInt r_i = empty(tmem);
			div21(&block, &shifted_b, n, &q_i, &r_i);
			assign_digits(&z.digits, &r_i.digits);

			qd[i * n:q_i.digits.len()] = q_i.digits.array_view()[..];
		}

		DynBigInt r0 = window(&z, pad, z.digits.len());
		ulong dropped;
		r0.divmod_small(factor, rem, &dropped);
	};
	quot.negative = quot_negative;
	quot.normalize();
	rem.negative = rem_negative;
	rem.normalize();
}

<*
 The integer square root, the largest `x` with `x * x <= self`.
 Untested + slow algorithm.

 @param [&out] root : "The root, which must be zero on entry and must not alias the input"

 @require !self.negative : "A negative number has no integer square root"
 @require root != self : "The root must not alias the input"
 @require root.digits.len() == 0 : "The root must be zero"
*>
fn void DynBigInt.sqrt_into(&self, DynBigInt* root)
{
	if (self.is_zero()) return;
	@pool()
	{
		sz half = (self.digits.len() + 1) / 2;
		DynBigInt l;
		l.tinit();
		DynBigInt r;
		r.tinit();
		set_block_pow(&l, half - 1);
		set_block_pow(&r, half);

		DynBigInt mid;
		mid.tinit();
		DynBigInt square;
		square.tinit();
		DynBigInt gap;
		gap.tinit();

		sub_into(&gap, &r, &l);
		while (cmp_small(&gap, 1) > 0)
		{
			ulong dropped;
			add_into(&mid, &l, &r);
			mid.divmod_small(2, &mid, &dropped);
			mul_into(&square, &mid, &mid);
			if (cmp_digits(&square.digits, &self.digits) <= 0)
			{
				assign_digits(&l.digits, &mid.digits);
			}
			else
			{
				assign_digits(&r.digits, &mid.digits);
			}
			sub_into(&gap, &r, &l);
		}
		assign_digits(&root.digits, &l.digits);
	};
	root.negative = false;
	root.normalize();
}

<*
 The integer square root, the largest `x` with `x * x <= self`.

 @require !self.negative : "A negative number has no integer square root"
*>
fn DynBigInt DynBigInt.sqrt(&self)
{
	DynBigInt root;
	root.init(self.digits.allocator);
	self.sqrt_into(&root);
	return root;
}