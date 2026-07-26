// @title Union-Find
module c3algo::collections::unionfind;

struct UnionFind
{
	Allocator allocator;
	int[] parent;
	int[] rank;
	sz components;
}

<*
 Initialize a disjoint set union.

 @param [&inout] allocator : "The allocator to use"
 @param n : "The number of elements"

 @require !self.is_initialized() : "The UnionFind must not be initialized"
 @require n >= 0 : "The number of elements may not be negative"
 @require n <= int::max : "The number of elements must fit in an int"

 @ensure self.len() == n, self.components == n
*>
fn UnionFind* UnionFind.init(&self, Allocator allocator, sz n)
{
	self.allocator = allocator;
	self.parent = alloc::alloc_array(allocator, int, n);
	self.rank = alloc::new_array(allocator, int, n);
	self.components = n;
	// parent[i] = i
	foreach (i, &p : self.parent)
	{
		*p = (int)i;
	}
	return self;
}

<*
 Initialize a disjoint set union using temp allocator.

 @param n : "The number of elements"

 @require !self.is_initialized() : "The UnionFind must not be initialized"
 @require n >= 0 : "The number of elements may not be negative"
 @require n <= int::max : "The number of elements must fit in an int"

 @ensure self.len() == n, self.components == n
*>
fn UnionFind* UnionFind.tinit(&self, sz n) @inline => self.init(tmem, n);

<*
 Release the memory held by the UnionFind.

 @ensure !self.is_initialized()
*>
fn void UnionFind.free(&self)
{
	if (!self.is_initialized()) return;
	alloc::free(self.allocator, self.parent.ptr);
	alloc::free(self.allocator, self.rank.ptr);
	*self = { };
}

<*
 @return "`true` if the UnionFind has an allocator"
*>
fn bool UnionFind.is_initialized(&self) @inline => self.allocator != null;

<*
 @return "The number of elements"
*>
fn sz UnionFind.len(&self) @inline => (sz)self.parent.len;

<*
 @return "The number of components"

 @ensure return >= 0, return <= self.len()
*>
fn sz UnionFind.count(&self) @inline => self.components;

<*
 Find the representative of the component holding `x`.

 @param x : "The element to look up"
 @return "The representative of the component holding `x`"

 @require x >= 0 && x < self.len() : "Index out of range"

 @ensure return >= 0 && return < self.len()
*>
fn sz UnionFind.find(&self, sz x)
{
	int i = (int)x;
	while (self.parent[i] != i)
	{
		self.parent[i] = self.parent[self.parent[i]];
		i = self.parent[i];
	}
	return i;
}

<*
 Merge the components holding `a` and `b`.

 @param a : "An element of the first component"
 @param b : "An element of the second component"
 @return "`true` if the components were distinct and got merged"

 @require a >= 0 && a < self.len() : "Index out of range"
 @require b >= 0 && b < self.len() : "Index out of range"
*>
fn bool UnionFind.unite(&self, sz a, sz b)
{
	int ra = (int)self.find(a);
	int rb = (int)self.find(b);
	if (ra == rb) return false;
	if (self.rank[ra] < self.rank[rb])
	{
		@swap(ra, rb);
	}
	self.parent[rb] = ra;
	if (self.rank[ra] == self.rank[rb]) self.rank[ra]++;
	self.components--;
	return true;
}

<*
 @param a : "An element of the first component"
 @param b : "An element of the second component"
 @return "`true` if `a` and `b` belong to the same component"

 @require a >= 0 && a < self.len() : "Index out of range"
 @require b >= 0 && b < self.len() : "Index out of range"
*>
fn bool UnionFind.same(&self, sz a, sz b) @inline => self.find(a) == self.find(b);