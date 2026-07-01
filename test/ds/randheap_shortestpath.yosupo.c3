// @title Shortest Path (Randomized Heap)
// PROBLEM: https://judge.yosupo.jp/problem/shortest_path

import c3algo::ds::randheap;
import c3algo::algebra::concept;
import c3algo::io;

const long INF = 1_000_000_000_000_000_000;

struct Edge
{
	int to;
	long cost;
	int next;
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

alias Heap = randheap::RandHeap{DistVer, concept::Less};
alias push = randheap::push{DistVer, concept::Less};
alias pop = randheap::pop{DistVer, concept::Less};
alias is_empty = randheap::is_empty{DistVer, concept::Less};

fn void main()
{
	FastInput inp;
	inp.init();
	defer inp.free();
	FastOutput out;
	out.init();
	defer out.free();

	int n   = inp.read(int);
	int m   = inp.read(int);
	int src = inp.read(int);
	int dst = inp.read(int);

	int[] head  = mem::new_array(int, (usz)n);
	long[] dist = mem::new_array(long, (usz)n);
	int[] prev  = mem::new_array(int, (usz)n);
	for (int v = 0; v < n; v++)
	{
		head[v] = -1;
		dist[v] = INF;
		prev[v] = -1;
	}

	Edge[] edge = mem::new_array(Edge, (usz)m);
	for (int i = 0; i < m; i++)
	{
		int from  = inp.read(int);
		int to    = inp.read(int);
		long cost = inp.read(long);
		edge[i] = (Edge) { to, cost, head[from] };
		head[from] = i;
	}

	Heap heap = { };
	dist[src] = 0;
	push(&heap, (DistVer) { 0, src });
	while (!is_empty(&heap))
	{
		DistVer cur = pop(&heap);
		if (cur.dist > dist[cur.ver]) continue;
		for (int e = head[cur.ver]; e != -1; e = edge[e].next)
		{
			long nd = cur.dist + edge[e].cost;
			if (nd < dist[edge[e].to])
			{
				dist[edge[e].to] = nd;
				prev[edge[e].to] = cur.ver;
				push(&heap, (DistVer) { nd, edge[e].to });
			}
		}
	}

	if (dist[dst] == INF)
	{
		out.writeln(-1);
		return;
	}

	int[] path = mem::new_array(int, (usz)n);
	int len    = 0;
	for (int v = dst; v != -1; v = prev[v]) path[len++] = v;

	out.write(dist[dst]);
	out.sp();
	out.write(len - 1);
	out.nl();
	for (int i = len - 1; i >= 1; i--)
	{
		out.write(path[i]);
		out.sp();
		out.write(path[i - 1]);
		out.nl();
	}
}
