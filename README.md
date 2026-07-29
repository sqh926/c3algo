# c3algo

[![Actions Status](https://github.com/sqh926/c3algo/actions/workflows/verify.yml/badge.svg)](https://github.com/sqh926/c3algo/actions)
[![GitHub Pages](https://img.shields.io/static/v1?label=GitHub+Pages&message=c3algo+&color=brightgreen&logo=github)](https://sqh926.github.io/c3algo)

Collection of algorithm and data structure implementations in C3.

Built and verified with c3c 0.8.1.

## Contents

The $+$ and the $\sum$ below stand for whatever
operation you hand the container, and every entry says what it has to satisfy.

| module                                                                       | what problem it solves                                                                                                                                                                |
|------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`c3algo::bigint`](src/bigint/bigint.c3)                                     | Arbitrary precision integers, supports $+, -, \times, \div, \%$ and $\lfloor \sqrt{n} \rfloor$. Both decimal and hexadecimal.                                                         |
| [`c3algo::collections::fenwicktree`](src/collections/fenwicktree.c3)         | $\sum_{i=0}^{r-1} a_i$ and $a_i \gets a_i + v$ in $O(\log n)$, and $\sum_{i=l}^{r-1} a_i$ as well if $+$ has an inverse. Needs $+$ to be associative and commutative.                 |
| [`c3algo::collections::segmenttree`](src/collections/segmenttree.c3)         | $\sum_{i=l}^{r-1} a_i$ and $a_i \gets v$ in $O(\log n)$. Needs $+$ associative, the order is kept so it may be non-commutative.                                                       |
| [`c3algo::collections::lazysegmenttree`](src/collections/lazysegmenttree.c3) | Everything the segment tree does, and $a_i \gets f(a_i)$ for a whole $[l, r)$ at once, in $O(\log n)$. Needs $f(x + y) = f(x) + f(y)$.                                                |
| [`c3algo::collections::splaytree`](src/collections/splaytree.c3)             | An array you can insert into and erase from at any position, plus $\sum_{i=l}^{r-1} a_i$, $f$ over a range, reversing a range and cutting the array in two, in $O(\log n)$ amortised. |
| [`c3algo::collections::treap`](src/collections/treap.c3)                     | The same array, on a randomised tree instead, in $O(\log n)$ expected.                                                                                                                |
| [`c3algo::collections::linkcuttree`](src/collections/linkcuttree.c3)         | A forest whose edges you add and remove, plus $\sum a_x$ along the path $u \to v$ and $f$ applied to that path, in $O(\log n)$ amortised.                                             |
| [`c3algo::collections::avltree`](src/collections/avltree.c3)                 | A sorted set that also answers the $k$-th smallest key, $\#\lbrace i : a_i \le x \rbrace$ and the two neighbours of $x$, in $O(\log n)$.                                              |
| [`c3algo::collections::randomizedheap`](src/collections/randomizedheap.c3)   | The smallest element of a multiset, with insert, extract and merging two heaps into one, in $O(\log n)$ expected.                                                                     |
| [`c3algo::collections::unionfind`](src/collections/unionfind.c3)             | Merging two sets into their union, finding the representative of the set holding $x$, and telling whether $x$ and $y$ are in one set, in near $O(1)$ time.                            |
| [`c3algo::collections::bitset`](src/collections/bitset.c3)                   | A mask of $n$ bits with and, or, xor and shifts.                                                                                                                                      |
| [`c3algo::convolution::fft`](src/convolution/fft.c3)                         | $c_k = \sum_{i + j = k} a_i b_j$ in $O(n \log n)$, over the integers or modulo any $m$ that fits in an int.                                                                           |
| [`c3algo::convolution::ntt`](src/convolution/ntt.c3)                         | The same sum in exact integers with no rounding, when $m$ is a prime like $998244353$.                                                                                                |
| [`c3algo::numbertheory::modint`](src/numbertheory/modint.c3)                 | A number that stays reduced modulo $m$ through $+ - \times \div$, with $m$ a compile time constant.                                                                                   |
| [`c3algo::numbertheory::primality`](src/numbertheory/primality.c3)           | Whether $n$ is prime, for every $n < 2^{64}$, with a definite answer rather than a probable one.                                                                                      |
| [`c3algo::numbertheory::factorize`](src/numbertheory/factorize.c3)           | $n = p_1 p_2 \dots p_k$, the primes with multiplicity, for $n < 2^{64}$.                                                                                                              |
| [`c3algo::io`](src/io/io.c3)                                                 | Buffered I/O. Shouldn't be used in any advanced applications!!!                                                                                                                       |

## Using an algorithm from this repository

You don't need to copy the whole library, 
in most case scenarios you'd only need one algorithm from this whole repository.


Go to [the documentation pages](https://sqh926.github.io/c3algo), open the
algorithm you need, and copy the **bundled + minified** source code into your project, 
or just **bundled** one if you would rather keep a readable version.
It carries every module it depends on, so it compiles on its own.

Every page offers the same code in three variants:

| variant            | what it is                                           |
|--------------------|------------------------------------------------------|
| source             | the file as it is in `src/`, with contracts and docs |
| bundled            | that file plus every module it imports, in one file  |
| bundled + minified | spaces and everything unused stripped out            |


Every module starts with a header listing what it needs from user, its whole
public API and a short example, so reading the top of a file should be enough.


## Tests

Every algorithm and data structure is verified against a [Library Checker](https://judge.yosupo.jp)
problem.

## Contributing

Bug reports and suggestions are welcome, but pull requests are not accepted.