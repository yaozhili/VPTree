# distutils: language = c++
#
import sys
import time
import numpy as np
cimport numpy as np

cimport cython

import psutil
from concurrent.futures import ThreadPoolExecutor
from functools import partial

from libc.stdio cimport printf
from libcpp.deque cimport deque
from libcpp.vector cimport vector
from libcpp.pair cimport pair

from cython.operator cimport dereference
from cython.operator cimport postincrement as inc

from vptree cimport VPTree
from vptree cimport Distance
from vptree cimport Point
from vptree cimport SphericalPoint
from vptree cimport GreatCircleDistance


cdef class PyVPTree:
    cdef VPTree *vptree
    cdef deque[Point] points
    cdef Distance *gcd

    def __cinit__(self):
        self.vptree = new VPTree()
        self.points = deque[Point]()

    def initializeGreatCircleDistance(self):

        self.gcd = new GreatCircleDistance()
        self.vptree.initializeDistance(self.gcd)
        
    def buildPointsVector(self,np.ndarray[np.float64_t,ndim=2] points):

        cdef SphericalPoint spoint
        cdef Point point
        for i in range(0,len(points)):
            spoint = SphericalPoint()
            point = <Point>spoint
            point.setCoordinate1(points[i,0])
            point.setCoordinate2(points[i,1])
            #printf("%f\t%f\n",point.getCoordinate1(),point.getCoordinate2())
            self.points.push_back(point)

    def initializePoints(self):
        self.vptree.initializeVPTreePoints(self.points)
    
    def getNeighborsInRange(self,np.ndarray[np.float64_t,ndim=2] gridPoints,np.float64_t maxDistance):

        number_of_processors = psutil.cpu_count(logical=False)
        chunk = np.array_split(gridPoints,number_of_processors,axis=0)
        x = ThreadPoolExecutor(max_workers=number_of_processors) 
        t0 = time.time()
        print(t0)
        func = partial(self.getNeighborsInRangeChunk,maxDistance)
        results = x.map(func,chunk)
        t1 = time.time()
        print(t1)
        print(t1-t0)
        return results

    def getNeighborsInRangeChunk(self,np.float64_t maxDistance,np.ndarray[np.float64_t,ndim=2] gridPoints):


        cdef deque[pair[double,Point]] deq1
        cdef double[:,:] gPoints
        cdef double distance
        cdef Point p
        cdef deque[deque[pair[double,Point]]] collectionOfDeq = deque[deque[pair[double,Point]]]()
        cdef deque[deque[pair[double,Point]]].iterator it
        cdef deque[pair[double,Point]].iterator it2
        gPoints = memoryview(gridPoints)
        resultList = []
        with nogil:
            for i in range(gPoints.shape[0]):
                collectionOfDeq.push_back(self.getNeighborsInRangeForSingleQueryPoint(gPoints[i],maxDistance))

        it = collectionOfDeq.begin()
        while it != collectionOfDeq.end():
            deq1 = dereference(it)
            result = []  
            it2 = deq1.begin()
            while it2 != deq1.end():
                distance = dereference(it2).first
                p = dereference(it2).second
                p1 = np.array([p.getCoordinate1(),p.getCoordinate2()])
                d = <float>distance
                print("The value of p is",p1)
                result.append(tuple((d,p1)))
                inc(it2)
            resultList.append(result)
            inc(it)
        return resultList

    @cython.boundscheck(True)
    cdef deque[pair[double,Point]] getNeighborsInRangeForSingleQueryPoint(self,double[:] qpoint, double  maxDistance) nogil :
        cdef deque[pair[double,Point]] deq
        cdef SphericalPoint spoint
        cdef Point point

        spoint = SphericalPoint() 
        point = <Point>spoint
        point.setCoordinate1(qpoint[0])
        point.setCoordinate2(qpoint[1])
        return move(self.vptree.getAllInRange(point,maxDistance))

        
    def __dealloc__(self):
        if self.vptree != NULL:
            del self.vptree
