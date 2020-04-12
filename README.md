# LRU cache

The standard implemenation of LRU cache (hash table + doubly-linked list). 
All operations are in time complexity of O(1).
This implementation is *not* thread-safe.

## Usage

```
# create a new LRU cache with initial capacity of 1 items
let cache = newLRUCache[int, string](1) 

cache[1] = "a"
cache[2] = "b"

# key 1 is not in cache, because key 1 is eldest and capacity is only 1
assert: 1 notin cache 
assert: 2 in cache

# increase capacity and add key 1 
cache.capacity = 2 
cache[1] = "a"
assert: 1 in cache
assert: 2 in cache

# update recentness of key 2 and add key 3, then key 1 will be discarded.
echo cache[2]
cache[3] = "c"
assert: 1 notin cache
assert: 2 in cache
assert: 3 in cache
```
