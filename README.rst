orderedobject
=============

Travis-CI Status

.. image:: https://travis-ci.org/rainwoodman/orderedobject.svg?branch=master
    :target: https://travis-ci.org/rainwoodman/orderedobject

.. author:: Yu Feng <rainwoodman@gmail.com>


.. notes::

    These represents my current understanding of MPI and Python at the time of writing.
    Comments and corrections to my opinion / analysis is highly welcomed.

Overview
--------

The `object` class in Python does not guarentee an order deferencing attributes
during the deconstruction of the object.

The base class here, `orderedobject` provides a deterministic order.
Currently the order is the reversed sequence of the creation sequence.

Motivation
----------

The relevance occurs while interacting MPI, a distributed parallel application
where collective behavior is defined and expected cross all instances of the
a communicator.

Here, the word ``deterministic`` is used in a broad, non-strict manner.
The issue is whether the order is only a function of the history of the owner
object. With Python's default `object` class, under the CPython implementation,
the order is determined by the hashing of the underlying `__dict__` object that
provides the storage of the attributes. The hashing is beyond the ower object 
-- its result is controlled by the hashing seed. The situation only gets more
complicated for other implementations.

The most straight forward way of specifying the order of destruction is to derive
an order from the order of construction (e.g. reversed) -- the time sequence when
the attributes are attached to the object. This is how it is implemented in
this `orderedobject` base class.

Uncovered Case
--------------

For parallel applications, we still have difficulty when the life cycle of 
objects itself becomes non-deterministic. This can happen when automated garbage collection
is involved. The object is destroyed only when the garbage collection occurs.
Fortunately in CPython this is only triggered when there is cyclic reference.
We therefore explicitly marked our `orderedobject` non-GC friendly (at least we have
attempted to do so)

Alternatives
------------

For CPython, a similar effect can be achieved by using the same `PYTHONHASHSEED`
environment variable on all processes.

A useful programming paradigm is to ``abandon`` the idea of collective objects.
Instead, replace them with a collective transient state, which is maintained by a `context
manager`, or via a `destroy` method that must be called explicitly. To me, these methods
does not fundamentally solve the problem. They simply push the issue of collective
objects further down stream of the application stack, or mask the difficulty by
making it harder to observe the underlying collective object pattern.


