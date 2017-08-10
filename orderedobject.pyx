cimport cython
__version__ = "0.0.0"

# do not prepend tp_clear because we will use these objects
# during destruction. 
@cython.no_gc_clear
cdef class orderedobject:
    """ An object whose attributes are unreferenced by the order they are attached.
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
        for key in self.__attrorder__:
            self.__dict__.pop(key)

    def __reduce__(self):
        return unpickle, (self.__dict__, self.__attrorder__)

def unpickle(dict, attrorder):
    cdef orderedobject obj = orderedobject()
    obj.__dict__.update(dict)
    obj.__attrorder__.extend(attrorder)
    return obj
