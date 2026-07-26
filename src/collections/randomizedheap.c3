// @title Randomized Heap
<*
 Meldable priority queue. Source:
 https://cp-algorithms.com/data_structures/randomized_heap.html

 @require concept::@is_comparator(Cmp, Key) : "Randomized heap requires a comparator with `before(a,b)`"
*>
module c3algo::collections::randomizedheap <Key, Cmp>;

import c3algo::algebra::concept;
import c3algo::random;

const int L = 0;
const int R = 1;

struct Node
{
	Key key;
	Node*[2] child;
}

struct RandomizedHeap
{
	Allocator allocator;
	Node* root;
	sz size;
}

<*
 Initialize an empty heap.

 @param [&inout] allocator : "The allocator nodes are taken from"

 @require !self.is_initialized() : "The RandomizedHeap must not be initialized"

 @ensure self.root == null, self.size == 0
*>
fn RandomizedHeap* RandomizedHeap.init(&self, Allocator allocator)
{
	self.allocator = allocator;
	self.root = null;
	self.size = 0;
	return self;
}

<*
 Initialize an empty heap with the temp allocator.

 @require !self.is_initialized() : "The RandomizedHeap must not be initialized"

 @ensure self.root == null, self.size == 0
*>
fn RandomizedHeap* RandomizedHeap.tinit(&self) => self.init(tmem) @inline;

<*
 Free every node and leave the heap uninitialized.

 @ensure !self.is_initialized()
*>
fn void RandomizedHeap.free(&self)
{
	if (!self.is_initialized()) return;
	self.clear();
	*self = { };
}

<*
 Free every node, but keep head initialized.

 @require self.is_initialized() : "The RandomizedHeap must be initialized"

 @ensure self.root == null, self.size == 0
*>
fn void RandomizedHeap.clear(&self)
{
	free_nodes(self.allocator, self.root);
	self.root = null;
	self.size = 0;
}

<*
 @return "`true` if the heap has an allocator"
*>
fn bool RandomizedHeap.is_initialized(&self) @inline => self.allocator != null;

<*
 @return "The number of elements"
*>
fn sz RandomizedHeap.len(&self) @inline => self.size;

<*
 @return "`true` if the heap holds no elements"
*>
fn bool RandomizedHeap.is_empty(&self) @inline => self.root == null;

<*
 Insert an element.

 @param key : "The element to insert"

 @require self.is_initialized() : "The RandomizedHeap must be initialized"

 @ensure self.size > 0
*>
fn void RandomizedHeap.push(&self, Key key)
{
	Node* node = alloc::new(self.allocator, Node);
	node.key = key;
	self.root = merge_nodes(self.root, node);
	self.size++;
}

<*
 @return "The element the comparator puts first, the element is left in the heap"
 @return? NO_MORE_ELEMENT
*>
fn Key? RandomizedHeap.top(&self)
{
	if (!self.root) return NO_MORE_ELEMENT~;
	return self.root.key;
}

<*
 Remove the element the comparator puts first.

 @return "The removed element"
 @return? NO_MORE_ELEMENT
*>
fn Key? RandomizedHeap.pop(&self)
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
 Move every element of `other` into this heap, absorbing it in the process.

 @param [&inout] other : "The heap to absorb"

 @require self.is_initialized() && other.is_initialized() : "Both heaps must be initialized"
 @require self.allocator == other.allocator : "Both heaps must share an allocator"
 @require self != other : "A heap may not be merged into itself"
*>
fn void RandomizedHeap.merge(&self, RandomizedHeap* other)
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