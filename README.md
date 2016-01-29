# listsv
A Nim language module that implements singly and doubly linked lists with features including insertions, 
finding, deleting, extracting, and forward and reverse iterators.

The source code includes tests and examples. Html docs for the module can be generated using the nim doc command.

LinkedList types are defined as using either single or double links on creation, any procs with different behavoirs between the two are set as proc fields in the LinkedList on creation to produce the correct behavior without overhead or problems of using generics with dynamic method dispatching.

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

All procs works for both singly and doubly linked lists but programmers should be aware that procs requiring reverse transversal through the links are more efficient for doubly linked lists, because singly linked list require iterating from the start of the list to find the upstream link.

For test purposes let's define a type "birdScore" to be the value type for 
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
The aboce fills the allscores list with each birdScore in order. But what if we want to capture only the highest 5 scores?

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
The above code block also works for singly linked lists, but the 'insertBeforeHere' proc is inherently slow for a singly linked list; it needs to scan the list from the beginning to find the upstream link.

The next code block does the same job but is more efficient for singly linked lists since it only uses "prepend" and "insertAfter", both of which are efficient for both singly and doubly linked lists:
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
Links for both types can be extracted into new lists without creating new link objects and refs, thus avoiding GC overhead, using the "extract" proc:

```
# It turns out that every team whose name's second letter is 'a' 
# has been found guilty of deflated the game ball.
# The cheaters must be removed fromm the list!
let cheaters = singleScores.extract( t => t.name[1] == 'a')

echo "Cheaters: " , $cheaters
echo "Clean Scores: " , $singleScores
echo "Winners are the " , singleScores.head.value.name, "!"
```
Output of the above code blocks combined is :
```
Double Scores: {(score: 4.8, name: Falcons), (score: 4.5, name: Hawks), (score: 3.2, name: Juncos), (score: 2.5, name: Gulls)} len 4
Single Scores: [(score: 4.8, name: Falcons), (score: 4.5, name: Hawks), (score: 3.2, name: Juncos), (score: 2.5, name: Gulls)] len 4
Cheaters: [(score: 4.8, name: Falcons), (score: 4.5, name: Hawks)]
Clean Scores: [(score: 3.2, name: Juncos), (score: 2.5, name: Gulls)]
Winners are the Juncos!
```





