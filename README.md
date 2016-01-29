# listsv
A Nim language module that implements singly and doubly linked lists with features including insertions, 
finding, deleting, extracting, and forward and reverse iterators.

The source code includes tests and examples. Html docs for the module can be generated using the nim doc command.

LinkedList types are assigned to having single or double links on creation, and some procs fields are set in the LinkedList object to produce the correct behavior without the overhead and problems with generics and dynamic method dispatching. All procs works for both singly and doulby linked lists but the programmer should be aware that procs requiring reverse transversal through the links are more efficient for doubly linked lists. For example:
```
import listsv, future
let # Both of these are type LinkedList[int]
  singleList = createLinkedList[int](ltSingle)
  doubleList = createLinkedList[int](ltDouble)
  
# But generates different Link types
assert singleList.newLink(1) of Link[int]
assert doubleList.newLink(1) of DoubleLink[int]
```

For test purposes define a type "birdScore" to be the value type for 
the linked list, and create an array of example birdScores:
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

This makes an empty doubly linked list and then collects the highest 5 scores into the list:
```
let doubleScores = newDoubleLinkedList[birdScore]()
# Collects a LinkedList of the 5 highest scoring birdScores sorted high to low
for s in scores:
   let ok = doubleScores.insertBeforeHere(s, t => t.score < s.score)
   if not ok:
      doubleScores.append(s)
   if doubleScores.len >= 5:
      doubleScores.remove(doubleScores.tail)
      
echo "Double Scores: " , $doubleScores, " len " , doubleScores.len
```
The above code block also works for singly linked lists, but the 'insertBeforeHere' procedure is inherently slow for a single list list; it needs to scan the list from the beginning to find the upstream link.

The next code block does the same job but is more efficient for singly linked lists since it only uses "prepend" and "insertAfter", both of which are efficient for singly and doubly linked lists:
```
let singleScores = newLinkedList[birdScore]()
for s in scores:
   if singleScores.head != nil and singleScores.head.value.score < s.score :
         singleScores.prepend(s)
   elif not singleScores.insertAfterHere(
                singleScores.newLink(s),  
                link => link.next != nil and link.next.value.score < s.score):
      singleScores.append(s)
   if singleScores.len >= maxScores:
      singleScores.remove(singleScores.tail)
      
echo "Single Scores: " , $singleScores, " len " , singleScores.len
```
Links for both types can be extracted into new lists without creating new link objects and refs, thus avoiding GC overhead, can be done with the "extract" proc:

```
# It turns out that every team whose name's second letter is 'a' 
# has been found guilt of deflated the game ball.
# The cheaters must be removed fromm the list!
let cheaters = singleScores.extract( t => t.name[1] == 'a')

echo "cheaters: " , $cheaters
echo "clean Scores: " , $singleScores
echo "Winners are the " , singleScores.head.value.name, "!"
```
The output of all of the above code blocks combined is :
```
Double Scores: {(score: 4.8, name: Falcons), (score: 4.5, name: Hawks), (score: 3.2, name: Juncos), (score: 2.5, name: Gulls)} len 4
Single Scores: [(score: 4.8, name: Falcons), (score: 4.5, name: Hawks), (score: 3.2, name: Juncos), (score: 2.5, name: Gulls)] len 4
cheaters: [(score: 4.8, name: Falcons), (score: 4.5, name: Hawks)]
clean Scores: [(score: 3.2, name: Juncos), (score: 2.5, name: Gulls)]
Winners are the Juncos!
```





