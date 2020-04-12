import lists, tables 

type
  # no need to use ref, since DoublyLinkedNode is already a ref
  Node[K,T] = object
    key: K
    val: T

  LRUCache*[K, T] = ref object 
    capacity: int
    list: DoublyLinkedList[Node[K,T]]
    table: Table[K, DoublyLinkedNode[Node[K,T]]]

proc newLRUCache*[K,T](capacity: int): LRUCache[K,T] =
  ## Create a new Least-Recently-Used (LRU) cache that store the last `capacity`-accessed items.
  LRUCache[K,T](
    capacity: capacity,
    list: initDoublyLinkedList[Node[K,T]](),
    table: initTable[K, DoublyLinkedNode[Node[K,T]]]( rightSize(capacity) )
  )

proc resize[K,T](cache: LRUCache[K,T]) =
  while cache.len > cache.capacity:
    let t = cache.list.tail
    cache.table.del(t.value.key)
    cache.list.remove t

proc addNewNode[K,T](cache: LRUCache[K,T], key: K, val: T) =
  # create new node 
  let node = newDoublyLinkedNode[Node[K,T]](
    Node[K,T](key: key, val: val)
  )
  # put on table and prepend new node 
  cache.table[key] = node
  cache.list.prepend node
  # remove old node if exceed capacity
  cache.resize()

proc capacity*[K,T](cache: LRUCache[K,T]): int = 
  ## Get the maximum capacity of cache
  cache.capacity

proc `capacity=`*[K,T](cache: LRUCache[K,T], capacity: int) = 
  ## Resize the maximum capacity of cache
  cache.capacity = capacity
  cache.resize()

proc len*[K,T](cache: LRUCache[K,T]): int = 
  ## Return number of key in cache
  cache.table.len

proc contains*[K,T](cache: LRUCache[K,T], key: K): bool =
  ## Check whether key in cache. Does *NOT* update recentness.
  cache.table.contains(key)

proc peek*[K,T](cache: LRUCache[K,T], key: K): T =
  ## Read value by key, but *NOT* update recentness.
  ## Raise `KeyError` if `key` is not in `cache`.
  let node = cache.table[key] 
  result = node.value.val

proc del*[K,T](cache: LRUCache[K,T], key: K) =
  ## Delete key in cache. Does nothing if key is not in cache.
  let node = cache.table.getOrDefault(key, nil)
  if not node.isNil:
    cache.table.del(key)
    cache.list.remove(node)

proc clear*[K,T](cache: LRUCache[K,T]) =
  ## remove all items
  cache.list = initDoublyLinkedList[Node[K,T]]()
  cache.table.clear()

proc `[]`*[K,T](cache: LRUCache[K,T], key: K): T =
  ## Read value from `cache` by `key` and update recentness
  ## Raise `KeyError` if `key` is not in `cache`.
  let node = cache.table[key]        # may raise KeyError
  result = node.value.val
  cache.list.remove node
  cache.list.prepend node

proc `[]=`*[K,T](cache: LRUCache[K,T], key: K, val: T) =
  ## Put value `v` in cache with key `k`.
  ## Remove least recently used value from cache if length exceeds capacity.
  
  # read current node
  var node = cache.table.getOrDefault(key, nil)
  if node.isNil:
    cache.addNewNode(key, val)
  else:
    # set value 
    node.value.val = val
    # move to head
    cache.list.remove node
    cache.list.prepend node
    
proc get*[K,T](cache: LRUCache[K,T], key: K): T = 
  ## Alias of `cache[key]`
  cache[key]

proc put*[K,T](cache: LRUCache[K,T], key: K, val: T): T =
  ## Alias of `cache[key] = val`
  cache[key] = val
  
proc getOrDefault*[K,T](cache: LRUCache[K,T], key: K, val: T): T =
  ## Similar to get, but return `val` if `key` is not in `cache`
  let node = cache.table.getOrDefault(key, nil)
  if node.isNil:
    result = val
  else:
    result = node.value.val

proc getOrPut*[K,T](cache: LRUCache[K,T], key: K, val: T): T =
  ## Similar to `get`, but put and return `val` if `key` is not in `cache`
  let node = cache.table.getOrDefault(key, nil)
  if not node.isNil:
    result = node.value.val
  else:
    result = val
    cache.addNewNode(key, val)

proc isEmpty*[K,T](cache: LRUCache[K,T]): bool = 
  ## Equivalent to `cache.len == 0`
  cache.len == 0

proc isFull*[K,T](cache: LRUCache[K,T]): bool = 
  ## Equivalent to `cache.len == cache.capacity`
  cache.len == cache.capacity

