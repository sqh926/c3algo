// @title Randomized Heap
<*
 @require concept::@is_comparator(Cmp, Key) : "Randomized heap requires a comparator with `before(a,b)`"
*>
module c3algo::ds::randheap <Key, Cmp>;
import c3algo::algebra::concept;

ulong rng_state @local = 0xdeadbeef;

fn ulong rand() @local
{
	ulong x = rng_state;
	x ^= x << 13;
	x ^= x >> 7;
	x ^= x << 17;
	rng_state = x;
	return x;
}


const int L = 0;
const int R = 1;
struct Node
{
	Key key;
	Node*[2] child;
}

alias RandHeap = Node*;

fn RandHeap new_node(Key key) {
	Node *self = mem::new(Node);
	self.key = key;
	return self;
}

fn RandHeap merge(RandHeap l, RandHeap r) {
	if (!l || !r) return l ? l : r;
	if (((Cmp){}).before(r.key, l.key)) @swap(l, r);
	int dir = (int)(rand() & 1);
	l.child[dir] = merge(l.child[dir], r);
	return l;	
}

fn bool is_empty(RandHeap* h) @inline => *h == null;
fn void push(RandHeap* h, Key key) => *h = merge(*h, new_node(key));
fn Key top(RandHeap* h) @inline => (*h).key;

fn RandHeap pop_hint(RandHeap h) {
	RandHeap merged = merge(h.child[L], h.child[R]);
	mem::free(h);
	return merged;
}

fn Key pop(RandHeap *h) {
	Key key = (*h).key;
	*h = pop_hint(*h);
	return key;
}
