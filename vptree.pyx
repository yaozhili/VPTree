#distutils : language = c++
#distutils : sources = VPTree.cpp

from vptree cimport VPTree
from vptree cimport Distance
from vptree cimport Point

cimport numpy as np

from cython.operator cimport dereference

cdef class PyVPTree:
    cdef VPTree *vptree
    cdef Distance *gcd
    cdef vector[shared_ptr[Point]]* points

    def __cinit__(self):
        self.vptree = new VPTree()
        self.points = new vector[shared_ptr[Point]]()
        
    def buildPointsVector(self,np.float64_t latitude,np.float64_t longitude):

        cdef shared_ptr[Point] point
        point = shared_ptr[Point](new SphericalPoint())
        dereference(point).setCoordinate1(latitude)
        dereference(point).setCoordinate2(longitude)
        self.points.push_back(point)
        
    cdef initializePoints(self):
        self.vptree.initializeVPTreePoints(self.points)
    
        
    def initializeGreatCircleDistance(self):
        self.gcd = new GreatCircleDistance()
        self.vptree.initializeDistance(self.gcd)

    def getAllInRange(self,double latitude,double longitude,double maxDistance):
        cdef shared_ptr[Point] point
        cdef vector[pair[double,shared_ptr[Point]]] vec
        point = shared_ptr[Point](new SphericalPoint())
        dereference(point).setCoordinate1(latitude)
        dereference(point).setCoordinate2(longitude)
        vec = self.vptree.getAllInRange(point,maxDistance)
        
        
    def __dealloc__(self):
        if self.vptree != NULL:
            del self.vptree
