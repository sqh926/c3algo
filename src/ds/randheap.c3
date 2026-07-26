// @title Randomized Heap
<*
 Meldable priority queue. Source:
 https://cp-algorithms.com/data_structures/randomized_heap.html

 @require concept::@is_comparator(Cmp, Key) : "Randomized heap requires a comparator with `before(a,b)`"
*>
module c3algo::ds::randheap <Key, Cmp>;

import c3algo::algebra::concept;
import c3algo::random;

const int L = 0;
const int R = 1;

struct Node
{
	Key key;
	Node*[2] child;
}

struct RandHeap
{
	Allocator allocator;
	Node* root;
	sz size;
}

<*
 Initialize an empty heap.

 @param [&inout] allocator : "The allocator nodes are taken from"

 @require !self.is_initialized() : "The RandHeap must not be initialized"

 @ensure self.root == null, self.size == 0
*>
fn RandHeap* RandHeap.init(&self, Allocator allocator)
{
	self.allocator = allocator;
	self.root = null;
	self.size = 0;
	return self;
}

<*
 Initialize an empty heap taking nodes from the temp allocator.

 @require !self.is_initialized() : "The RandHeap must not be initialized"

 @ensure self.root == null, self.size == 0
*>
fn RandHeap* RandHeap.tinit(&self) => self.init(tmem) @inline;

<*
 Free every node and leave the heap uninitialized.

 @ensure !self.is_initialized()
*>
fn void RandHeap.free(&self)
{
	if (!self.is_initialized()) return;
	self.clear();
	*self = { };
}

<*
 Free every node, keeping the heap ready for reuse.

 @require self.is_initialized() : "The RandHeap must be initialized"

 @ensure self.root == null, self.size == 0
*>
fn void RandHeap.clear(&self)
{
	free_nodes(self.allocator, self.root);
	self.root = null;
	self.size = 0;
}

<*
 @return "True if the heap has an allocator to take nodes from"
*>
fn bool RandHeap.is_initialized(&self) @inline => self.allocator != null;

<*
 @return "The number of elements"
*>
fn sz RandHeap.len(&self) @inline => self.size;

<*
 @return "True if the heap holds no elements"
*>
fn bool RandHeap.is_empty(&self) @inline => self.root == null;

<*
 Insert an element.

 @param key : "The element to insert"

 @require self.is_initialized() : "The RandHeap must be initialized"

 @ensure self.size > 0
*>
fn void RandHeap.push(&self, Key key)
{
	Node* node = alloc::new(self.allocator, Node);
	node.key = key;
	self.root = merge_nodes(self.root, node);
	self.size++;
}

<*
 @return "The element the comparator puts first, left in the heap"
 @return? NO_MORE_ELEMENT
*>
fn Key? RandHeap.top(&self)
{
	if (!self.root) return NO_MORE_ELEMENT~;
	return self.root.key;
}

<*
 Remove the element the comparator puts first.

 @return "The removed element"
 @return? NO_MORE_ELEMENT
*>
fn Key? RandHeap.pop(&self)
{
	Node* node = self.root;
	if (!node) return NO_MORE_ELEMENT~;
	Key key = node.key;
	self.root = merge_nodes(node.child[L], node.child[R]);
	alloc::free(self.allocator, node);
	self.size--;
	return key;
}

<*
 Move every element of `other` into this heap, absorbing it in process.

 @param [&inout] other : "The heap to absorb"

 @require self.is_initialized() && other.is_initialized() : "Both heaps must be initialized"
 @require self.allocator == other.allocator : "Both heaps must share an allocator"
 @require self != other : "A heap may not be merged into itself"
*>
fn void RandHeap.merge(&self, RandHeap* other)
{
	self.root = merge_nodes(self.root, other.root);
	self.size += other.size;
	other.root = null;
	other.size = 0;
}

fn Node* merge_nodes(Node* l, Node* r) @local
{
	if (!l || !r) return l ? l : r;
	if (((Cmp) { }).before(r.key, l.key)) @swap(l, r);
	int dir = (int)(random::next() & 1);
	l.child[dir] = merge_nodes(l.child[dir], r);
	return l;
}

fn void free_nodes(Allocator allocator, Node* node) @local
{
	if (!node) return;
	free_nodes(allocator, node.child[L]);
	free_nodes(allocator, node.child[R]);
	alloc::free(allocator, node);
}