// @title Link-Cut Tree
<*
 @require concept::@is_monoid(Monoid)
 @require concept::@is_action(Action, Monoid)
*>
module c3algo::ds::lctree <Monoid, Action>;
import c3algo::ds::splaytree;
import c3algo::algebra::concept;

const int L = 0;
const int R = 1;

alias Node = splaytree::Node{Monoid, Action};
alias new_node = splaytree::new_node{Monoid, Action};
alias is_root = splaytree::is_root{Monoid, Action};
alias splay = splaytree::splay{Monoid, Action};
alias push = splaytree::push{Monoid, Action};
alias pull = splaytree::pull{Monoid, Action};
alias apply = splaytree::apply{Monoid, Action};

fn void push_down(Node* x)
{
	if (!is_root(x)) push_down(x.parent);
	push(x);
}

fn void splay_push(Node* x)
{
	push_down(x);
	splay(x);
}
fn void expose(Node* v)
{
	splay_push(v);
	v.child[R] = null;
	pull(v);
	while (v.parent)
	{
		Node* w = v.parent;
		splay_push(w);
		w.child[R] = v;
		pull(w);
		splay_push(v);
	}
}

fn void evert(Node* v)
{
	expose(v);
	v.rev ^= true;
	push(v);
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
	v.child[L].parent = null;
	v.child[L] = null;
	pull(v);
}

fn Node* find_root(Node* v)
{
	expose(v);
	while (v.child[L])
	{
		v = v.child[L];
		push(v);
	}
	splay(v);
	return v;
}


fn bool connected(Node* u, Node* v) => find_root(u) == find_root(v);

fn Monoid path_query(Node* u, Node* v)
{
	evert(u);
	expose(v);
	return v.agg;
}

fn void apply_path(Node* u, Node* v, Action f)
{
	evert(u);
	expose(v);
	apply(v, f);
}

fn void point_set(Node* v, Monoid m)
{
	splay_push(v);
	v.val = m;
	pull(v);
}
