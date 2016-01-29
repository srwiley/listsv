# listsv
A Nim language module that implements singly and doubly linked lists with features including insertions, 
finding, deleting, extracting, and forward and reverse iterators.

The source code includes tests and examples. Html docs for the module can be generated using the nim doc command.

LinkedList objects are defined on creation as using either singly (type Link) or doubly (type DoubleLink) linked links. Any procs that differ between the link types are set as proc fields in the LinkedList when instantiated to produce the correct behavior without overhead or problems related to using generics with dynamic method dispatching.

```
import listsv, future

let # Both of these are type LinkedList[int]
  singleList = createLinkedList[int](ltSingle)
  doubleList = createLinkedList[int](ltDouble)
  
# But the newlink proc generates different Link types.
# That is because the newlink proc field in the 
# LinkedList object was set by the createLinkedList
# procedure.
assert singleList.newLink(1) of Link[int]
assert doubleList.newLink(1) of DoubleLink[int]
```

All procs work for both singly and doubly linked lists, but programmers should be aware that procs requiring reverse transversal through the links are more efficient for doubly linked lists, because singly linked lists require searching from the start of the list to find the upstream link.

Here are some examples:

Let's define a type "birdScore" which will be the value type for example linked lists, although basic types such as int would work as well for the value type. Now define an example array of birdScores:
```
type birdScore = tuple[score: float, name :string]
const scores : array[7,birdScore] = 
    [  ( 1.0, "Sparrows"), 
       ( 2.5, "Gulls"), 
       ( 4.5, "Hawks"),
       ( 2.3, "Crows"),
       ( 4.8, "Falcons"),
       ( 1.5, "Jays"),
       ( 3.2, "Juncos")  ]
```

To create and fill a singly linked list with the scores do this:

```
let allscores = newLinkedList(scores[0..scores.high])
```

and this will assert:

```
assert allscores.len == 7
```

The above fills the allscores list with each birdScore in the order of the scores array. But what if we want to capture and sort by the highest 5 scores?

This makes an empty doubly linked list and then collects the highest 5 scores into the list sorted from high to low:

```
let doubleScores = newDoubleLinkedList[birdScore]()
for s in scores:
   let added = doubleScores.insertBeforeHere(s, t => t.score < s.score)
   if doubleScores.len >= 5:
      doubleScores.remove(doubleScores.tail)
   elif not added :
      doubleScores.append(s)
      
echo "Double Scores: " , $doubleScores, " len " , doubleScores.len
```

The above code block also works for singly linked lists, but the 'insertBeforeHere' and 'remove' proc is inherently slow for a singly linked list; it needs to scan the list from the beginning to find the upstream link.

The next code block does the same job but is more efficient for singly linked lists since it only uses procs which are efficient for both singly and doubly linked lists:

```
let singleScores = newLinkedList[birdScore]()
for s in scores:
   var
      added = false
      blink : Link[birdScore] = nil
   if singleScores.head == nil or singleScores.head.value.score < s.score :
      singleScores.prepend(s)
      blink = singleScores.head
      added = true
   else:
      blink = singleScores.newLink(s)
      added = singleScores.insertAfterHere(
                 blink,
                 link => link.next != nil and link.next.value.score < s.score)
   if singleScores.len > 5:
      # Find the link that preceeds the tail
      while blink.next != singleScores.tail:
         blink = blink.next
      discard singleScores.removeNext(blink)
   elif not added:
      singleScores.append(s)
      
echo "Single Scores: " , $singleScores, " len " , singleScores.len
```
Links of both types can be extracted into new lists without creating new link objects and refs, thus avoiding GC overhead, using the "extract" proc:

```
# It turns out that every team whose name's second letter is 'a' 
# has been found guilty of deflating the game ball.
# The cheaters must be removed fromm the list!

let cheaters = singleScores.extract( t => t.name[1] == 'a')
echo "Cheaters: " , $cheaters
echo "Clean Scores: " , $singleScores
echo "Winners are the " , singleScores.head.value.name, "!"
```

Output of the above code blocks combined is:

```
Double Scores: {(score: 4.8, name: Falcons), (score: 4.5, name: Hawks), (score: 3.2, name: Juncos), (score: 2.5, name: Gulls)} len 4
Single Scores: [(score: 4.8, name: Falcons), (score: 4.5, name: Hawks), (score: 3.2, name: Juncos), (score: 2.5, name: Gulls)] len 4
Cheaters: [(score: 4.8, name: Falcons), (score: 4.5, name: Hawks)]
Clean Scores: [(score: 3.2, name: Juncos), (score: 2.5, name: Gulls)]
Winners are the Juncos!
```





