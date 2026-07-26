// @title Shortest Path (Randomized Heap)
// PROBLEM: https://judge.yosupo.jp/problem/shortest_path

import c3algo::collections::randomizedheap;
import c3algo::algebra::concept;
import c3algo::io;
import std::collections::list;

const long INF =  1_000_000_000_000_000_000;
const int NONE = -1;

struct Edge
{
	int to;
	long cost;
	int next_edge;
}

struct DistVer
{
	long dist;
	int ver;
}

fn bool DistVer.less(self, DistVer other) @inline
{
	return (self.dist < other.dist) || (self.dist == other.dist && self.ver > other.ver);
}

alias Heap = randomizedheap::RandomizedHeap{DistVer, concept::Less};
alias IntList = List{int};

fn void main()
{
	FastInput inp;
	inp.init();
	defer inp.free();

	FastOutput out;
	out.init();
	defer out.free();

	sz n    = inp.read(sz);
	sz m    = inp.read(sz);
	int src = inp.read(int);
	int dst = inp.read(int);

	int[] first_edge = mem::new_array(int, n);
	long[] dist      = mem::new_array(long, n);
	int[] prev       = mem::new_array(int, n);
	foreach (&e : first_edge) *e = NONE;
	foreach (&d : dist) *d = INF;
	foreach (&p : prev) *p = NONE;

	Edge[] edges = mem::new_array(Edge, m);
	foreach (i, &edge : edges)
	{
		int from  = inp.read(int);
		int to    = inp.read(int);
		long cost = inp.read(long);
		*edge = (Edge) { .to = to, .cost = cost, .next_edge = first_edge[from] };
		first_edge[from] = (int)i;
	}

	Heap heap;
	heap.init(mem);
	defer heap.free();

	dist[src] = 0;
	heap.push((DistVer) { .dist = 0, .ver = src });
	while (!heap.is_empty())
	{
		DistVer cur = heap.pop()!!;
		if (cur.dist > dist[cur.ver]) continue;
		for (int e = first_edge[cur.ver]; e != NONE; e = edges[e].next_edge)
		{
			Edge edge    = edges[e];
			long relaxed = cur.dist + edge.cost;
			if (relaxed < dist[edge.to])
			{
				dist[edge.to] = relaxed;
				prev[edge.to] = cur.ver;
				heap.push((DistVer) { .dist = relaxed, .ver = edge.to });
			}
		}
	}

	if (dist[dst] == INF)
	{
		out.writeln(-1);
		return;
	}

	IntList path;
	path.init(mem);
	defer path.free();
	for (int v = dst; v != NONE; v = prev[v]) path.push(v);
	path.reverse();

	out.write(dist[dst]);
	out.sp();
	out.writeln(path.len() - 1);
	for (sz i = 1; i < path.len(); i++)
	{
		out.write(path[i - 1]);
		out.sp();
		out.writeln(path[i]);
	}
}