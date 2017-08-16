cimport cython
__version__ = "0.0.1"


# Important: do not override tp_clear because we will explicitly
# unref members of __dict__ in order during the dealloc.
@cython.no_gc_clear
cdef class orderedobject:
    """ A base class for objects whose attributes
        are unreferenced by the reverse of the order they are defined.

        An orderedobject is likely not GC friendly. Avoid cyclic references involving
        orderedobject.

        Notes:

        orderedobject is most useful to when the life cycle of a resource
        is managed with the life cycle of an object.

        In Python we are usually recommended to use contexts managers to
        decouple the life cycle of a short-living resource; even though the
        original purpose of context managers was to gracefully handle exceptions
        during the locking / owning of such resources.

        In some scenarios, the life cycle of a resource can be quite long. For
        example, the life cycle of a FFTW plan can be much longer than a simple
        code segment, for it is reused many times. In addition, in a parallel
        application the FFTW `plan` must be destroyed collectively, or the
        behavior of the application becomes undefined. This is when deriving
        from orderedobject becomes useful.

        -- look at
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

    def __dir__(self):
        return sorted(object.__dir__(self))

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
@cython.no_gc_clear
cdef class ordereddict(dict):
    """ A dictionary that dereferences its members in the order
        that they are added.

        ordereddict is likely not GC friendly. Avoid cyclic references.
    """
    # FIXME: this only provides a subset of collections.OrderedDict.

    cdef list __order__

    def __cinit__(self):
        self.__order__ = []

    def __setitem__(self, name, value):
        if name not in self:
            self.__order__.append(name)
        dict.__setitem__(self, name, value)

    def __iter__(self):
        for i in self.__order__:
            yield i

    def keys(self):
        return self.__order__

    def values(self):
        return [self[k] for k in self.__order__]

    def items(self):
        return [(k, self[k]) for k in self.__order__]

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

@cython.no_gc
@cython.no_gc_clear
cdef class OrderedClass(type):
    """ A metaclass for classes that dereferences class members are in
        a consistent order. (currently the reverse of the order they are defined).

        This does not yet work due to https://github.com/cython/cython/issues/1821.

        This does not apply to the instance members.

        OrderedClass is likely not GC friendly. Avoid cyclic references. In general
        avoid holding long living resources in a class as a static member in the
        design might be a good idea. Classes shall be less fluidy than objects.

        This is stolen from

        https://docs.python.org/3/reference/datamodel.html#metaclass-example

        We replace the dictionary of the class during type construction an
        ordereddict().

        Warning:

        The destruction order of attributes added out side of the class scope
        is still undeterministic. This is because only members defined inside
        of the class scope are stored in the dictionary created by `__prepare__`.

    """
    cdef list __attrorder__

    @classmethod
    def __prepare__(metacls, name, bases, **kwds):
        raise RuntimeError("This does not work due to a potential bug or special feature of Cython.")
        return ordereddict()

    #def __new__(cls, name, bases, namespace, **kwds):
    #    result = type.__new__(cls, name, bases, dict(namespace))
    #    return result
    def __cinit__(self, name, bases, ordereddict namespace, **kwds):
        self.__attrorder__ = list()
        self.__attrorder__.extend(namespace.__order__)

    def __dealloc__(self):
        print('dealloc', self.__attrorder__, self.__dict__)
        for key in reversed(self.__attrorder__):
            self.__dict__.pop(key)
