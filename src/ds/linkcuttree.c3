module c3algo::ds::linkcuttree;
import std::core::mem;

struct Node
{
	long val;
	long sum;
	Node* left;
	Node* right;
	Node* parent;
	bool rev;
}

alias LinkCutTree = Node*;

fn LinkCutTree new_node(long val)
{
	Node* n = mem::new(Node);
	n.val = val;
	n.sum = val;
	return n;
}

fn long Node.subsum(&self) @inline
{
	return self ? self.sum : 0;
}

fn void Node.pull(&self) @inline
{
	self.sum = self.left.subsum() + self.val + self.right.subsum();
}

fn void Node.push(&self) @inline
{
	if (self.rev)
	{
		self.rev = false;
		@swap(self.left, self.right);
		if (self.left) self.left.rev ^= true;
		if (self.right) self.right.rev ^= true;
	}
}

fn bool Node.is_root(&self) @inline
{
	return self.parent == null || (self.parent.left != self && self.parent.right != self);
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
		if (g.left == self)
		{
			g.left = b;
		}
		else if (g.right == self)
		{
			g.right = b;
		}
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
		if (g.left == self)
		{
			g.left = b;
		}
		else if (g.right == self)
		{
			g.right = b;
		}
	}
	self.pull();
	b.pull();
}

fn void Node.rotate_up(&self) @inline
{
	if (self.parent.left == self)
	{
		self.parent.rotate_right();
	}
	else
	{
		self.parent.rotate_left();
	}
}

fn void Node.push_down(&self)
{
	if (!self.is_root()) self.parent.push_down();
	self.push();
}

fn void Node.splay(&self)
{
	self.push_down();
	while (!self.is_root())
	{
		Node* p = self.parent;
		if (!p.is_root())
		{
			bool same = (p.left == self) == (p.parent.left == p);
			if (same)
			{
				p.rotate_up();
			}
			else
			{
				self.rotate_up();
			}
		}
		self.rotate_up();
	}
}

fn void expose(Node* v)
{
	v.splay();
	v.right = null;
	v.pull();
	while (v.parent)
	{
		Node* w = v.parent;
		w.splay();
		w.right = v;
		w.pull();
		v.splay();
	}
}

fn void evert(Node* v)
{
	expose(v);
	v.rev ^= true;
	v.push();
}

fn void link(Node* u, Node* v)
{
	evert(u);
	u.parent = v;
}

fn void cut(Node* u, Node* v)
{
	evert(u);
	expose(v);
	v.left.parent = null;
	v.left = null;
	v.pull();
}

fn Node* find_root(Node* v)
{
	expose(v);
	while (v.left)
	{
		v = v.left;
		v.push();
	}
	v.splay();
	return v;
}

fn bool connected(Node* u, Node* v)
{
	return find_root(u) == find_root(v);
}

fn void add(Node* v, long x)
{
	v.splay();
	v.val += x;
	v.pull();
}

fn long path_sum(Node* u, Node* v)
{
	evert(u);
	expose(v);
	return v.sum;
}
