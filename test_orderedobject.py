from orderedobject import orderedobject
from orderedobject import OrderedClass

import gc
from weakref import proxy

class O(object):
    pass

def make_removable(name, list, weakholder):
    obj = O()

    def callback(ref, name=name, list=list):
        list.append(name)

    weakholder.append(proxy(obj, callback))
    return obj

def test_orderedobject():
    gc.collect()

    o = orderedobject()

    l = []
    w = []
    o.a = make_removable('a', l, w)
    o.b = make_removable('b', l, w)

    print("Before deleting", l)
    del o # trigger deletion
    print("After deleting", l)
    gc.collect() # forcefully with GC.
    print("After gc", l)

    # assert reversed order.
    assert l[0] == 'b'
    assert l[1] == 'a'

def test_pickle():
    import pickle
    o = orderedobject()
    o.a = 100
    o.b = 200
    s = pickle.dumps(o)
    o2 = pickle.loads(s)
    assert o2.a == o.a
    assert o2.b == o.b

def test_orderedclass():
    gc.collect() # forcefully with GC.

    l = []
    w = []
    class A(metaclass=OrderedClass):
        a = make_removable('a', l, w)
        b = make_removable('b', l, w)

    print("Before deleting", l)
#    print(A.__dict__.__order__)
    del A

    print("After deleting", l)
    gc.collect() # forcefully with GC.
    print("After gc", l)

    # assert reversed order.
    assert l[0] == 'b'
    assert l[1] == 'a'
    
