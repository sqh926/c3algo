// @title Matrix Product
// PROBLEM: https://judge.yosupo.jp/problem/matrix_product

import c3algo::io;
import c3algo::numbertheory::modint;

const int MAXN = 1024;
alias Mint = ModInt{998244353};

Mint[MAXN][MAXN] a;
Mint[MAXN][MAXN] b;
Mint[MAXN][MAXN] c;

fn void main()
{
	FastInput inp;
	inp.init(mem);
	defer inp.free();
	FastOutput out;
	out.init(mem);
	defer out.free();

	int n = inp.read(int);
	int t = inp.read(int);
	int m = inp.read(int);

	for (int i = 0; i < n; i++)
	{
		for (int j = 0; j < t; j++)
		{
			a[i][j].init(inp.read(long));
		}
	}
	for (int i = 0; i < t; i++)
	{
		for (int j = 0; j < m; j++)
		{
			b[i][j].init(inp.read(long));
		}
	}

	// Split the rows of C into block
	// that helps with caching reads from b[j][k]
	const int BLOCK = 32;
	for (int i0 = 0; i0 < n; i0 += BLOCK)
	{
		int clamped = i0 + BLOCK < n ? i0 + BLOCK : n;
		for (int j = 0; j < t; j++)
		{
			for (int i = i0; i < clamped; i++)
			{
				// llvm lowers (u64)(u32) * (u64)(u32) to a single vpmuludq
				uint x = (uint)a[i][j].val();
				for (int k = 0; k < m; k++)
				{
					c[i][k].add_unsafe((ulong)x * (ulong)(uint)b[j][k].val());
				}
			}
			if (j % 8 == 0)
			{
				for (int i = i0; i < clamped; i++)
				{
					for (int k = 0; k < m; k++)
					{
						c[i][k].pseudonormalize();
					}
				}
			}
		}
	}

	for (int i = 0; i < n; i++)
	{
		for (int j = 0; j < m; j++)
		{
			c[i][j].normalize();
			out.write(c[i][j].val());
			if (j + 1 == m)
			{
				out.nl();
			}
			else
			{
				out.sp();
			}
		}
	}
}