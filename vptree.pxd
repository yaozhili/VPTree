from libcpp.deque cimport deque
from libcpp.pair cimport pair


cdef extern from "VPTree.h":
    cdef cppclass VPTree:
       VPTree() nogil except +
       deque[pair[double,Point]] getAllInRange(Point point,double maxDistance) nogil
       void initializeVPTreePoints(deque[Point] points) nogil
       void initializeDistance(Distance *distance) nogil
       
cdef extern from "Distance.h" :
    cdef cppclass Distance:
       Distance() except +
       double calculateDistance(Point point1,Point point2)	
    cdef cppclass GreatCircleDistance(Distance):
       GreatCircleDistance() except +
       double calculateDistance(Point point1,Point point2)
											

cdef extern from "Point.h":
    cdef cppclass Point:
       Point() except +
       double getCoordinate1()
       double getCoordinate2()
       void setCoordinate1(double coordinate1)
       void setCoordinate2(double coordinate2)
       
    cdef cppclass SphericalPoint(Point):
       SphericalPoint() except +
       double getCoordinate1()
       double getCoordinate2()
       void setCoordinate1(double lat)
       void setCoordinate2(double lon)
