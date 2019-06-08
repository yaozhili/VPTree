# distutils: language = c++
#
import sys
import time
import numpy as np
cimport numpy as np

cimport cython

import psutil
from concurrent.futures import ThreadPoolExecutor

from libc.stdio cimport printf
from libcpp.memory cimport shared_ptr,unique_ptr,make_shared,make_unique,dynamic_pointer_cast
from libcpp.vector cimport vector
from libcpp.deque cimport deque
from libcpp.pair cimport pair
from libcpp.list cimport list

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
    cdef int number_of_processors

    def __cinit__(self):
        self.vptree = new VPTree()
        self.points = deque[Point]()
        self.number_of_processors = cpu_count()
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
        args = ((chunk,maxDistance))
        results = x.map(self.getNeighborsInRangeChunk, args)
        t1 = time.time()
        print(t1-t0)
        return results

    def getNeighborsInRangeChunk(self,np.ndarray[np.float64_t,ndim=2] gridPoints,np.float64_t maxDistance):
        accumulatedResult = []
        for i in range(0,len(gridPoints)):
            result = self.getNeighborsInRangeForSingleQueryPoint(gridPoints[i],maxDistance)
            accumulatedResult.append(result)
        return accumulatedResult

    def getNeighborsInRangeForSingleQueryPoint(self,np.ndarray[np.float64_t,ndim=1] qpoint, np.float64_t maxDistance)  :
        cdef deque[pair[double,Point]] deq
        cdef SphericalPoint spoint
        cdef Point point
        spoint = SphericalPoint()
        point = <Point>spoint
        point.setCoordinate1(qpoint[0])
        point.setCoordinate2(qpoint[1])
        deq = self.vptree.getAllInRange(point,maxDistance)
        cdef deque[pair[double,Point]].iterator it = deq.begin()
        result = []
        while it != deq.end():
            distance = dereference(it).first
            p = dereference(it).second
            lat = p.getCoordinate1()
            lon = p.getCoordinate2()
            p1 = np.c_[lat,lon]
            inc(it)
            result.append(tuple((distance,p1)))
        return result

        
    def __dealloc__(self):
        if self.vptree != NULL:
            del self.vptree
