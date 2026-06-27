// @title Union-Find
module c3algo::ds::unionfind;

struct UnionFind
{
	int[] parent;
	int[] rank;
}

fn void UnionFind.init(&self, sz n)
{
	self.parent = mem::new_array(int, n);
	self.rank = mem::new_array(int, n);
	for (sz i = 0; i < n; i++) self.parent[i] = (int)i;
}

fn void UnionFind.free(&self)
{
	mem::free(self.parent.ptr);
	mem::free(self.rank.ptr);
}

fn int UnionFind.find(&self, int x)
{
	while (self.parent[x] != x)
	{
		self.parent[x] = self.parent[self.parent[x]];
		x = self.parent[x];
	}
	return x;
}

fn bool UnionFind.unite(&self, int a, int b)
{
	int ra = self.find(a);
	int rb = self.find(b);
	if (ra == rb) return false;
	if (self.rank[ra] < self.rank[rb])
	{
		@swap(ra, rb);
	}
	self.parent[rb] = ra;
	if (self.rank[ra] == self.rank[rb]) self.rank[ra]++;
	return true;
}

fn bool UnionFind.same(&self, int a, int b)
{
	return self.find(a) == self.find(b);
}
