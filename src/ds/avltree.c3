module c3algo::ds::avltree;
import std::core::mem;
import std::math;

struct Node
{
	int value;
	int height;
	sz cnt;
	Node* left;
	Node* right;
}

alias AVLTree = Node*;

fn AVLTree new_node(int value)
{
	AVLTree self = mem::new(Node);
	self.value = value;
	self.height = 1;
	self.cnt = 1;
	return self;
}

fn sz Node.size(&self) @inline
{
	return self ? self.cnt : 0;
}

fn int Node.sheight(&self) @inline
{
	return self ? self.height : 0;
}

fn void Node.pull(&self) @inline
{
	self.cnt = self.left.size() + self.right.size() + 1;
	self.height = math::max(self.left.sheight(), self.right.sheight()) + 1;
}

fn int Node.diff(&self) @inline
{
	return self.left.sheight() - self.right.sheight();
}

fn Node* Node.rotate_left(&self)
{
	Node* b = self.right;
	self.right = b.left;
	b.left = self;
	self.pull();
	b.pull();
	return b;
}

fn Node* Node.rotate_right(&self)
{
	Node* b = self.left;
	self.left = b.right;
	b.right = self;
	self.pull();
	b.pull();
	return b;
}

fn Node* Node.balance(&self)
{
	if (!self) return null;
	if (self.diff() > 1)
	{
		if (self.left.diff() < 0) { self.left = self.left.rotate_left(); }
		return self.rotate_right();
	}
	if (self.diff() < -1)
	{
		if (self.right.diff() > 0) { self.right = self.right.rotate_right(); }
		return self.rotate_left();
	}
	self.pull();
	return self;
}

fn AVLTree insert_node(AVLTree node, int value) @local
{
	if (!node) return new_node(value);
	if (value < node.value) { node.left = insert_node(node.left, value); }
	else if (value > node.value) { node.right = insert_node(node.right, value); }
	else { return node; }
	return node.balance();
}

fn Node* find_min(Node* node) @local
{
	while (node && node.left) node = node.left;
	return node;
}

fn AVLTree delete_node(AVLTree node, int value) @local
{
	if (!node) return null;
	if (value < node.value) { node.left = delete_node(node.left, value); }
	else if (value > node.value) { node.right = delete_node(node.right, value); }
	else
	{
		if (!node.left)
		{
			Node* right = node.right;
			mem::free(node);
			return right;
		}
		if (!node.right)
		{
			Node* left = node.left;
			mem::free(node);
			return left;
		}
		Node* min_node = find_min(node.right);
		node.value = min_node.value;
		node.right = delete_node(node.right, min_node.value);
	}
	return node.balance();
}

fn void insert(AVLTree* t, int value)
{
	*t = insert_node(*t, value);
}

fn void erase(AVLTree* t, int value)
{
	*t = delete_node(*t, value);
}

fn bool contains(AVLTree* t, int value)
{
	Node* node = *t;
	while (node)
	{
		if (value == node.value) return true;
		node = value < node.value ? node.left : node.right;
	}
	return false;
}

<*
 @require (k < (*t).size()) : "kth: index out of range"
*>
fn int kth(AVLTree* t, sz k)
{
	Node* node = *t;
	while (true)
	{
		sz cnt = node.left.size();
		if (k == cnt) return node.value;
		if (k < cnt) { node = node.left; }
		else { k -= cnt + 1; node = node.right; }
	}
}

fn sz count_leq(AVLTree* t, int x)
{
	Node* node = *t;
	sz cnt = 0;
	while (node)
	{
		if (x < node.value) { node = node.left; }
		else { cnt += node.left.size() + 1; node = node.right; }
	}
	return cnt;
}

fn int floor(AVLTree* t, int x)
{
	Node* node = *t;
	int res = -1;
	while (node)
	{
		if (node.value <= x) { res = node.value; node = node.right; }
		else { node = node.left; }
	}
	return res;
}

fn int ceil(AVLTree* t, int x)
{
	Node* node = *t;
	int res = -1;
	while (node)
	{
		if (node.value >= x) { res = node.value; node = node.left; }
		else { node = node.right; }
	}
	return res;
}
