module c3algo::ds::splaytree;
import std::core::mem;

struct Node
{
	int key;
	sz cnt;
	Node* parent;
	Node* left;
	Node* right;
}

alias SplayTree = Node*;

fn SplayTree new_node(int key)
{
	Node* n = mem::new(Node);
	n.key = key;
	n.cnt = 1;
	return n;
}

fn sz Node.size(&self) @inline
{
	return self ? self.cnt : 0;
}

fn void Node.pull(&self) @inline
{
	self.cnt = self.left.size() + self.right.size() + 1;
}

fn void Node.rotate_right(&self)
{
	Node* b = self.left;
	Node* g = self.parent;
	self.left = b.right;
	if (b.right) b.right.parent = self;
	b.right = self;
	self.parent = b;
	b.parent = g;
	if (g)
	{
		if (g.left == self) { g.left = b; } else { g.right = b; }
	}
	self.pull();
	b.pull();
}

fn void Node.rotate_left(&self)
{
	Node* b = self.right;
	Node* g = self.parent;
	self.right = b.left;
	if (b.left) b.left.parent = self;
	b.left = self;
	self.parent = b;
	b.parent = g;
	if (g)
	{
		if (g.left == self) { g.left = b; } else { g.right = b; }
	}
	self.pull();
	b.pull();
}

fn void Node.rotate_up(&self) @inline
{
	if (self.parent.left == self) { self.parent.rotate_right(); }
	else { self.parent.rotate_left(); }
}

fn void Node.splay(&self)
{
	while (self.parent)
	{
		Node* p = self.parent;
		if (p.parent)
		{
			bool same = (p.left == self) == (p.parent.left == p);
			if (same) { p.rotate_up(); }
			else { self.rotate_up(); }
		}
		self.rotate_up();
	}
}

fn void splay_nearest(SplayTree* t, int key) @local
{
	Node* cur = *t;
	if (!cur) return;
	while (cur.key != key)
	{
		Node* nxt = key < cur.key ? cur.left : cur.right;
		if (!nxt) break;
		cur = nxt;
	}
	cur.splay();
	*t = cur;
}

fn bool contains(SplayTree* t, int key)
{
	splay_nearest(t, key);
	return *t != null && (*t).key == key;
}

fn void insert(SplayTree* t, int key)
{
	if (!*t) { *t = new_node(key); return; }
	splay_nearest(t, key);
	Node* r = *t;
	if (r.key == key) return;
	Node* n = new_node(key);
	if (key < r.key)
	{
		n.left = r.left;
		if (r.left) r.left.parent = n;
		r.left = null;
		n.right = r;
	}
	else
	{
		n.right = r.right;
		if (r.right) r.right.parent = n;
		r.right = null;
		n.left = r;
	}
	r.parent = n;
	r.pull();
	n.pull();
	*t = n;
}

fn void erase(SplayTree* t, int key)
{
	splay_nearest(t, key);
	Node* r = *t;
	if (!r || r.key != key) return;
	Node* l = r.left;
	Node* rr = r.right;
	if (l) l.parent = null;
	if (rr) rr.parent = null;
	mem::free(r);
	if (!l) { *t = rr; return; }
	Node* m = l;
	while (m.right) m = m.right;
	m.splay();
	m.right = rr;
	if (rr) rr.parent = m;
	m.pull();
	*t = m;
}

<*
 @require (k < (*t).size()) : "kth: index out of range"
*>
fn int kth(SplayTree* t, sz k)
{
	Node* cur = *t;
	while (true)
	{
		sz ls = cur.left.size();
		if (k == ls) break;
		if (k < ls) { cur = cur.left; }
		else { k -= ls + 1; cur = cur.right; }
	}
	cur.splay();
	*t = cur;
	return cur.key;
}

fn sz count_leq(SplayTree* t, int x)
{
	splay_nearest(t, x);
	Node* r = *t;
	if (!r) return 0;
	return r.key <= x ? r.left.size() + 1 : r.left.size();
}

fn int floor(SplayTree* t, int x)
{
	splay_nearest(t, x);
	Node* r = *t;
	if (!r) return -1;
	if (r.key <= x) return r.key;
	Node* p = r.left;
	if (!p) return -1;
	while (p.right) p = p.right;
	return p.key;
}

fn int ceil(SplayTree* t, int x)
{
	splay_nearest(t, x);
	Node* r = *t;
	if (!r) return -1;
	if (r.key >= x) return r.key;
	Node* s = r.right;
	if (!s) return -1;
	while (s.left) s = s.left;
	return s.key;
}
