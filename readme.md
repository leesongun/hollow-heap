This repository implements hollow heap. 

A hollow heap organizes data in a DAG satisfying:
1. has zero or one root
2. each node has at most two parents
3. satisfies heap ordering condition
4. Each node is either hollow or data-full.

Order of parents is unimportant in theory, but for optimized implementation it matters, as it adds another invariant 
1. every node is last child in second parent, if exists.

For the sake of simplicity, we assume that the DAG is not empty from now on.
Primitive Operations are : 
```Python
fn get():
    a
```
All operations are lazy, and the only nontrivial part is normalization

```Python
fn normalize():

#do something
```

In short, it removes hollow roots by recursively following orphans, and for new roots, link two with same rank, and then finally we link them all.

In this implementation, we use following fields
```Zig
```
