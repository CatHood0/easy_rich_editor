# Paths

Paths is the way on we refers to the list of indexes that are used to access fastly 
to a Node.

A `Path` is tipically normalized. 

**What means that?** 

We refer to "normalized" as the objects that have an order of priority, 
being the first element the root node that contains this node, and the last
index, is the element.

It's too simple when you think about it. Just take a look over this `Tree`:

```console
Root:
|  Paragraph:
|   |  Line
|   |  Line
|   |_ Line
|      |   Text: 'Simple text. '
|      |_  Text: 'Another simple text'
|
|_ Paragraph:
    |
    |_ Line
```

Assumes that you want the Node that contains the text `'Another simple text'`. To get that node,
you just need to create a `Path` like this one:

```dart
[
  0, // the index of the first paragraph
  2, // the index of the last line
  1, // the index of the text node
]
```

## How query nodes using paths

## How create a path
