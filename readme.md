This repository implements hollow heap. 

A hollow heap is a DAG with following properties.
1. It has zero or one root.
2. A node has at most two parents.
3. A node is either hollow or full.
4. A node with two parents is hollow.
5. A node's key is not greater than its child's. 

All primitive operations are lazy. For simplicity, we assume the DAG is not empty.
```Python
def new(k, v):
    #dosomething
    return ...
def min(h):
    """Assumes normlized DAG"""
    return h.value
def link(g, h):
    unimplemented
def delete(h):
    h.value = null
```

The nontrivial part is normalization, which makes the root a full node. This is done in three steps.
1. remove hollow roots recursively by following orphans
2. for two roots with same rank, link them and bump rank
3. link remaining roots from small rank
```Python
def normalize(h):

#do something
```
Normalization condition is only violated when you delete min. 

For implementation, we order parent and children with the time of addition, giving another invariant:
1. A node with a second parent is the last child of it.

In this implementation, we use following fields
```Zig
```
