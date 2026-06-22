module c3algo::io;
import std::core::mem;
import std::core::types;
import libc;

const usz PAD = 64;

struct FastInput
{
	char* buf;
	char* cur;
	char* end;
}

fn void FastInput.init(&self, CInt fd = 0)
{
	usz cap = 1 << 16;
	usz len = 0;
	char* b = libc::malloc(cap);
	while (true)
	{
		if (cap - len < (1 << 16))
		{
			cap *= 2;
			b = libc::realloc(b, cap);
		}
		sz n = libc::read(fd, b + len, cap - len);
		if (n <= 0) break;
		len += (usz)n;
	}
	b = libc::realloc(b, len + PAD);
	mem::set(b + len, 0, PAD);
	self.buf = b;
	self.cur = b;
	self.end = b + len;
}

fn void FastInput.free(&self)
{
	if (self.buf) libc::free(self.buf);
	*self = { };
}

fn bool FastInput.eof(&self)
{
	self.skip_space();
	return self.cur >= self.end;
}

macro void FastInput.skip_space(&self)
{
	while (self.cur < self.end && *self.cur < 33) self.cur++;
}

fn ulong FastInput.read_u64(&self)
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

fn uint128 FastInput.read_u128(&self)
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

fn char FastInput.read_char(&self)
{
	char x = *self.cur;
	self.cur += 2;
	return x;
}

fn String FastInput.read_string(&self)
{
	char* first = self.cur;
	while (*self.cur > 32) self.cur++;
	String s = (String)first[:self.cur - first];
	self.cur++;
	return s;
}

macro FastInput.read(&self, $Type)
{
	self.skip_space();
	$switch $Type:
		$case bool:
			char b = *self.cur;
			self.cur += 2;
			return b == '1';
		$case char:
			return self.read_char();
		$case ichar:
			return (ichar)self.read_char();
		$case String:
			return self.read_string();
		$default:
			$if types::is_signed($Type):
				bool neg = *self.cur == '-';
				self.cur += (usz)neg;
				$if $Type::size <= 8:
					ulong v = self.read_u64();
					return ($Type)(neg ? (ulong)(-(long)v) : v);
				$else
					uint128 v = self.read_u128();
					return ($Type)(neg ? (uint128)(-(int128)v) : v);
				$endif
			$else
				$if $Type::size <= 8:
					return ($Type)self.read_u64();
				$else
					return ($Type)self.read_u128();
				$endif
			$endif
	$endswitch
}

macro void FastInput.read_into(&self, ptr)
{
	*ptr = self.read($Typeof(*ptr));
}

tlocal char[4][10000] full_lut @private;
tlocal char[4][10000] head_lut @private;
tlocal char[10000] head_len @private;
tlocal bool lut_ready @private;

fn void build_lut() @private
{
	if (lut_ready) return;
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
	lut_ready = true;
}

struct FastOutput
{
	CInt fd;
	char* buf;
	char* cur;
	char* end;
	usz cap;
}

fn void FastOutput.init(&self, CInt fd = 1, usz cap = 1 << 19)
{
	build_lut();
	self.fd = fd;
	self.buf = libc::malloc(cap);
	self.cur = self.buf;
	self.end = self.buf + cap;
	self.cap = cap;
}

fn void FastOutput.flush(&self)
{
	usz n = (usz)(self.cur - self.buf);
	if (n) libc::write(self.fd, self.buf, n);
	self.cur = self.buf;
}

fn void FastOutput.free(&self)
{
	if (self.buf)
	{
		self.flush();
		libc::free(self.buf);
	}
	*self = { };
}

macro void FastOutput.reserve(&self, usz need)
{
	if ((usz)(self.end - self.cur) < need) self.flush();
}

macro void FastOutput.@groups(&self, $g, x)
{
	$switch:
		$case $g == 0:
			mem::copy(self.cur, &head_lut[x], 4, $dst_align: 1);
			self.cur += head_len[x];
		$default:
			self.@groups($g - 1, x / 10000);
			mem::copy(self.cur, &full_lut[x % 10000], 4, $dst_align: 1);
			self.cur += 4;
	$endswitch
}

fn void FastOutput.write_u64(&self, ulong x)
{
	switch
	{
		case x > 9_999_999_999_999_999: self.@groups(4, x);
		case x > 999_999_999_999: self.@groups(3, x);
		case x > 99_999_999: self.@groups(2, x);
		case x > 9999: self.@groups(1, (uint)x);
		default: self.@groups(0, (uint)x);
	}
}

const uint128 E19 = 10_000_000_000_000_000_000;
const uint128 E38 = E19 * E19;

macro void FastOutput.@groups16(&self, x)
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

fn void FastOutput.write_w19(&self, ulong x)
{
	ulong top  = x / 10_000_000_000_000_000;
	ulong rest = x % 10_000_000_000_000_000;
	mem::copy(self.cur, &full_lut[top][1], 3, $dst_align: 1);
	self.cur += 3;
	self.@groups16(rest);
}

// For some reason compiler cant optimize x / E19 and uses __udivti3
// here we explicitly use divq for dividing u128 over u64
fn ulong[2] divmod_1e19(uint128 x) @local @inline
{
	$if env::X86_64:
		ulong hi = (ulong)(x >> 64);
		ulong lo = (ulong)x;
		ulong d  = 10_000_000_000_000_000_000;
		ulong q, r;
		asm
		{
			movq $rax, lo;
			movq $rdx, hi;
			divq d;
			movq q, $rax;
			movq r, $rdx;
		}
		return { q, r };
	$else
		return { (ulong)(x / E19), (ulong)(x % E19) };
	$endif
}

fn void FastOutput.write_u128(&self, uint128 x)
{
	if (x < E19)
	{
		self.write_u64((ulong)x);
	}
	else if (x < E38)
	{
		ulong[2] qr = divmod_1e19(x);
		self.write_u64(qr[0]);
		self.write_w19(qr[1]);
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
		self.write_w19(qr[0]);
		self.write_w19(qr[1]);
	}
}

macro void FastOutput.write(&self, x)
{
	var $Type = $Typeof(x);
	$switch $Type:
		$case bool:
			self.reserve(1);
			*self.cur++ = x ? '1' : '0';
		$case char:
			self.reserve(1);
			*self.cur++ = x;
		$case ichar:
			self.reserve(1);
			*self.cur++ = (char)x;
		$case String:
			self.write_bytes(x);
		$case char*:
			self.write_bytes((String)x[:libc::strlen(x)]);
		$case ichar*:
			self.write_bytes((String)((char*)x)[:libc::strlen((char*)x)]);
		$default:
			self.reserve(48);
			$if types::is_signed($Type):
				if (x < 0) *self.cur++ = '-';
				$if $Type::size <= 8:
					self.write_u64(x < 0 ? (ulong)(-(long)x) : (ulong)x);
				$else
					self.write_u128(x < 0 ? (uint128)(-(int128)x) : (uint128)x);
				$endif
			$else
				$if $Type::size <= 8:
					self.write_u64((ulong)x);
				$else
					self.write_u128((uint128)x);
				$endif
			$endif
	$endswitch
}

fn void FastOutput.write_bytes(&self, String s)
{
	usz len = s.len;
	if (len >= self.cap)
	{
		self.flush();
		libc::write(self.fd, s.ptr, len);
		return;
	}
	self.reserve(len);
	mem::copy(self.cur, s.ptr, (sz)len, $dst_align: 1, $src_align: 1);
	self.cur += (sz)len;
}

macro void FastOutput.writeln(&self, x)
{
	self.write(x);
	self.nl();
}

macro void FastOutput.sp(&self)
{
	self.reserve(1);
	*self.cur++ = ' ';
}

macro void FastOutput.nl(&self)
{
	self.reserve(1);
	*self.cur++ = '\n';
}
