#module listsv
#
# Nim Language implementation of singly and doubly
# linked lists with supporting functions like
# insertions, removes, finds, and trimming.
#
# Author srwiley@github.com

## Implementation of singly and doubly linked lists with supporting
## procedures like inserting, finding, extracting, deleting and trimming.
##
## Many procs have forms compatible with using Link objects directly
## or the generic value
## types, so the user can choose what level of access they require.

import future 

type

  LinkType* = enum
    ## LinkedLists use one of these link types
    ltSingle,ltDouble

  Link*[T] = ref object of RootObj
    ## Single link
    next* : Link[T]
    value* : T

  DoubleLink*[T] = ref object of Link[T]
    ## Double link extends single link
    prev* : DoubleLink[T]

  LinkedList*[T] = ref object
    ## LinkedList instantiates both singly and douby linked lists.
    ## The linkType value determines what procs will be populated into the
    ## proc fields as required by single or double links.
    ##
    ## Head and tail values hold the first and last links in the list.
    ## The tail link next value is nil for a valid list, and if the list is
    ## doubly linked the head link prev value is nil.
    ##
    ## The count value is for internal use only and might be set to -1
    ## signifying invalid by a trim operation.
    ## Use the len() proc to obtain the number of links in the list.
    ##
    ## This implementation handles generics and dynamic method dispatching
    ## by saving procs that are
    ## different between singly and doubly linked lists, such as newLink,
    ## in proc fields in the LinkedList object when the list is created.
    ## These procs can then be called like other procs.
    ## For example:
    ##
    ## .. code-block:: nim
    ##   let # Both of these are type LinkedList[int]
    ##     singleList = createLinkedList[int](ltSingle)
    ##     doubleList = createLinkedList[int](ltDouble)
    ##   # But newLink generates different object types 
    ##   assert singleList.newLink(1) of Link[int]
    ##   assert doubleList.newLink(1) of DoubleLink[int]
    
    count : int
    # count can be invalid by the trim operation for efficiency
    # If invalid count is set to -1. Count will be reset if len is called by
    # iterating through the entire list.
    linkType* : LinkType
    head* : Link[T]
    tail* : Link[T]
    newLink* : proc(t:T) : Link[T]
    # Creates a new link of type Link or Double
    # link depending on the linkedList's linkType
    insertAfter* : proc(plug, place: Link[T])
    # Inserts plug after place in the list.
    # Place link must be in the list.
    insertBefore* : proc(plug, place: Link[T])
    # Inserts plug before place in the list
    # Place link must be in the list.
    trimBefore* : proc(place: Link[T])
    # Trims the list so that it starts with the place link.
    # Place link must be in the list.
    removeNext* : proc(link : Link[T]) : Link[T]
    # Removes link.next from the list. Works efficiently
    # for both singly and double linked lists
    remove* : proc(link : Link[T])
    # Removes link.next from the list. Works efficiently
    # for only doubly linked lists. Singly linked lists
    # must iterate from the start of the list to set the 
    # previous links next pointer to link.next
    
  # It is the user's responsibility to make sure 
  # that the link type is Link or DoubleLink
  # depending on the linkedList's linkType for
  # the above procedures if called directly.

proc clear*[T](list : LinkedList[T]) =
  ## The list is cleared of all values and the link refs
  ## are free to be GC'ed.
  list.head = nil
  list.tail = nil
  list.count = 0

proc len*[T](list: LinkedList[T] ) : int =
    ## Returns the number of links in the list. 
    ## For example:
    ##
    ## .. code-block:: nim
    ##   let list = newLinkedList("mouse", "cat", "dog")
    ##   assert list.len == 3
    ##
    if list.count >= 0 : 
      return list.count
    list.count = 0
    var link = list.head
    while link != nil :
      inc(list.count)
      link = link.next
    return list.count

template addIfGE0( inc : int) =
  # reduces repeat code in createLinkedList
  if list.count >= 0:
    list.count += inc

template initIfNil( dorev : stmt)  =
  # reduces repeat code in createLinkedList
  if place == nil :
    list.head = plug
    list.tail = plug
    list.count = 1
    plug.next = nil
    dorev
    return
  addIfGE0(1)
  
template remNext() =
  # reduces repeat code in createLinkedList
  result = link.next
  if link.next == nil:
    assert list.tail == link
    return
  addIfGE0(-1)
  link.next  = link.next.next
  if link.next == nil:
    list.tail = link
      
template insAfter() =
  # reduces repeat code in createLinkedList
  plug.next = place.next
  place.next = plug
  if list.tail == place:
    list.tail = plug

proc trimAfter*[T](list : LinkedList[T],place : Link[T]) =
  ## Removes all links after the place link in the list.
  ## For example:
  ##
  ## .. code-block:: nim
  ##  let
  ##    animalSeqs = @["cat", "dog", "mouse", "duck", "goat", "rat"]
  ##    list = newLinkedList[string](animalSeqs[0..animalSeqs.high])
  ##  assert list.len == 6
  ##
  ##  let duckLink = list.findFirst("duck")
  ##  list.trimAfter(duckLink)
  ##  assert list.len == 4
  ##  assert list.tail == duckLink
  ##  assert list.head.value == "cat"
  ##
  ##  let dogLink = list.findFirst("dog")
  ##  list.trimBefore(dogLink)
  ##  assert list.len == 3
  ##  assert list.tail == duckLink
  ##  assert list.head == dogLink
  ##
  ## Note that the trimBefore proc is a field in the LinkList object,
  ## but can be called like any proc.
  ## Calls to either trim function invalidates the internal link count 
  ## of the list
  ## and so the next call to len() will force traversal of the 
  ## entire list to re-count the links.
  place.next = nil
  list.tail = place
  list.count = -1

proc append*[T](list : LinkedList[T], value : T) =
  ## Appends the value to the end of the list.
  ##
  ## .. code-block:: nim
  ##  let
  ##    list = newLinkedList[string]()
  ##    animalSeqs = @["cat", "dog", "mouse", "duck", "goat", "rat"]
  ##  for s in animalSeqs:
  ##    list.append(s)
  ##  var i = 0
  ##  for v in list.values:
  ##    assert v == animalSeqs[i]
  ##    inc i
  ## 
  list.insertAfter(list.newLink(value),list.tail)

proc prepend*[T](list : LinkedList[T], value : T) =
  ## Prepends the value to the start of the list.
  ##
  ## .. code-block:: nim
  ##  let 
  ##    list = newLinkedList[string]()
  ##    animalSeqs = @["cat", "dog", "mouse", "duck", "goat", "rat"]
  ##  for s in animalSeqs:
  ##    list.prepend(s)
  ##  var i = animalSeqs.high
  ##  for v in list.values:
  ##    assert v == animalSeqs[i]
  ##    dec i
  list.insertBefore(list.newLink(value),list.head)

proc createLinkedList*[T]( linkType : LinkType = ltSingle ) : LinkedList[T] =
  ## Returns a new empty LinkedList of type linkType. ltSingle is the default.
  ##
  ## Depending on the linkType argument, the list will use either Link or
  ## DoubleLink type links, and the proc fields in the LinkedList object will be 
  ## populated as appropriate for the link type, leveraging
  ## the use of proc fields and variable capture as an alternative to dynamic 
  ## method dispatching.
  ##
  var list = LinkedList[T](linkType: linkType)
  case linkType:
    of ltSingle:
      list.newLink = proc(t : T) : Link[T] = Link[T](value:t)
      list.insertAfter =  proc(plug,place: Link[T]) =
          initIfNil : discard
          insAfter
      list.insertBefore =  proc(plug,place: Link[T]) =
          plug.next = place
          initIfNil : discard
          if list.head == place:
            list.head = plug
            return
          var node = list.head
          while node != nil :
            if node.next == place:
              node.next = plug
              return
            node = node.next
      list.removeNext = proc(link: Link[T]): Link[T] =
          remNext
      list.remove = proc(link: Link[T]) =
         addIfGE0(-1)
         if list.head == link:
            list.head = link.next
            if list.head == nil:
              list.tail = nil
            return
         var node = list.head
         while node != nil :
           if node.next == link:
              node.next = link.next
              if node.next == nil:
                list.tail = node
              return
           node = node.next
      list.trimBefore = proc(place: Link[T]) =
          list.head = place
          list.count = -1
    of ltDouble:
      list.newLink = proc(t : T) : Link[T] = DoubleLink[T](value:t)
      list.insertAfter =  proc(plug,place: Link[T]) =
          initIfNil: DoubleLink[T](plug).prev  = nil
          insAfter
          if plug.next != nil:
              DoubleLink[T](plug.next).prev =  DoubleLink[T](plug)
          DoubleLink[T](plug).prev = DoubleLink[T](place)
      list.insertBefore =  proc(plug,place: Link[T]) =
          let dplug = DoubleLink[T](plug)
          initIfNil: dplug.prev = nil
          dplug.next = place
          dplug.prev = DoubleLink[T](place).prev
          DoubleLink[T](place).prev = dplug
          if dplug.prev != nil:
              dplug.prev.next = dplug
          if list.head == place:
            list.head = plug
      list.removeNext = proc(link: Link[T]): Link[T] =
          if link.next.next != nil:
            DoubleLink[T](link.next.next).prev = DoubleLink[T](link)
          remNext
      list.remove = proc(link: Link[T]) =
          addIfGE0(-1)
          if link == list.tail:
             list.tail = DoubleLink[T](link).prev
          if link == list.head:
             list.head = link.next
          if link.next != nil:
             DoubleLink[T](link.next).prev = DoubleLink[T](link).prev
          if DoubleLink[T](link).prev != nil:
             DoubleLink[T](link).prev.next = link.next
      list.trimBefore = proc(place: Link[T]) =
          list.head = place
          DoubleLink[T](place).prev = nil
          list.count = -1
  return list

proc newLinkedList*[T](values : varargs[T]) : LinkedList[T] =
  ## Returns a new singly linked list filled with all provided
  ## values.
  ##
  ## This example creates two singly
  ## linked lists with type string values:
  ##
  ## .. code-block:: nim
  ##   let
  ##     list1 = newLinkedList("mouse", "cat", "dog")
  ##     list2 = newLinkedList[string]()
  ##   assert list1.len == 3
  ##   assert list2.len == 0
  
  result = createLinkedList[T](ltSingle)
  for v in values:
    result.append(v)

proc newDoubleLinkedList*[T]( values : varargs[T]) : LinkedList[T] =
  ## Returns a new doubly linked list filled with all provided values.
  ##
  ## This example creates two doubly
  ## linked lists with type string values:
  ##
  ## .. code-block:: nim
  ##   let
  ##     list1 = newDoubleLinkedList("mouse", "dog")
  ##     list2 = newDoubleLinkedList[string]()
  ##   assert list1.len == 2
  ##   assert list2.len == 0
  ##
  ## Although all procs are compatible with singly and doubly linked lists, procs
  ## requring reverse iteration through the list are done more efficiently with 
  ## doubly linked lists.
  result = createLinkedList[T](ltDouble)
  for v in values:
    result.append(v)

iterator links*[T](list : LinkedList[T]) : Link[T]=
    ## Forward iterates through the list's links.
    var link = list.head
    while link != nil :
      yield link
      link = link.next

iterator values*[T](list : LinkedList[T]) : T =
   ## Forward iterates through the list's values.
   for link in list.links: yield link.value

iterator reverseLinks*[T](list : LinkedList[T]) : Link[T] =
   ## Reverse iterates through the list's links. 
   ## Singly linked lists are less efficient
   ## than doubly as they iterate through 
   ## the entire list first, and store
   ## the links in a seq in reverse order.
   case list.linkType
      of ltSingle:
        var revNodes = newSeq[Link[T]](list.len)
        var cntr = 0
        for link in list.links:
            inc cntr
            revNodes[list.len - cntr] = link
        for link in revNodes:
          yield link
      of ltDouble:
        var link = list.tail
        while link != nil :
          yield link
          link = DoubleLink[T](link).prev

iterator reverseValues*[T](list : LinkedList[T]) : T =
   ## Reverse iterates through the list's values.
   ## Singly linked lists are less efficient
   ## than doubly as they must iterate through and store
   ## the lists in a seq in reverse order.
   for link in list.reverselinks:
      yield link.value
      
proc insertBeforeHere*[T](list : LinkedList[T], plug : Link[T],
                          isHere : proc(link: Link[T]) : bool ) : bool =
  ## Inserts plug before the first link in the list that returns 
  ## true when passed to the isHere proc, 
  ## and returns true if and only if an insertion is made. This
  ## operation is more efficient with a doubly linked list.
  ##
  ## .. code-block:: nim
  ##   import future 
  ##   let list = newDoubleLinkedList("big", "small")
  ##   assert list.insertBeforeHere(list.newLink("medium"),
  ##                                link => link.value == "small")
  ##   assert list.len == 3
  ##   assert list.head.value == "big"
  ##   assert list.head.next.value == "medium"
  ##   assert list.tail.value == "small"
  for link in list.links:
    if isHere(link) == true:
      list.insertBefore(plug,link)
      return true
  return false

proc insertBeforeHere*[T](list:LinkedList[T], plug: T, 
                          isHere : proc(t: T) : bool ) : bool =
  ## Inserts a new link with value plug before the first link in the list that 
  ## returns true when the link value is passed to the isHere proc, 
  ## and returns true if and only if an insertion is made. This
  ## operation is more efficient with a doubly linked list.
  ##
  ## .. code-block:: nim
  ##   import future 
  ##   let list = newDoubleLinkedList("big", "small")
  ##   assert list.insertBeforeHere("medium",(value :string)=> value == "small")
  ##   assert list.len == 3
  ##   assert list.head.value == "big"
  ##   assert list.head.next.value == "medium"
  ##   assert list.tail.value == "small"
  return list.insertBeforeHere(list.newLink(plug), 
                              (link:Link[T]) => isHere(link.value))
  
proc insertBeforeValue*[T](list:LinkedList[T], plug, value: T ) : bool =
  ## Inserts a new link with value plug before the first link in the list
  ## with value equal
  ## to the target and returns true if and only if an insertion is made.
  ## This operation is more efficient with a doubly linked list.
  ##
  ## .. code-block:: nim
  ##   let list = newLinkedList("big", "small")
  ##   assert list.insertBeforeValue("medium","small")
  ##   assert list.len == 3
  ##   assert list.head.value == "big"
  ##   assert list.head.next.value == "medium"
  ##   assert list.tail.value == "small"
  return list.insertBeforeHere(plug, (t:T) => t == value)
  
proc insertAfterHere*[T](list:LinkedList[T], plug: Link[T],
                         isHere : proc(link: Link[T]) : bool ) : bool =
  ## Inserts plug before the first link in the list that returns 
  ## true when passed to the isHere proc, 
  ## and returns true if and only if an insertion is made. 
  ## Similar usage to insertBeforeHere.
  for link in list.links:
    if isHere(link) == true:
      list.insertAfter(plug,link)
      return true
  return false

proc insertAfterHere*[T](list:LinkedList[T], plug: T, 
                         isHere : proc(t: T) : bool ) : bool =
  ## Inserts a new link with value plug before the first link in the list that 
  ## returns true when the link value is passed to the isHere proc, 
  ## and returns true if and only if an insertion is made. 
  ## Similar usage to insertBeforeHere.
  return list.insertAfterHere(list.newLink(plug), 
                              (link:Link[T]) => isHere(link.value))
  
proc insertAfterValue*[T](list:LinkedList[T], plug, value: T ) : bool =
  ## Inserts a new link with value plug before the first link in the list
  ## with value equal
  ## to the target and returns true if and only if an insertion is made.
  ## Similar usage to insertBeforeValue.
  return list.insertAfterHere(plug, (t:T) => t == value)

proc findAll*[T](list: LinkedList[T],
                 test: proc(link: Link[T]): bool ): LinkedList[T] =
  ## Returns a new linked list with links containing the values of all
  ## links that satisfy the test proc. Returns an empty list if all 
  ## links fail. For example:
  ##
  ## .. code-block:: nim
  ##   import future 
  ##   let list = newDoubleLinkedList("bird", "cat", "bear", "mouse")
  ##   let found = list.findAll((link:Link[string])=> link.value[0] == 'b')
  ##   assert found.len == 2
  ##   assert found.head.value == "bird"
  ##   assert found.tail.value == "bear"
  
  result = createLinkedList[T](list.linkType)
  for link in list.links:
    if link.test == true:
      result.insertAfter(result.newLink(link.value),result.tail)
      
proc findAll*[T](list: LinkedList[T], test: proc(t: T): bool ):  LinkedList[T] =
  ## Returns a new linked list with links containing the values of all
  ## links with values that satisfy the test proc. Returns an empty list if all 
  ## links fail. For example:
  ##
  ## .. code-block:: nim
  ##   import future 
  ##   let list = newDoubleLinkedList("bird", "cat", "bear", "mouse")
  ##   let found = list.findAll((value:string)=> value[0] == 'b')
  ##   assert found.len == 2
  ##   assert found.head.value == "bird"
  ##   assert found.tail.value == "bear"
  return list.findAll( (link:Link[T]) => test(link.value))
  
proc findFirst*[T](list: LinkedList[T], 
                   test : proc(link: Link[T]) : bool ) : Link[T] =
  ## Returns the first link in the list satisfying the test proc.
  ## Returns nil if all links fail test
  for link in list.links:
    if link.test == true:
      return link
      
proc findFirst*[T](list: LinkedList[T], test : proc(t: T) : bool ) : Link[T] =
  ## Returns the first link in the list satisfying the test proc applied to 
  ## the link value. Returns nil if all values fail.
  return list.findFirst( (link:Link[T]) => test(link.value))

proc findFirst*[T](list: LinkedList[T] , t : T ) : Link[T] =
  ## Returns the first link in the list with value equal to t or
  ## nil if no values match.
  return list.findFirst( (link:Link[T]) => link.value == t )
    
proc contains*[T](list: LinkedList[T] , t : T ) : bool =
    ## Return true if and only if the list contains a link with value t
    return list.findFirst( (link:Link[T]) => link.value == t ) != nil

proc findLast*[T](list: LinkedList[T] , 
                  test : proc(link: Link[T]) : bool ) : Link[T] =
  ## Returns the last link in the list satisfying the test proc. 
  ## Nil if all links fail.
  ## This is more efficient for doubly linked lists than singly linked lists. 
  for link in list.reverseLinks:
    if link.test == true:
      return link

proc findLast*[T](list: LinkedList[T], test : proc(t: T) : bool ) : Link[T] =
  ## Returns the last link in the list satisfying the test proc applied to 
  ## the link value. Returns nil if all values fail. This is more efficient
  ## for doubly linked lists than singly linked lists. 
  return list.findLast( (link:Link[T]) => test(link.value))
  
proc findLast*[T](list: LinkedList[T] , t : T) : Link[T] =
  ## Returns the last link in the list with value equal to t or
  ## nil if no values match. This is more efficient
  ## for doubly linked lists than singly linked lists.
  return list.findLast( (link:Link[T]) => link.value == t )

proc deleteLink*[T](list: LinkedList[T] , test: proc(link: Link[T]): bool , 
                    doWith : proc(link: Link[T])) : int =
    ## Removes from the list all links that are true for the test proc 
    ## and returns the total number of links removed. 
    ##
    ## The doWith function calls back every link that is removed, 
    ## allowing the links be used in other containers which can
    ## be useful for avoiding GC overhead by not having to create 
    ## new refs to links. For example:
    ##
    ## .. code-block:: nim
    ##    import future
    ##
    ##    let list = newLinkedList[int]()
    ##    let underdogs = newLinkedList[int]()
    ##    for i in 1..100:
    ##        list.append(i*i mod 100)
    ##    assert list.len == 100
    ##    let removed = list.deleteLink(
    ##       (link:Link[int])=> link.value < 50, 
    ##       (link:Link[int])=> underdogs.insertAfter(link,underdogs.tail))
    ##    assert removed + list.len == 100
    ##    assert removed == underdogs.len
    if list.head == nil:
      return
    while list.head != nil and list.head.test :
      let head = list.head
      list.remove(list.head)
      doWith(head)
      result.inc
    var link = list.head
    while link.next != nil:
      if link.next.test:
        doWith( list.removeNext(link))
        inc result
      else:
        link = link.next
        
proc discardLink[T](link: Link[T]) =
    discard

proc deleteLink*[T](list:LinkedList[T], test: proc(link: Link[T]): bool ): int =
  ## Removes from the list all links that return true from
  ## the test proc and returns the total number of links 
  ## that were removed. For example:
  ##
  ## .. code-block:: nim
  ##    import future
  ##    let list = newLinkedList[int]()
  ##    for i in 1..100:
  ##        list.append(i*i mod 100)
  ##    assert list.len == 100
  ##    let removed = list.deleteLink( link => link.value < 50)
  ##    assert removed + list.len == 100
  return deleteLink(list,test,discardLink)

proc delete*[T](list: LinkedList[T] ,
                test : proc(t :T) : bool , doWith : proc(t : T)) : int =
    ## Removes from the list all links with values that are true for the test
    ## proc and returns the total number of links removed. 
    ##
    ## The doWith function is a call back for every value that is removed.
    ## For example:
    ##
    ## .. code-block:: nim
    ##    import future
    ##    let list = newLinkedList[int]()
    ##    var recovered : seq[int] = @[]
    ##    for i in 1..100:
    ##        list.append(i*i mod 100)
    ##    assert list.len == 100
    ##    let removed = list.delete((val:int)=> val < 50, (val:int)=> recovered.add(val))
    ##    assert removed + list.len == 100
    ##    assert removed == recovered.len
    return list.deleteLink( (link:Link[T]) => test(link.value), 
                          (link:Link[T]) => doWith(link.value) )

proc discardValue[T](t : T) = discard
    
proc delete*[T](list: LinkedList[T] , test : proc(t :T) : bool ) : int =
  ## Deletes all links that return true when their values are passed to test,
  ## and returns the number of deleted links.
  return list.deleteLink( (link:Link[T]) => test(link.value), discardValue)

proc extractLink*[T](list: LinkedList[T] , 
                     test: proc(link: Link[T]): bool) : LinkedList[T] =
  ## Extracts all links testing true into the returned list of same linkType as the calling list.
  ## For example:
  ##
  ## .. code-block:: nim
  ##    import future
  ##
  ##    let list = newLinkedList[int]()
  ##    for i in 1..100:
  ##        list.append(i*i mod 100)
  ##    assert list.len == 100
  ##    let underdogs = list.extractLink( (link:Link[int]) => link.value < 50)
  ##    assert underdogs.len + list.len == 100
  ##    for i in underdogs.values:
  ##        assert i < 50
  ##    for i in list.values:
  ##        assert i >= 50
  let extracted = createLinkedList[T](list.linkType)
  discard deleteLink(list, test, (link: Link[T]) => extracted.insertAfter(link,extracted.tail))
  return extracted
  
proc extract*[T](list: LinkedList[T] ,
                 test : proc(t : T) : bool ) : LinkedList[T] =
  ## Extracts all links with values testing true into the returned 
  ## list of same linkType as the calling list. For example:
  ##
  ## .. code-block:: nim
  ##    import future
  ##
  ##     let list = newLinkedList[int]()
  ##     for i in 1..100:
  ##        list.append(i*i mod 100)
  ##     assert list.len == 100
  ##     let underdogs = list.extract( (t :int) => t < 50)
  ##     assert underdogs.len + list.len == 100
  ##     for i in underdogs.values:
  ##        assert i < 50
  ##     for i in list.values:
  ##        assert i >= 50
  return list.extractLink( (link : Link[T]) => test(link.value))

proc `$`*[T](list: LinkedList[T] ) : string = 
  ## Dollar to string function for LinkedList types.
  ## Double lists are enclosed by braces and single lists
  ## by brackets.
  result = if list.linkType == ltDouble : "{" else: "["
  for t in list.values:
    if result.len > 1: result.add(", ")
    result.add($t)
  result.add(if list.linkType == ltDouble: "}"  else: "]")

when isMainModule:
 # testing for the linked listx module

 var animalSeqs = @["cat", "dog", "mouse", "duck", "goat", "rat"]
    
 proc testList[T](list : LinkedList[T]) =
    if list.len == 0:
        assert list.tail == nil
        assert list.head == nil
        return
    if list.len == 1:
      assert list.head != nil
      assert list.head == list.tail
      assert list.head.next == nil
      return
    assert list.tail != nil
    assert list.head != nil
    var count = 0
    var last : Link[T]
    for link in list.links :
      assert link.value != nil
      last = link
      count.inc
    assert list.len() == count , "count is " & $count & " list.len is " & $list.len
    assert last != nil
    assert list.tail == last
    assert last.next == nil
    case list.linkType 
      of ltDouble:
        count = 0
        last = nil
        for link in list.reverseLinks:
          assert link.value != nil
          assert link of DoubleLink[T]
          last = link
          count.inc
        assert count == list.len , " Error in reverse count, got " & $count & " list.len is " & $list.len
        assert last != nil
        assert list.head == last
        assert DoubleLink[T](last).prev == nil
      of ltSingle:
        count = 0
        last = nil
        for link in list.reverseLinks:
          assert link.value != nil
          assert ((link of DoubleLink[T]) == false)
          last = link
          count.inc
        assert count == list.len , " Error in reverse count, got " & $count & " list.len is " & $list.len
        assert last != nil
        assert list.head == last

 template testLinks( list,rlist : expr) = 
    assert list.len == 0
    assert rlist.len == 0
    for s in animalSeqs:
      list.append(s)
      list.testList()
    for s in animalSeqs:
      rlist.prepend(s) 
      rList.testList()
    var index = 0
    for s in list.values:
      assert s == animalSeqs[index]
      inc index
    assert index == 6
    index = 0
    for s in rlist.values:
      assert s == animalSeqs[ animalSeqs.high - index]
      inc index
    assert index == 6
    index = 0
    for s in rlist.reverseValues:
      assert s == animalSeqs[index]
      inc index
    assert index == 6
    index = 0
    for s in list.reverseValues:
      assert s == animalSeqs[ animalSeqs.high - index]
      inc index
    assert index == 6
    
    let f = proc( t : Link[string] ): bool = 
      return t.value == "dog"
      
    var link = list.findFirst("dog")
    assert link != nil
    list.remove(link)
    list.testList()
    assert list.len == len(animalSeqs) - 1
    let mlink = list.findFirst("mouse")
    let mlink2 = list.findFirst( (t:string) => t == "mouse")
    let mlink3 = list.findFirst( (lnk:Link[string]) => lnk.value == "mouse")
    let flink = list.findLast("mouse")
    let flink2 = list.findLast( (t:string) => t == "mouse")
    let flink3 = list.findLast( (lnk:Link[string]) => lnk.value == "mouse")
    assert mlink == mlink2
    assert mlink2 == mlink3
    assert flink == flink2
    assert flink2 == flink3
    assert flink == mlink
    list.insertBefore(list.newLink("dog"), mLink)
    list.testList()
    assert list.len == len(animalSeqs)
    
    assert list.contains("dog"), "Dog gone"
    link = list.findFirst("dog")
    assert link != nil
    list.remove(link)
    assert list.contains("dog") == false, "Dog not gone"
    
    list.testList()
    assert list.len == len(animalSeqs) - 1
    let clink = list.findFirst("cat")
    list.insertAfter(list.newLink("dog"), cLink)
    list.testList()
    assert list.len == len(animalSeqs)
    
    index = 0
    for s in list.values:
      assert s == animalSeqs[index]
      inc index
     
    link = list.findFirst("dog")
    assert link != nil
    assert list.contains("mouse") , "Mouse gone"
    let removed = list.removeNext(link)
    assert removed.value == "mouse"
    assert list.contains("mouse") == false, "Mouse not gone"
    list.testList()
    assert list.len == len(animalSeqs) - 1
    let ok = list.insertAfterValue("mouse", "dog")
    assert ok == true
    assert list.contains("mouse") , "Mouse not back"
    list.testList()
    assert list.len == len(animalSeqs) 
    
    index = 0
    for s in list.values:
      assert s == animalSeqs[index]
      inc index
    
    let extracted = list.extractLink( lnk => lnk.value == "mouse" or lnk.value == "rat")
    extracted.testList
    list.testList
    assert extracted.len == 2 , "count:" & $extracted.len
    assert extracted.head.value == "mouse"
    assert extracted.tail.value == "rat"
    
    let extracted2 = list.extract( value => value == "cat")
    extracted2.testList
    list.testList
    assert extracted2.len == 1 , "count:" & $extracted2.len
    assert extracted2.head == extracted2.tail
    assert extracted2.head.value == "cat"
    
    extracted.remove(extracted.tail)
    assert extracted.len == 1 , "rem rcount:" & $extracted.len
    extracted.testList
    extracted.remove(extracted.head)
    assert extracted.len == 0 , "rem count:" & $extracted.len
    extracted.testList
    
    let duckLink = list.findFirst("duck")
    assert duckLink != nil, "Duck missing"
    for i in 1..2: # do twice; trimmed seqs should stay trimmed
      list.trimAfter(duckLink)
      assert list.count == -1, "Count not neg " & $list.count
      list.testList
      assert list.len == 2
    list.prepend("hamster")
    list.testList
    assert list.len == 3
    for i in 1..2: # do twice; trimmed seqs should stay trimmed
      list.trimBefore(duckLink)
      list.testList
      assert list.len == 1
    
    let cnt = rlist.delete( value => value == "goat")
    assert cnt == 1
    assert rlist.len == 5
    
    let cnt2 = rlist.deleteLink( lnk => lnk.value == "cat" or lnk.value == "dog" )
    assert cnt2 == 2
    assert rlist.len == 3
    list.clear()
    assert list.len == 0
    list.testList()
 
 proc testLinkedList()= # test the topology
    var val : string = nil
    let list = newLinkedList[string]()
    let rlist = newLinkedList[string]()
    testLinks(list, rlist)
    let dlist = newDoubleLinkedList[string]()
    let rdlist = newDoubleLinkedList[string]()
    testLinks(dlist, rdlist)
    
    let
      list1 = newDoubleLinkedList("mouse")
      list2 = newDoubleLinkedList[string]()
      tup : tuple[x:int, y : int] = (0,0)
      #list4 = newLinkedList(tup)
    assert list1.len == 1
    assert list2.len == 0
    
    # Run the examples in the docs:
    block:
      let
        singleList = newLinkedList[string]()
        doubleList = newDoubleLinkedList[int]()
      assert singleList.newLink("mouse") of Link[string]
      assert doubleList.newLink(1) of DoubleLink[int]
    block:
      let list = newLinkedList("mouse", "cat", "dog")
      assert list.len == 3
    block:
      let
        animalSeqs = @["cat", "dog", "mouse", "duck", "goat", "rat"]
        list = newLinkedList[string](animalSeqs[0..animalSeqs.high])
      let duckLink = list.findFirst("duck")
      assert list.len == 6

      list.trimAfter(duckLink)
      assert list.len == 4
      assert list.tail == duckLink
      assert list.head.value == "cat"

      let dogLink = list.findFirst("dog")
      list.trimBefore(dogLink)
      assert list.len == 3
      assert list.tail == duckLink
      assert list.head == dogLink
    block:
      let
        list = newLinkedList[string]()
        animalSeqs = @["cat", "dog", "mouse", "duck", "goat", "rat"]
      for s in animalSeqs:
        list.append(s)
      var i = 0
      for v in list.values:
        assert v == animalSeqs[i]
        inc i
    block:
      let
        list = newLinkedList[string]()
        animalSeqs = @["cat", "dog", "mouse", "duck", "goat", "rat"]
      for s in animalSeqs:
        list.prepend(s)
      var i = animalSeqs.high
      for v in list.values:
        assert v == animalSeqs[i]
        dec i
    block:
      let
        list1 = newLinkedList("mouse", "cat", "dog")
        list2 = newLinkedList[string]()
      assert list1.len == 3
      assert list2.len == 0
    block:
      let
        list1 = newDoubleLinkedList("mouse", "dog")
        list2 = newDoubleLinkedList[string]()
      assert list1.len == 2
      assert list2.len == 0
    block:
      let list = newDoubleLinkedList("big", "small")
      assert list.insertBeforeHere(list.newLink("medium"),
                                   link => link.value == "small")
      assert list.len == 3
      assert list.head.value == "big"
      assert list.head.next.value == "medium"
      assert list.tail.value == "small"
    block:
      let list = newDoubleLinkedList("big", "small")
      assert list.insertBeforeHere("medium",(value :string)=> value == "small")
      assert list.len == 3
      assert list.head.value == "big"
      assert list.head.next.value == "medium"
      assert list.tail.value == "small"
    block:
      let list = newLinkedList("big", "small")
      assert list.insertBeforeValue("medium","small")
      assert list.len == 3
      assert list.head.value == "big"
      assert list.head.next.value == "medium"
      assert list.tail.value == "small"
    block:
      let list = newDoubleLinkedList("bird", "cat", "bear", "mouse")
      let found = list.findAll((link:Link[string])=> link.value[0] == 'b')
      assert found.len == 2
      assert found.head.value == "bird"
      assert found.tail.value == "bear"
    block:
      let list = newDoubleLinkedList("bird", "cat", "bear", "mouse")
      let found = list.findAll((value:string)=> value[0] == 'b')
      assert found.len == 2
      assert found.head.value == "bird"
      assert found.tail.value == "bear"
    block:
      let list = newLinkedList[int]()
      let underdogs = newLinkedList[int]()
      for i in 1..100:
          list.append(i*i mod 100)
      assert list.len == 100
      let removed = list.deleteLink(
         (link:Link[int])=> link.value < 50,
         (link:Link[int])=> underdogs.insertAfter(link,underdogs.tail))
      assert removed + list.len == 100
      assert removed == underdogs.len
    block:
      let list = newLinkedList[int]()
      for i in 1..100:
          list.append(i*i mod 100)
      assert list.len == 100
      let removed = list.deleteLink( link => link.value < 50)
      assert removed + list.len == 100
    block:
      let list = newLinkedList[int]()
      var recovered : seq[int] = @[]
      for i in 1..100:
          list.append(i*i mod 100)
      assert list.len == 100
      let removed = list.delete((val:int)=> val < 50, (val:int)=> recovered.add(val))
      assert removed + list.len == 100
      assert removed == recovered.len
      assert removed > 0
    block:
      let list = newLinkedList[int]()
      for i in 1..100:
          list.append(i*i mod 100)
      assert list.len == 100
      let underdogs = list.extractLink( (link:Link[int]) => link.value < 50)
      assert underdogs.len + list.len == 100
      for i in underdogs.values:
          assert i < 50
      for i in list.values:
          assert i >= 50
    block:
       let list = newLinkedList[int]()
       for i in 1..100:
          list.append(i*i mod 100)
       assert list.len == 100
       let underdogs = list.extract( (t :int) => t < 50)
       assert underdogs.len + list.len == 100
       for i in underdogs.values:
          assert i < 50
       for i in list.values:
          assert i >= 50

 testLinkedList()
