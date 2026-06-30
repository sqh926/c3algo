// @title AVL Tree
<*
 @require concept::@is_ordered(Key) : "AVL Tree requires Key to support <"
*>
module c3algo::ds::avltree <Key>;
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
alias AVLTree = Node*;

fn AVLTree new_node(Key key)
{
	Node* n = mem::new(Node);
	n.key = key;
	n.size = 1;
	n.height = 1;
	return n;
}

fn sz safe_size(AVLTree t) @inline => t ? t.size : 0;
fn int safe_height(AVLTree t) @inline => t ? t.height : 0;
fn int diff(AVLTree t) @inline => safe_height(t.child[L]) - safe_height(t.child[R]);

fn void pull(AVLTree t) @inline
{
	t.size = 1 + safe_size(t.child[L]) + safe_size(t.child[R]);
	t.height = 1 + math::max(safe_height(t.child[L]), safe_height(t.child[R]));
}

fn void rotate(AVLTree* t, int dir)
{
	int opp    = dir ^ 1;
	Node* node = *t;
	Node* x    = node.child[opp];
	node.child[opp] = x.child[dir];
	x.child[dir] = node;
	pull(node);
	pull(x);
	*t = x;
}

fn AVLTree balance(AVLTree t)
{
	pull(t);
	int bf = diff(t);
	if (bf > 1)
	{
		if (diff(t.child[L]) < 0) rotate(&t.child[L], L);
		rotate(&t, R);
	}
	else if (bf < -1)
	{
		if (diff(t.child[R]) > 0) rotate(&t.child[R], R);
		rotate(&t, L);
	}
	return t;
}

fn AVLTree insert_node(AVLTree t, Key key)
{
	if (!t) return new_node(key);
	if (key < t.key)
	{
		t.child[L] = insert_node(t.child[L], key);
	}
	else if (t.key < key)
	{
		t.child[R] = insert_node(t.child[R], key);
	}
	else
	{
		return t;
	}
	return balance(t);
}

fn AVLTree find_min(AVLTree t)
{
	while (t.child[L]) t = t.child[L];
	return t;
}

fn AVLTree delete_node(AVLTree t, Key key)
{
	if (!t) return null;
	if (key < t.key)
	{
		t.child[L] = delete_node(t.child[L], key);
	}
	else if (t.key < key)
	{
		t.child[R] = delete_node(t.child[R], key);
	}
	else
	{
		if (!t.child[L])
		{
			Node* r = t.child[R];
			mem::free(t);
			return r;
		}
		if (!t.child[R])
		{
			Node* l = t.child[L];
			mem::free(t);
			return l;
		}
		Node* succ = find_min(t.child[R]);
		t.key = succ.key;
		t.child[R] = delete_node(t.child[R], succ.key);
	}
	return balance(t);
}

fn sz size(AVLTree* t) @inline => safe_size(*t);

fn void insert(AVLTree* t, Key key) => *t = insert_node(*t, key);

fn void erase(AVLTree* t, Key key) => *t = delete_node(*t, key);

fn bool contains(AVLTree* t, Key key)
{
	AVLTree node = *t;
	while (node)
	{
		if (key < node.key)
		{
			node = node.child[L];
		}
		else if (node.key < key)
		{
			node = node.child[R];
		}
		else
		{
			return true;
		}
	}
	return false;
}

<*
 @require k < safe_size(*t) : "kth: index out of range"
*>
fn Key kth(AVLTree* t, sz k)
{
	AVLTree node = *t;
	while (true)
	{
		sz ls = safe_size(node.child[L]);
		if (k == ls) return node.key;
		if (k < ls)
		{
			node = node.child[L];
		}
		else
		{
			k -= ls + 1;
			node = node.child[R];
		}
	}
}

fn sz count_leq(AVLTree* t, Key x)
{
	AVLTree node = *t;
	sz cnt       = 0;
	while (node)
	{
		if (x < node.key)
		{
			node = node.child[L];
		}
		else
		{
			cnt += safe_size(node.child[L]) + 1;
			node = node.child[R];
		}
	}
	return cnt;
}

fn Key? floor(AVLTree* t, Key x)
{
	AVLTree node = *t;
	Key? res     = NOT_FOUND~;
	while (node)
	{
		if (x < node.key)
		{
			node = node.child[L];
		}
		else
		{
			res = node.key;
			node = node.child[R];
		}
	}
	return res;
}

fn Key? ceil(AVLTree* t, Key x)
{
	AVLTree node = *t;
	Key? res     = NOT_FOUND~;
	while (node)
	{
		if (node.key < x)
		{
			node = node.child[R];
		}
		else
		{
			res = node.key;
			node = node.child[L];
		}
	}
	return res;
}
