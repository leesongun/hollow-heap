# Introduction
This repository implements the lazy heap, a modification of the [hollow heap](https://arxiv.org/abs/1510.06535).
## Goals 
1. Aim for a concise, well-documented implementation.
## Non-Goals
1. Optimize for real-world performance. - Lazy heap is not intended to have good real-world performance
# Lazy Heap
A lazy heap is a DAG with following properties.
1. It has zero or one root.
2. A node has at most two parents.
3. A node is either hollow or full.
4. A node with two parents is hollow.
5. A node's key is not greater than its child's. 
## Primitive Operations
All primitive operations are lazy. We omit empty cases for simplicity.
```Python
def new(key):
    #dosomething
    return ...
def min(h):
    """Assumes normalized DAG"""
    return h.value
def link(g, h):
    unimplemented
def delete(h):
    h.value = null
```

## Normalize
Normalization makes the root a full node. It is done in three steps.
1. recursively remove hollow nodes by following orphans
2. make list of new full roots 
2. for two roots with same rank, link them and bump rank
3. link remaining roots from small rank
```Python
def normalize(h):

#do something
```
Normalization condition is only violated when you delete min. 


## Rebuild
Rebuilding removes all hollow nodes. It mitigates unboundedness of size, which is due to laziness. 
## 

# Implementation
For complete documentation, visit [here](github.com). This explains higher level differences. 
## Ordering

For implementation, we order parent and children with the time of addition, giving another invariant:
1. A node with a second parent is the last child of it.

## Fields
In this implementation, we use following fields
```Zig
```





