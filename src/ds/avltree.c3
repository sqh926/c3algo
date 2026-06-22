module c3algo::ds::avltree;

import std::math;


struct Node
{
	sz cnt;
	int value;
	int height;
	long sm;
	Node* left;
	Node* right;
}

alias AVLTree = Node*;

fn AVLTree new_node(int value)
{
	AVLTree self = mem::new(Node);
	self.cnt = 1;
	self.value = value;
	self.height = 1;
	self.sm = value;
	return self;
}

fn sz Node.scnt(&self)
{
	return self ? self.cnt : 0;
}
fn int Node.svalue(&self)
{
	return self ? self.value : 0;
}
fn long Node.ssm(&self)
{
	return self ? self.sm : 0;
}
fn int Node.sheight(&self)
{
	return self ? self.height : 0;
}

fn void Node.pull(&self)
{
	self.cnt = self.left.scnt() + self.right.scnt() + 1;
	self.height = math::max(self.left.sheight(), self.right.sheight()) + 1;
	self.sm = self.left.ssm() + self.right.ssm() + self.value;
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
		if (self.left.diff() < 0)
		{
			self.left = self.left.rotate_left();
		}
		return self.rotate_right();
	}

	if (self.diff() < -1)
	{
		if (self.right.diff() > 0)
		{
			self.right = self.right.rotate_right();
		}
		return self.rotate_left();
	}

	self.pull();
	return self;
}

fn AVLTree insert(AVLTree node, int value)
{
	if (!node) return new_node(value);
	if (value < node.value)
	{
		node.left = insert(node.left, value);
	}
	else if (value > node.value)
	{
		node.right = insert(node.right, value);
	}
	else
	{
		return node;
	}
	return node.balance();
}

fn Node* find_min(Node* node)
{
	while (node && node.left) node = node.left;
	return node;
}

fn AVLTree delete(AVLTree node, int value)
{
	if (!node) return null;
	if (value < node.value)
	{
		node.left = delete(node.left, value);
	}
	else if (value > node.value)
	{
		node.right = delete(node.right, value);
	}
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
		node.right = delete(node.right, min_node.value);
	}
	return node.balance();
}

fn Node* find(AVLTree node, int value)
{
	while (node)
	{
		if (value == node.value)
		{
			return node;
		}
		if (value < node.value)
		{
			node = node.left;
		}
		else
		{
			node = node.right;
		}
	}
	return null;
}


fn bool contains(AVLTree node, int value) @inline
{
	return find(node, value) != null;
}


<*
 @require (node != null) : "Tree must not be empty"
*>
fn int min_key(AVLTree node)
{
	return find_min(node).value;
}

<*
 @require (node != null) : "Tree must not be empty"
*>
fn int max_key(AVLTree node)
{
	while (node && node.right) node = node.right;
	return node.value;
}


fn sz count_leq(AVLTree node, int x)
{
	sz cnt = 0;
	while (node)
	{
		if (x < node.value)
		{
			node = node.left;
		}
		else
		{
			cnt += node.left.scnt() + 1;
			node = node.right;
		}
	}
	return cnt;
}

fn int floor(AVLTree node, int x)
{
	int res = -1;
	while (node)
	{
		if (node.value <= x)
		{
			res = node.value;
			node = node.right;
		}
		else
		{
			node = node.left;
		}
	}
	return res;
}

fn int ceil(AVLTree node, int x)
{
	int res = -1;
	while (node)
	{
		if (node.value >= x)
		{
			res = node.value;
			node = node.left;
		}
		else
		{
			node = node.right;
		}
	}
	return res;
}

<*
 @require (node && k << node.scnt()) : "Tree must be not empty and kth node must exist"
*>
fn int kth(AVLTree node, sz k)
{
	sz cnt = node.left.scnt();
	if (k < cnt)
	{
		return kth(node.left, k);
	}
	if (k == cnt) return node.value;
	return kth(node.right, k - cnt - 1);
}
