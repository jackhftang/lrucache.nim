import lists
import tables

type
  # no need to use ref, since DoublyLinkedNode is already a ref
  Node[K,T] = object
    key: K
    val: T

  LruCache*[K, T] = ref object 
    capacity: int
    list: DoublyLinkedList[Node[K,T]]
    table: Table[K, DoublyLinkedNode[Node[K,T]]]

template rightSize(cap): untyped {.dirty.} =
  when (NimMajor,NimMinor)<(1,4):
    tables.rightSize(cap)
  else:
    cap

proc newLruCache*[K,T](capacity: int): LruCache[K,T] =
  ## Create a new Least-Recently-Used (LRU) cache that store the last `capacity`-accessed items.
  LruCache[K,T](
    capacity: capacity,
    list: initDoublyLinkedList[Node[K,T]](),
    table: initTable[K, DoublyLinkedNode[Node[K,T]]]( rightSize(capacity) )
  )
  
