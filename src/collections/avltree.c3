// @title AVL Tree
<*
 A variant of self-balancing binary search tree.
 https://en.wikipedia.org/wiki/AVL_tree

 @require concept::@is_ordered(Key) : "AVL Tree requires Key to support <"
*>
module c3algo::collections::avltree <Key>;

import c3algo::algebra::concept;
import std::math;

const int L = 0;
const int R = 1;

struct Node
{
	Key key;
	sz size;
	int height;
	Node*[2] child;
}

struct AVLTree
{
	Allocator allocator;
	Node* root;
}

<*
 Initialize an empty tree.

 @param [&inout] allocator : "The allocator for nodes"

 @require !self.is_initialized() : "The AVLTree must not be initialized"

 @ensure self.root == null
*>
fn AVLTree* AVLTree.init(&self, Allocator allocator)
{
	self.allocator = allocator;
	self.root = null;
	return self;
}

<*
 Initialize an empty tree with the temp allocator.

 @require !self.is_initialized() : "The AVLTree must not be initialized"

 @ensure self.root == null
*>
fn AVLTree* AVLTree.tinit(&self) @inline => self.init(tmem);

<*
 Free every node and leave the tree uninitialized.

 @ensure !self.is_initialized()
*>
fn void AVLTree.free(&self)
{
	if (!self.is_initialized()) return;
	self.clear();
	*self = { };
}

<*
 Free every node, keeping the tree initialized.

 @require self.is_initialized() : "The AVLTree must be initialized"

 @ensure self.root == null
*>
fn void AVLTree.clear(&self)
{
	free_nodes(self.allocator, self.root);
	self.root = null;
}

<*
 @return "`true` if the tree has an allocator"
*>
fn bool AVLTree.is_initialized(&self) @inline => self.allocator != null;

<*
 @return "The number of keys"
*>
fn sz AVLTree.len(&self) @inline => safe_size(self.root);

<*
 @return "`true` if the tree holds no keys"
*>
fn bool AVLTree.is_empty(&self) @inline => self.root == null;

<*
 Insert a key, doing nothing if it is already present.

 @param key : "The key to insert"

 @return "`true` if the key was not present before"

 @require self.is_initialized() : "The AVLTree must be initialized"
*>
fn bool AVLTree.insert(&self, Key key)
{
	sz before = safe_size(self.root);
	self.root = insert_node(self.allocator, self.root, key);
	return self.root.size != before;
}

<*
 Remove a key, doing nothing if it is absent.

 @param key : "The key to remove"

 @return "`true` if the key was present"

 @require self.is_initialized() : "The AVLTree must be initialized"
*>
fn bool AVLTree.erase(&self, Key key)
{
	sz before = safe_size(self.root);
	self.root = delete_node(self.allocator, self.root, key);
	return safe_size(self.root) != before;
}

<*
 @param key : "The key to look for"

 @return "`true` if the key is present"
*>
fn bool AVLTree.contains(&self, Key key)
{
	Node* node = self.root;
	while (node)
	{
		if (key < node.key)
		{
			node = node.child[L];
			continue;
		}
		if (node.key < key)
		{
			node = node.child[R];
			continue;
		}
		return true;
	}
	return false;
}

<*
 @param k : "The rank to look up, counting from zero"

 @return "The `k`-th smallest key"

 @require k >= 0 && k < self.len() : "Index out of range"
*>
fn Key AVLTree.kth(&self, sz k)
{
	Node* node = self.root;
	while (true)
	{
		sz ls = safe_size(node.child[L]);
		if (k == ls) return node.key;
		if (k < ls)
		{
			node = node.child[L];
			continue;
		}
		k -= ls + 1;
		node = node.child[R];
	}
}

<*
 @param x : "The key to compare against"

 @return "The number of keys not greater than `x`"
*>
fn sz AVLTree.count_leq(&self, Key x)
{
	Node* node = self.root;
	sz count   = 0;
	while (node)
	{
		if (x < node.key)
		{
			node = node.child[L];
			continue;
		}
		count += safe_size(node.child[L]) + 1;
		node = node.child[R];
	}
	return count;
}

<*
 @param x : "The key to compare against"

 @return "The greatest key not greater than `x`"
 @return? NOT_FOUND
*>
fn Key? AVLTree.floor(&self, Key x)
{
	Node* node = self.root;
	Key? res   = NOT_FOUND~;
	while (node)
	{
		if (x < node.key)
		{
			node = node.child[L];
			continue;
		}
		res = node.key;
		node = node.child[R];
	}
	return res;
}

<*
 @param x : "The key to compare against"

 @return "The smallest key not less than `x`"
 @return? NOT_FOUND
*>
fn Key? AVLTree.ceil(&self, Key x)
{
	Node* node = self.root;
	Key? res   = NOT_FOUND~;
	while (node)
	{
		if (node.key < x)
		{
			node = node.child[R];
			continue;
		}
		res = node.key;
		node = node.child[L];
	}
	return res;
}

fn Node* new_node(Allocator allocator, Key key) @local
{
	Node* node = alloc::new(allocator, Node);
	node.key = key;
	node.size = 1;
	node.height = 1;
	return node;
}

fn sz safe_size(Node* node) @local @inline => node ? node.size : 0;

fn int safe_height(Node* node) @local @inline => node ? node.height : 0;

fn int diff(Node* node) @local @inline => safe_height(node.child[L]) - safe_height(node.child[R]);

fn void pull(Node* node) @local @inline
{
	node.size = 1 + safe_size(node.child[L]) + safe_size(node.child[R]);
	node.height = 1 + math::max(safe_height(node.child[L]), safe_height(node.child[R]));
}

fn void rotate(Node** slot, int dir) @local
{
	int opp    = dir ^ 1;
	Node* node = *slot;
	Node* top  = node.child[opp];
	node.child[opp] = top.child[dir];
	top.child[dir] = node;
	pull(node);
	pull(top);
	*slot = top;
}

fn Node* balance(Node* node) @local
{
	pull(node);
	int bf = diff(node);
	if (bf > 1)
	{
		if (diff(node.child[L]) < 0) rotate(&node.child[L], L);
		rotate(&node, R);
	}
	else if (bf < -1)
	{
		if (diff(node.child[R]) > 0) rotate(&node.child[R], R);
		rotate(&node, L);
	}
	return node;
}

fn Node* insert_node(Allocator allocator, Node* node, Key key) @local
{
	if (!node) return new_node(allocator, key);
	if (key < node.key)
	{
		node.child[L] = insert_node(allocator, node.child[L], key);
	}
	else if (node.key < key)
	{
		node.child[R] = insert_node(allocator, node.child[R], key);
	}
	else
	{
		return node;
	}
	return balance(node);
}

fn Node* find_min(Node* node) @local
{
	while (node.child[L]) node = node.child[L];
	return node;
}

fn Node* delete_node(Allocator allocator, Node* node, Key key) @local
{
	if (!node) return null;
	if (key < node.key)
	{
		node.child[L] = delete_node(allocator, node.child[L], key);
	}
	else if (node.key < key)
	{
		node.child[R] = delete_node(allocator, node.child[R], key);
	}
	else
	{
		if (!node.child[L] || !node.child[R])
		{
			Node* rest = node.child[L] ? node.child[L] : node.child[R];
			alloc::free(allocator, node);
			return rest;
		}
		Node* succ = find_min(node.child[R]);
		node.key = succ.key;
		node.child[R] = delete_node(allocator, node.child[R], succ.key);
	}
	return balance(node);
}

fn void free_nodes(Allocator allocator, Node* node) @local
{
	if (!node) return;
	free_nodes(allocator, node.child[L]);
	free_nodes(allocator, node.child[R]);
	alloc::free(allocator, node);
}