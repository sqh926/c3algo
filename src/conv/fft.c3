// @title fft
module c3algo::conv::fft <Real>;

import std::math::complex, std::math;

alias Ftype = ComplexNumber{Real};

fn void fft_inplace(Ftype[] in, bool inverse)
{
	int n    = (int)in.len;
	int logn = n.ctz();
	static int[] rev;
	if (rev.len != n)
	{
		if (rev.len != 0) mem::free(rev);
		rev = mem::new_array(int, n);
		for (int i = 0; i < n; i++)
		{
			rev[i] = (rev[i >> 1] >> 1) | ((i & 1) << (logn - 1));
		}
	}
	for (int i = 0; i < n; i++)
	{
		if (i < rev[i]) @swap(in[i], in[rev[i]]);
	}
	static Ftype[] w;
	if (w.len != n)
	{
		if (w.len != 0) mem::free(w);
		int half = n / 2;
		w = mem::new_array(Ftype, half);
		for (int k = 0; k < half; k++)
		{
			Real ang = 2 * (Real)math::PI * k / n;
			w[k] = { .r = (Real)math::cos(ang), .c = (Real)math::sin(ang) };
		}
	}

	for (int len = 2; len <= n; len *= 2)
	{
		int step = n / len;
		for (int i = 0; i < n; i += len)
		{
			for (int j = 0; j < len / 2; j++)
			{
				Ftype u = in[i + j];
				Ftype v = in[i + j + len / 2] * w[j * step];
				in[i + j] = u + v;
				in[i + j + len / 2] = u - v;
			}
		}
	}
	if (inverse)
	{
		in[0] /= n;
		for (int i = 1; i < n / 2; i++)
		{
			in[i] /= n;
			in[n - i] /= n;
			@swap(in[i], in[n - i]);
		}
	}
}
