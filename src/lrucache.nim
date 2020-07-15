import hashes, lists, tables, options

type
  # no need to use ref, since DoublyLinkedNode is already a ref
  Node[T] = object
    key: Hash
    val: T

  LruCache*[K, T] = ref object 
    capacity: int
    list: DoublyLinkedList[Node[T]]
    table: Table[Hash, DoublyLinkedNode[Node[T]]]

proc newLruCache*[K,T](capacity: int): LruCache[K,T] =
  ## Create a new Least-Recently-Used (LRU) cache that store the last `capacity`-accessed items.
  LruCache[K,T](
    capacity: capacity,
    list: initDoublyLinkedList[Node[T]](),
    table: initTable[Hash, DoublyLinkedNode[Node[T]]]( rightSize(capacity) )
  )

proc resize[K,T](cache: LruCache[K,T]) =
  while cache.len > cache.capacity:
    let t = cache.list.tail
    cache.table.del(t.value.key)
    cache.list.remove t

proc addNewNode[K,T](cache: LruCache[K,T], hkey: Hash, val: T) =
  # create new node 
  let node = newDoublyLinkedNode[Node[T]](
    Node[T](key: hkey, val: val)
  )
  # put on table and prepend new node 
  cache.table[hkey] = node
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
  cache.table.contains(hash(key))

proc peek*[K,T](cache: LruCache[K,T], key: K): T =
  ## Read value by key, but *NOT* update recentness.
  ## Raise `KeyError` if `key` is not in `cache`.
  let hkey = hash(key)
  let node = cache.table[hkey] 
  result = node.value.val

proc del*[K,T](cache: LruCache[K,T], key: K) =
  let hkey = hash(key)

  ## Delete key in cache. Does nothing if key is not in cache.
  let node = cache.table.getOrDefault(hkey, nil)
  if not node.isNil:
    cache.table.del(hkey)
    cache.list.remove(node)

proc clear*[K,T](cache: LruCache[K,T]) =
  ## remove all items
  cache.list = initDoublyLinkedList[Node[T]]()
  cache.table.clear()

proc `[]`*[K,T](cache: LruCache[K,T], key: K): T =
  ## Read value from `cache` by `key` and update recentness
  ## Raise `KeyError` if `key` is not in `cache`.
  let hkey = hash(key)
  let node = cache.table[hkey]        # may raise KeyError
  result = node.value.val
  cache.list.remove node
  cache.list.prepend node

proc `[]=`*[K,T](cache: LruCache[K,T], key: K, val: T) =
  ## Put value `v` in cache with key `k`.
  ## Remove least recently used value from cache if length exceeds capacity.
  let hkey = hash(key)

  # read current node
  var node = cache.table.getOrDefault(hkey, nil)
  if node.isNil:
    cache.addNewNode(hkey, val)
  else:
    # set value 
    node.value.val = val
    # move to head
    cache.list.remove node
    cache.list.prepend node
    
proc get*[K,T](cache: LruCache[K,T], key: K): T {.inline.} = 
  ## Alias of `cache[key]`
  cache[key]

proc put*[K,T](cache: LruCache[K,T], key: K, val: T): T {.inline.} =
  ## Alias of `cache[key] = val`
  cache[key] = val
  
proc getOrDefault*[K,T](cache: LruCache[K,T], key: K, val: T): T =
  ## Similar to get, but return `val` if `key` is not in `cache`
  let hkey = hash(key)
  let node = cache.table.getOrDefault(hkey, nil)
  if node.isNil:
    result = val
  else:
    result = node.value.val

proc getOrPut*[K,T](cache: LruCache[K,T], key: K, val: T): T =
  ## Similar to `get`, but put and return `val` if `key` is not in `cache`
  let hkey = hash(key)
  let node = cache.table.getOrDefault(hkey, nil)
  if not node.isNil:
    result = node.value.val
  else:
    result = val
    cache.addNewNode(hkey, val)

proc getOption*[K,T](cache: LruCache[K,T], key: K): Option[T] =
  ## Similar to `get`, but return `None` if `key` is not in `cache` 
  ## or else return `Some(value)` and update recentness
  let hkey = hash(key)
  let node = cache.table.getOrDefault(hkey, nil)
  if node.isNil: none(T)
  else: some(node.value.val)

proc isEmpty*[K,T](cache: LruCache[K,T]): bool = 
  ## Equivalent to `cache.len == 0`
  cache.len == 0

proc isFull*[K,T](cache: LruCache[K,T]): bool = 
  ## Equivalent to `cache.len == cache.capacity`
  cache.len == cache.capacity

