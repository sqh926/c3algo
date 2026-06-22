// PROBLEM: https://judge.yosupo.jp/problem/many_aplusb_128bit

import c3algo::io;

fn void main()
{
    FastInput in; in.init();    defer in.free();
    FastOutput out; out.init(); defer out.free();

    int t = in.read(int);
    while (t-- > 0)
    {
        int128 a = in.read(int128);
        int128 b = in.read(int128);
        out.write(a + b);
        out.nl();
    }
}
