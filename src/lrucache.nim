import lists, tables, options

type
  LruCacheError* = object of CatchableError

  EmptyLruCacheError* = object of LruCacheError

  # no need to use ref, since DoublyLinkedNode is already a ref
  Node[K,T] = object
    key: K
    val: T

  LruCache*[K, T] = ref object 
    capacity: int
    list: DoublyLinkedList[Node[K,T]]
    table: Table[K, DoublyLinkedNode[Node[K,T]]]


template rightSize(cap): untyped {.dirty.}=
  # for backward compatability
  when declared(tables.rightSize) and (NimMajor,NimMinor) < (1,4):
    tables.rightSize(cap)
  else:
    cap

proc newLruCache*[K,T](capacity: int): LruCache[K,T] =
  ## Create a new Least-Recently-Used (LRU) cache that store the last `capacity`-accessed items.
  LruCache[K,T](
    capacity: capacity,
    list: initDoublyLinkedList[Node[K,T]](),
    table: initTable[K, DoublyLinkedNode[Node[K,T]]](rightSize(capacity))
  )
    
proc resize[K,T](cache: LruCache[K,T]) =
  while cache.len > cache.capacity:
    let t = cache.list.tail
    cache.table.del(t.value.key)
    cache.list.remove t

proc addNewNode[K,T](cache: LruCache[K,T], key: K, val: T) =
  # create new node 
  let node = newDoublyLinkedNode[Node[K,T]](
    Node[K,T](key: key, val: val)
  )
  # put on table and prepend new node 
  cache.table[key] = node
  cache.list.prepend node
  # remove old node if exceed capacity
  cache.resize()

proc capacity*[K,T](cache: LruCache[K,T]): int = 
  ## Get the maximum capacity of cache
  cache.capacity

proc `capacity=`*[K,T](cache: LruCache[K,T], capacity: int) = 
  ## Resize the maximum capacity of cache
  cache.capacity = capacity
  cache.resize()

proc len*[K,T](cache: LruCache[K,T]): int = 
  ## Return number of key in cache
  cache.table.len

proc contains*[K,T](cache: LruCache[K,T], key: K): bool =
  ## Check whether key in cache. Does *NOT* update recentness.
  cache.table.contains(key)

proc peek*[K,T](cache: LruCache[K,T], key: K): T =
  ## Read value by key, but *NOT* update recentness.
  ## Raise `KeyError` if `key` is not in `cache`.
  let node = cache.table[key] 
  result = node.value.val

proc del*[K,T](cache: LruCache[K,T], key: K) =
  ## Delete key in cache. Does nothing if key is not in cache.
  let node = cache.table.getOrDefault(key, nil)
  if not node.isNil:
    cache.table.del(key)
    cache.list.remove(node)

proc clear*[K,T](cache: LruCache[K,T]) =
  ## remove all items
  cache.list = initDoublyLinkedList[Node[K,T]]()
  cache.table.clear()

proc `[]`*[K,T](cache: LruCache[K,T], key: K): T =
  ## Read value from `cache` by `key` and update recentness
  ## Raise `KeyError` if `key` is not in `cache`.
  let node = cache.table[key]        # may raise KeyError
  result = node.value.val
  cache.list.remove node
  cache.list.prepend node

proc `[]=`*[K,T](cache: LruCache[K,T], key: K, val: T) =
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
    
proc get*[K,T](cache: LruCache[K,T], key: K): T = 
  ## Alias of `cache[key]`
  cache[key]

proc put*[K,T](cache: LruCache[K,T], key: K, val: T): T =
  ## Alias of `cache[key] = val`
  cache[key] = val
  
proc getOrDefault*[K,T](cache: LruCache[K,T], key: K, val: T): T =
  ## Similar to get, but return `val` if `key` is not in `cache`
  let node = cache.table.getOrDefault(key, nil)
  if node.isNil:
    result = val
  else:
    result = node.value.val

proc getOrPut*[K,T](cache: LruCache[K,T], key: K, val: T): T =
  ## Similar to `get`, but put and return `val` if `key` is not in `cache`
  let node = cache.table.getOrDefault(key, nil)
  if not node.isNil:
    result = node.value.val
  else:
    result = val
    cache.addNewNode(key, val)

proc getOption*[K,T](cache: LruCache[K,T], key: K): Option[T] =
  ## Similar to `get`, but return `None` if `key` is not in `cache` 
  ## or else return `Some(value)` and update recentness
  let node = cache.table.getOrDefault(key, nil)
  if node.isNil: none(T)
  else: some(node.value.val)

proc isEmpty*[K,T](cache: LruCache[K,T]): bool {.inline.} = 
  ## Equivalent to `cache.len == 0`
  cache.len == 0

proc isFull*[K,T](cache: LruCache[K,T]): bool {.inline.} = 
  ## Equivalent to `cache.len == cache.capacity`
  ## Raise `EmptyLruCacheError` if `cache` is empty.
  cache.len == cache.capacity

proc getMruKey*[K,T](cache: LruCache[K,T]): K =
  ## Return most recently used key.
  ## Raise `EmptyLruCacheError` if `cache` is empty.
  if cache.isEmpty:
    raise newException(EmptyLruCacheError, "Cannot get most recently used key from empty cache")
  cache.list.head.value.key

proc getMruValue*[K,T](cache: LruCache[K,T]): T =
  ## Return most recently used value.
  ## Raise `EmptyLruCacheError` if `cache` is empty.
  if cache.isEmpty:
    raise newException(EmptyLruCacheError, "Cannot get most recently used value from empty cache")
  cache.list.head.value.val

proc getLruKey*[K,T](cache: LruCache[K,T]): K =
  ## Return least recently used key.
  ## Raise `EmptyLruCacheError` if `cache` is empty.
  if cache.isEmpty:
    raise newException(EmptyLruCacheError, "Cannot get least recently used key from empty cache")
  cache.list.tail.value.key

proc getLruValue*[K,T](cache: LruCache[K,T]): T =
  ## Return least recently used value.
  ## Raise `EmptyLruCacheError` if `cache` is empty.
  if cache.isEmpty:
    raise newException(EmptyLruCacheError, "Cannot get least recently used value from empty cache")
  cache.list.tail.value.val


   
