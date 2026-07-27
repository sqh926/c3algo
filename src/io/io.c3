// @title Fast I/O
<*
 Buffered I/O.

 `FastInput` reads the whole stream in `init` and parses out of that one buffer, so reading a
 value costs nothing. `FastOutput` fills a buffer and hands it to the file descriptor in large
 blocks, flushing whatever is left over in `free`.
*>
module c3algo::io;
import libc;

<*
 Zero padding kept behind the input so that the wide parsing loads may run past the last digit.
*>
const sz PAD @local = 64;

<*
 An upper bound on the bytes a single `write` may emit
*>
const sz MAX_VALUE_BYTES @local = 48;

<*
 The whole input stream held in one buffer, with `cur` on the next unread byte and `end` on the
 last byte that came from the stream. Everything between `end` and the end of `buf` is padding.
*>
struct FastInput
{
	Allocator allocator;
	char[] buf;
	char* cur;
	char* end;
}

<*
 Read a stream to its end into a single buffer.

 @param [&inout] allocator : "The allocator for the input buffer"
 @param fd : "The file descriptor to read, standard input by default"

 @require !self.is_initialized() : "The FastInput must not be initialized"

 @ensure self.is_initialized()
*>
fn FastInput* FastInput.init(&self, Allocator allocator, CInt fd = 0)
{
	sz capacity  = 1 << 16;
	sz length    = 0;
	char* buffer = alloc::malloc(allocator, capacity);
	while (true)
	{
		if (capacity - length < (1 << 16))
		{
			capacity *= 2;
			buffer = alloc::realloc(allocator, buffer, capacity);
		}
		sz got = libc::read(fd, buffer + length, (usz)(capacity - length));
		if (got <= 0) break;
		length += got;
	}
	buffer = alloc::realloc(allocator, buffer, length + PAD);
	mem::set(buffer + length, 0, (usz)PAD);
	self.allocator = allocator;
	self.buf = buffer[:length + PAD];
	self.cur = buffer;
	self.end = buffer + length;
	return self;
}

<*
 Read a stream to its end into a buffer taken from the temp allocator.

 Values of type `String` read out of it point into that buffer, so they die with the temp scope.

 @param fd : "The file descriptor to read, standard input by default"

 @require !self.is_initialized() : "The FastInput must not be initialized"

 @ensure self.is_initialized()
*>
fn FastInput* FastInput.tinit(&self, CInt fd = 0) @inline => self.init(tmem, fd);

<*
 Release the buffer and leave the struct uninitialized.

 @ensure !self.is_initialized()
*>
fn void FastInput.free(&self)
{
	if (!self.is_initialized()) return;
	alloc::free(self.allocator, self.buf.ptr);
	*self = { };
}

<*
 @return "`true` if the input holds a buffer"
*>
fn bool FastInput.is_initialized(&self) @inline => self.allocator != null;

<*
 Step over whitespace, stopping on the first printable byte or at the end of the input.

 @require self.is_initialized() : "The FastInput must be initialized"
*>
macro void FastInput.skip_space(&self)
{
	while (self.cur < self.end && *self.cur < 33) self.cur++;
}

<*
 Step over whitespace and report whether the input is exhausted.

 @return "`true` if nothing but whitespace is left"

 @require self.is_initialized() : "The FastInput must be initialized"
*>
fn bool FastInput.eof(&self)
{
	self.skip_space();
	return self.cur >= self.end;
}

<*
 Read one whitespace separated value.

 @param $Type : "The type to read"

 @require self.is_initialized() : "The FastInput must be initialized"

 @return "The value read"
*>
macro FastInput.read(&self, $Type)
{
	self.skip_space();
	$switch $Type:
		$case bool:
			char b = *self.cur;
			self.cur += 2;
			return b == '1';
		$case char:
			return read_char(self);
		$case ichar:
			return (ichar)read_char(self);
		$case String:
			return read_string(self);
		$default:
			$if types::is_signed($Type):
				bool neg = *self.cur == '-';
				self.cur += (usz)neg;
				$if $Type::size <= 8:
					ulong v = read_u64(self);
					return ($Type)(neg ? (ulong)(-(long)v) : v);
				$else
					uint128 v = read_u128(self);
					return ($Type)(neg ? (uint128)(-(int128)v) : v);
				$endif
			$else
				$if $Type::size <= 8:
					return ($Type)read_u64(self);
				$else
					return ($Type)read_u128(self);
				$endif
			$endif
	$endswitch
}

<*
 Read one whitespace separated value into an existing variable, taking its type from the pointer.

 @param [&out] ptr : "Where to put the value read"

 @require self.is_initialized() : "The FastInput must be initialized"
*>
macro void FastInput.read_into(&self, ptr)
{
	*ptr = self.read($Typeof(*ptr));
}

<*
 Parse an unsigned decimal number, eight digits at a time.

 @require self.cur < self.end : "The input is exhausted"
*>
fn ulong read_u64(FastInput* self) @local
{
	char* c = self.cur;
	ulong x = 0;
	while (true)
	{
		ulong w;
		mem::copy(&w, c, 8, $src_align: 1);
		w ^= 0x3030303030303030;
		if (w & 0xf0f0f0f0f0f0f0f0) break;
		w = (w * 10 + (w >> 8)) & 0x00ff00ff00ff00ff;
		w = (w * 100 + (w >> 16)) & 0x0000ffff0000ffff;
		w = (w * 10000 + (w >> 32)) & 0x00000000ffffffff;
		x = x * 100000000 + w;
		c += 8;
	}
	uint v;
	mem::copy(&v, c, 4, $src_align: 1);
	v ^= 0x30303030;
	if (!(v & 0xf0f0f0f0))
	{
		v = (v * 10 + (v >> 8)) & 0x00ff00ff;
		v = (v * 100 + (v >> 16)) & 0x0000ffff;
		x = x * 10000 + v;
		c += 4;
	}
	for (; *c >= 48; c++) x = x * 10 + (ulong)(*c & 15);
	self.cur = c + 1;
	return x;
}

<*
 Parse an unsigned decimal number into 128 bits, eight digits at a time.

 @require self.cur < self.end : "The input is exhausted"
*>
fn uint128 read_u128(FastInput* self) @local
{
	char* c   = self.cur;
	uint128 x = 0;
	while (true)
	{
		ulong w;
		mem::copy(&w, c, 8, $src_align: 1);
		w ^= 0x3030303030303030;
		if (w & 0xf0f0f0f0f0f0f0f0) break;
		w = (w * 10 + (w >> 8)) & 0x00ff00ff00ff00ff;
		w = (w * 100 + (w >> 16)) & 0x0000ffff0000ffff;
		w = (w * 10000 + (w >> 32)) & 0x00000000ffffffff;
		x = x * 100000000 + w;
		c += 8;
	}
	uint v;
	mem::copy(&v, c, 4, $src_align: 1);
	v ^= 0x30303030;
	if (!(v & 0xf0f0f0f0))
	{
		v = (v * 10 + (v >> 8)) & 0x00ff00ff;
		v = (v * 100 + (v >> 16)) & 0x0000ffff;
		x = x * 10000 + v;
		c += 4;
	}
	for (; *c >= 48; c++) x = x * 10 + (uint128)(*c & 15);
	self.cur = c + 1;
	return x;
}

<*
 Take one byte and step over the separator behind it.

 @require self.cur < self.end : "The input is exhausted"
*>
fn char read_char(FastInput* self) @local
{
	char x = *self.cur;
	self.cur += 2;
	return x;
}

<*
 Take the bytes up to the next whitespace.

 @require self.cur < self.end : "The input is exhausted"

 @return "A view into the input buffer, valid until the input is freed"
*>
fn String read_string(FastInput* self) @local
{
	char* first = self.cur;
	while (*self.cur > 32) self.cur++;
	String s = (String)first[:self.cur - first];
	self.cur++;
	return s;
}

<*
 Bytes pending a write, with `cur` on the first free byte and `end` on the end of `buf`.
*>
struct FastOutput
{
	Allocator allocator;
	CInt fd;
	char[] buf;
	char* cur;
	char* end;
}

<*
 Take a buffer to collect output in.

 @param [&inout] allocator : "The allocator for the output buffer"
 @param fd : "The file descriptor to write to, standard output by default"
 @param capacity : "The size of the buffer in bytes"

 @require !self.is_initialized() : "The FastOutput must not be initialized"
 @require capacity >= MAX_VALUE_BYTES : "The buffer must be able to hold the longest single value"

 @ensure self.is_initialized()
*>
fn FastOutput* FastOutput.init(&self, Allocator allocator, CInt fd = 1, sz capacity = 1 << 19)
{
	self.allocator = allocator;
	self.fd = fd;
	self.buf = alloc::alloc_array(allocator, char, capacity);
	self.cur = self.buf.ptr;
	self.end = self.buf.ptr + capacity;
	return self;
}

<*
 Take a buffer from the temp allocator to collect output in.

 @param fd : "The file descriptor to write to, standard output by default"
 @param capacity : "The size of the buffer in bytes"

 @require !self.is_initialized() : "The FastOutput must not be initialized"
 @require capacity >= MAX_VALUE_BYTES : "The buffer must be able to hold the longest single value"

 @ensure self.is_initialized()
*>
fn FastOutput* FastOutput.tinit(&self, CInt fd = 1, sz capacity = 1 << 19) @inline => self.init(tmem, fd, capacity);

<*
 Hand everything buffered so far to the file descriptor.

 @require self.is_initialized() : "The FastOutput must be initialized"

 @ensure self.cur == self.buf.ptr
*>
fn void FastOutput.flush(&self)
{
	usz n = (usz)(self.cur - self.buf.ptr);
	if (n) libc::write(self.fd, self.buf.ptr, n);
	self.cur = self.buf.ptr;
}

<*
 Flush, release the buffer and leave the output uninitialized.

 @ensure !self.is_initialized()
*>
fn void FastOutput.free(&self)
{
	if (!self.is_initialized()) return;
	self.flush();
	alloc::free(self.allocator, self.buf.ptr);
	*self = { };
}

<*
 @return "`true` if the output holds a buffer"
*>
fn bool FastOutput.is_initialized(&self) @inline => self.allocator != null;

<*
 Write one value.

 `bool` is written as a single `0` or `1`, `char` and `ichar` as one byte, `String` and null
 terminated strings as their bytes, and every other integer type as a decimal number.

 @param x : "The value to write"

 @require self.is_initialized() : "The FastOutput must be initialized"
*>
macro void FastOutput.write(&self, x)
{
	var $Type = $Typeof(x);
	$switch $Type:
		$case bool:
			reserve(self, 1);
			*self.cur++ = x ? '1' : '0';
		$case char:
			reserve(self, 1);
			*self.cur++ = x;
		$case ichar:
			reserve(self, 1);
			*self.cur++ = (char)x;
		$case String:
			self.write_bytes(x);
		$case char*:
			self.write_bytes((String)x[:libc::strlen(x)]);
		$case ichar*:
			self.write_bytes((String)((char*)x)[:libc::strlen((char*)x)]);
		$default:
			reserve(self, MAX_VALUE_BYTES);
			$if types::is_signed($Type):
				if (x < 0) *self.cur++ = '-';
				$if $Type::size <= 8:
					write_u64(self, x < 0 ? (ulong)(-(long)x) : (ulong)x);
				$else
					write_u128(self, x < 0 ? (uint128)(-(int128)x) : (uint128)x);
				$endif
			$else
				$if $Type::size <= 8:
					write_u64(self, (ulong)x);
				$else
					write_u128(self, (uint128)x);
				$endif
			$endif
	$endswitch
}

<*
 Write one value and a newline.

 @param x : "The value to write"

 @require self.is_initialized() : "The FastOutput must be initialized"
*>
macro void FastOutput.writeln(&self, x)
{
	self.write(x);
	self.nl();
}

<*
 Write the bytes of a string, going straight to the file descriptor if it outgrows the buffer.

 @param s : "The bytes to write"

 @require self.is_initialized() : "The FastOutput must be initialized"
*>
fn void FastOutput.write_bytes(&self, String s)
{
	sz len = (sz)s.len;
	if (len >= (sz)self.buf.len)
	{
		self.flush();
		libc::write(self.fd, s.ptr, s.len);
		return;
	}
	reserve(self, len);
	mem::copy(self.cur, s.ptr, len, $dst_align: 1, $src_align: 1);
	self.cur += len;
}

<*
 Write a space.

 @require self.is_initialized() : "The FastOutput must be initialized"
*>
macro void FastOutput.sp(&self)
{
	reserve(self, 1);
	*self.cur++ = ' ';
}

<*
 Write a newline.

 @require self.is_initialized() : "The FastOutput must be initialized"
*>
macro void FastOutput.nl(&self)
{
	reserve(self, 1);
	*self.cur++ = '\n';
}

char[4][10000] full_lut @local;
char[4][10000] head_lut @local;
char[10000] head_len @local;


fn void build_lut() @init @local
{
	for (int i = 0; i < 10000; i++)
	{
		full_lut[i][0] = (char)('0' + i / 1000);
		full_lut[i][1] = (char)('0' + i / 100 % 10);
		full_lut[i][2] = (char)('0' + i / 10 % 10);
		full_lut[i][3] = (char)('0' + i % 10);
		int len = 1 + (int)(i >= 10) + (int)(i >= 100) + (int)(i >= 1000);
		head_len[i] = (char)len;
		for (int j = 0; j < len; j++) head_lut[i][j] = full_lut[i][4 - len + j];
	}
}

<*
 Make room for `need` bytes, flushing the buffer if it holds too much already.

 @param need : "The number of bytes about to be written"

 @require need <= (sz)self.buf.len : "The buffer is too small to ever hold that many bytes"

 @ensure self.end - self.cur >= need
*>
macro void reserve(FastOutput* self, sz need) @local
{
	if (self.end - self.cur < need) self.flush();
}

<*
 Write `x` as `$g + 1` groups of four digits, the first one trimmed to its own width.

 @param $g : "The number of full four digit groups behind the leading one"
 @param x : "The value to write, below `10000 ^ ($g + 1)`"
*>
macro void @groups(FastOutput* self, $g, x) @local
{
	$switch:
		$case $g == 0:
			mem::copy(self.cur, &head_lut[x], 4, $dst_align: 1);
			self.cur += head_len[x];
		$default:
			@groups(self, $g - 1, x / 10000);
			mem::copy(self.cur, &full_lut[x % 10000], 4, $dst_align: 1);
			self.cur += 4;
	$endswitch
}

<*
 Write `x` as exactly sixteen digits.

 @param x : "The value to write, below `10 ^ 16`"
*>
macro void @groups16(FastOutput* self, x) @local
{
	mem::copy(self.cur, &full_lut[x / 1_000_000_000_000 % 10000], 4, $dst_align: 1);
	self.cur += 4;
	mem::copy(self.cur, &full_lut[x / 100_000_000 % 10000], 4, $dst_align: 1);
	self.cur += 4;
	mem::copy(self.cur, &full_lut[x / 10000 % 10000], 4, $dst_align: 1);
	self.cur += 4;
	mem::copy(self.cur, &full_lut[x % 10000], 4, $dst_align: 1);
	self.cur += 4;
}

<*
 Write a number in as few digits as it needs.
*>
fn void write_u64(FastOutput* self, ulong x) @local
{
	switch
	{
		case x > 9_999_999_999_999_999: @groups(self, 4, x);
		case x > 999_999_999_999: @groups(self, 3, x);
		case x > 99_999_999: @groups(self, 2, x);
		case x > 9999: @groups(self, 1, (uint)x);
		default: @groups(self, 0, (uint)x);
	}
}

const uint128 E19 @local = 10_000_000_000_000_000_000;
const uint128 E38 @local = E19 * E19;

<*
 Write a number as exactly nineteen digits, zero padded.

 @param x : "The value to write, below `10 ^ 19`"

 @require x < (ulong)E19 : "A larger value does not fit in nineteen digits"
*>
fn void write_w19(FastOutput* self, ulong x) @local
{
	ulong top  = x / 10_000_000_000_000_000;
	ulong rest = x % 10_000_000_000_000_000;
	mem::copy(self.cur, &full_lut[top][1], 3, $dst_align: 1);
	self.cur += 3;
	@groups16(self, rest);
}

<*
 `ceil(2 ^ 191 / 10 ^ 19)`
*>
const uint128 E19_CONST @local = 0xec1e4a7db69561a52b31e9e3d06c32e6;

<*
 The top half of a 256 bit product

 @param a : "The first factor"
 @param b : "The second factor"

 @return "`(a * b) >> 128`"
*>
fn uint128 mul_high(uint128 a, uint128 b) @local @inline
{
	ulong a_low  = (ulong)a;
	ulong a_high = (ulong)(a >> 64);
	ulong b_low  = (ulong)b;
	ulong b_high = (ulong)(b >> 64);

	uint128 low   = (uint128)a_low * b_low;
	uint128 mid   = (uint128)a_low * b_high;
	uint128 mid2  = (uint128)a_high * b_low;
	uint128 high  = (uint128)a_high * b_high;
	uint128 carry = (low >> 64) + (ulong)mid + (ulong)mid2;

	return high + (mid >> 64) + (mid2 >> 64) + (carry >> 64);
}

<*
 Divide by `10 ^ 19`.

 Compiler cannot optimize it itself, and produces `__udivti3` assembly intstruction, which is too slow for our needs.

 `x * E19_CONST >> 191` = `x / 10 ^ 19`
 @param x : "The value to divide"

 @require (x >> 64) < E19 : "The quotient has to fit in 64 bits"

 @return "The quotient and the remainder"
*>
fn ulong[2] divmod_1e19(uint128 x) @local @inline
{
	ulong q = (ulong)(mul_high(x, E19_CONST) >> 63);
	ulong r = (ulong)(x - (uint128)q * (ulong)E19);
	return { q, r };
}

<*
 Write a number in as few digits as it needs, splitting it into chunks of nineteen digits.
*>
fn void write_u128(FastOutput* self, uint128 x) @local
{
	if (x < E19)
	{
		write_u64(self, (ulong)x);
	}
	else if (x < E38)
	{
		ulong[2] qr = divmod_1e19(x);
		write_u64(self, qr[0]);
		write_w19(self, qr[1]);
	}
	else
	{
		ulong top = 1;
		if (x >= 3 * E38)
		{
			top = 3;
		}
		else if (x >= 2 * E38)
		{
			top = 2;
		}
		x -= (uint128)top * E38;
		ulong[2] qr = divmod_1e19(x);
		*self.cur++ = (char)('0' + top);
		write_w19(self, qr[0]);
		write_w19(self, qr[1]);
	}
}