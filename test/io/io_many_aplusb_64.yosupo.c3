// PROBLEM: https://judge.yosupo.jp/problem/many_aplusb

import c3algo::io;

fn void main()
{
    FastInput in; in.init();    defer in.free();
    FastOutput out; out.init(); defer out.free();

    int t = in.read(int);
    while (t-- > 0)
    {
        ulong a = in.read(ulong);
        ulong b = in.read(ulong);
        out.write(a + b);
        out.nl();
    }
}
