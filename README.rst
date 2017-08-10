The destruction of object attributes in Python is nondeterministic. The base
class here, `orderedobject` provides a deterministic destruction order.

Here, the word ``deterministic`` is used in a broad, non-strict manner.
If the full state of the intepreter is known, the destruction order in principle
is deterministic. 
In this context, however, the issue is whether it is manifestly controlled by
the owner of the attributes, namely, the object.

We still may desire a particular order of attribute destruction. For example,
in a parallel application the attribute may refer to some collectively owned
resources that must be collectively destructed with matched parallel function
calls. MPI.Comm is a particularly notable one -- the implementation in
SGI MPT appears to requite a collective destruction or will hang.

The most straight forward way of specifying the order of destruction is to derive
an order from the order of construction (e.g. reversed) --
the time sequence when the attributes are attached to the object.

 There must be other ways to specify an order,
but they are probably of less practical usefulness; one particular interesting one
is via name. Again the key is deterministic-ness of the destruction.

A quick hack with Python serves as a workaround for a parallel application.
The order of destruction of a dictionary is determined by the variable `PYTHONHASHSEED`.
By requiring all processes in a parallel application to use the same `PYTHONHASHSEED`,
the order becomes deterministic at least for CPython.

Still, the destruction of objects is nondeterministic in CPython when there is cyclic
reference. We shall avoid cycles when deterministic resource management is involved.

A useful programming paradigm that even works with the garbage collection is involved,
is to widely use context manager or to explicitly use `destroy` methods. These approaches
effectively creates another reference management system in parallel to that of the
hosting Python language. This is almost certainly a preferred way to manage short living
resource handles, such as a `File` or perhaps a `DatabaseConnection`. Nevertheless 
we miss all of the benefits of automatic reference management of the language. 

-- How many `DatabaseConnectionManager` will we write and rewrite just to make a pool of `destroy`
methods?

