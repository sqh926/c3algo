module c3algo::bigint <RADIX>;

import std::collections::list;
import std::math;
import std::core::mem::alloc;
import c3algo::conv::fft;

const ulong BASE         = RADIX == 10 ? 10_000_000_000_000_000UL : 1UL << 60;
// Cannot directly use FFT with such a big base, so, for multiplication use the smaller one
const ulong SMALL_BASE   = RADIX == 10 ? 10_000UL : 1UL << 15;
const sz CHUNKS          = RADIX == 10 ? 4 : 4;
const int DIGIT_LENGTH   = RADIX == 10 ? 16 : 15;
const String DIGIT_CHARS = "0123456789abcdef";

alias fft_conv = fft::convolution{double};
alias ULongList = List{ulong};

struct DynBigInt
{
	ULongList digits;
	bool negative;
}

fn DynBigInt zero(Allocator allocator = mem)
{
	DynBigInt r;
	r.digits.allocator = allocator;
	return r;
}

fn void DynBigInt.free(&self)
{
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
			dst[CHUNKS * i + j] = (long)(val % SMALL_BASE);
			val /= SMALL_BASE;
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
			limb += (ulong)(carry % (long)SMALL_BASE) * shift;
			carry /= (long)SMALL_BASE;
			shift *= SMALL_BASE;
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
	DynBigInt r = zero(self.digits.allocator);
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
	DynBigInt r = zero(self.digits.allocator);
	add_into(&r, self, &o);
	return r;
}

fn DynBigInt DynBigInt.sub(&self, DynBigInt o) @operator(-)
{
	DynBigInt r = zero(self.digits.allocator);
	sub_into(&r, self, &o);
	return r;
}

fn DynBigInt DynBigInt.mul(&self, DynBigInt o) @operator(*)
{
	DynBigInt r = zero(self.digits.allocator);
	mul_into(&r, self, &o);
	return r;
}

fn ulong digit_val(char c) @local @inline
{
	if (c <= '9') return (ulong)(c - '0');
	if (c >= 'a') return (ulong)(c - 'a' + 10);
	return (ulong)(c - 'A' + 10);
}

fn DynBigInt from_string(String s, Allocator allocator = mem)
{
	DynBigInt r = zero(allocator);
	sz i        = 0;
	if (s.len > 0 && (s[0] == '-' || s[0] == '+'))
	{
		if (s[0] == '-') r.negative = true;
		i = 1;
	}
	r.digits.reserve(((sz)s.len - i + DIGIT_LENGTH - 1) / DIGIT_LENGTH);
	for (sz end = (sz)s.len; end > i; end -= DIGIT_LENGTH)
	{
		sz start = end - DIGIT_LENGTH;
		if (start < i) start = i;
		ulong limb = 0;
		for (sz j = start; j < end; j++) limb = limb * RADIX + digit_val(s[j]);
		r.digits.push(limb);
	}
	r.normalize();
	return r;
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
