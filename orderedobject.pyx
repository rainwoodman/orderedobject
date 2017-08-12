cimport cython
__version__ = "0.0.0"

# do not prepend tp_clear because we will use these objects
# during destruction. 

@cython.no_gc_clear
cdef class orderedobject:
    """ An object whose attributes are unreferenced by the reversed order they are attached.

        orderedobject is most useful to manage life cycle of resources with the object
        life cycles. In Python these are usually decoupled -- and hence contexts managers
        are usually recommended. However there are cases when the life cycle of resources
        is much longer than a single code segment, and in those cases it feels more natural
        to manage resource life cycle with the object life cycle -- which has been
        a prominent programming model in traditional programming languages like C -- look at
        the stdio API .. fclose and fopen does both memory and resource management!

    """
    cdef dict __dict__
    cdef list __attrorder__
    cdef object __weakref__
    def __cinit__(self):
        self.__dict__ = dict()
        self.__attrorder__ = []

    def __setattr__(self, name, value):
        if name not in self.__dict__:
            self.__attrorder__.append(name)
        self.__dict__[name] = value

    def __delattr__(self, name):
        if name in self.__dict__:
            self.__attrorder__.remove(name)
        self.__dict__.pop(name)

    def __dealloc__(self):
        # ensure ordered destruction of members
        # print("destruction order", self.__attrorder__)
        for key in reversed(self.__attrorder__):
            self.__dict__.pop(key)

    def __reduce__(self):
        return unpickle_object, (self.__dict__, self.__attrorder__)

def unpickle_object(dict, attrorder):
    cdef orderedobject obj = orderedobject()
    obj.__dict__.update(dict)
    obj.__attrorder__.extend(attrorder)
    return obj


# -----------
# From here and below things shall be used with more care ...
#
cdef class ordereddict(dict):
    """ the important feature is reversed destruction order. """
    # FIXME: this only provides a subset of collections.OrderedDict.

    cdef list __order__

    def __cinit__(self):
        self.__order__ = []

    def __setitem__(self, name, value):
        if name not in self:
            self.__order__.append(name)
        dict.__setitem__(self, name, value)

    def __delitem__(self, name):
        if name in self:
            self.__order__.remove(name)
        dict.__delitem__(self, name)

    def __dealloc__(self):
        for key in reversed(self.__order__):
            self.pop(key)

    def __reduce__(self):
        return unpickle_dict, (dict(self), self.__order__)


def unpickle_dict(dict, order):
    cdef ordereddict obj = ordereddict()
    for i in order:
        obj[i] = dict[i]
    return obj

@cython.no_gc_clear
#@cython.no_gc
cdef class OrderedClass(type):
    """ This is stolen from
        https://docs.python.org/3/reference/datamodel.html#metaclass-example

        We replace the dictionary of the class during type construction with
    """
    cdef list __attrorder__

    # FIXME: This doesn't work if attributes are attached later.
    # managing life cycles of resources with classes is a bad idea anyways.
    @classmethod
    def __prepare__(metacls, name, bases, **kwds):
        return ordereddict()

    #def __new__(cls, name, bases, namespace, **kwds):
    #    result = type.__new__(cls, name, bases, dict(namespace))
    #    return result
    def __cinit__(self, name, bases, ordereddict namespace, **kwds):
        self.__attrorder__ = list()
        self.__attrorder__.extend(namespace.__order__)

    def __dealloc__(self):
        print('dealloc', self.__attrorder__)
        for key in reversed(self.__attrorder__):
            self.__dict__.pop(key)
