// @title Union Find
// PROBLEM: https://judge.yosupo.jp/problem/unionfind

import std::io;
import c3algo::ds::unionfind;

fn long next(char[] buf, usz* pos)
{
    usz n = buf.len;
    while (*pos < n)
    {
        char c = buf[*pos];
        if (c >= '0' && c <= '9') break;
        (*pos)++;
    }
    long v = 0;
    while (*pos < n)
    {
        char c = buf[*pos];
        if (c < '0' || c > '9') break;
        v = v * 10 + (long)(c - '0');
        (*pos)++;
    }
    return v;
}

fn void main()
{
    char[] buf = io::read_fully(mem, io::stdin())!!;
    usz pos = 0;

    int n = (int)next(buf, &pos);
    int q = (int)next(buf, &pos);

    UnionFind uf;
    uf.init((usz)n);
    defer uf.free();

    ByteWriter out;
    out.init(mem, 1 << 16);
    defer (void)out.destroy();

    for (int i = 0; i < q; i++)
    {
        int t = (int)next(buf, &pos);
        int u = (int)next(buf, &pos);
        int v = (int)next(buf, &pos);
        if (t == 0)
        {
            uf.unite(u, v);
        }
        else
        {
            out.write_byte(uf.same(u, v) ? '1' : '0')!!;
            out.write_byte('\n')!!;
        }
    }

    io::stdout().write(out.array_view())!!;
}
