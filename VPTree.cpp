#include <iostream>
#include <exception>
#include <limits>
#include <fstream>
#include <deque>
#include <list>
#include <boost/optional.hpp>
#include <boost/range/combine.hpp>
#include <typeinfo>
#include <memory>
#include "VPTree.h"

using namespace std;
using std::vector;
using std::deque;

void VPTree::initializeDistance(Distance *pfunc)
{
  distance = pfunc;
}

void VPTree::initializeVPTreePoints(deque<shared_ptr<Point>> points)
{
  left = nullptr;
  right = nullptr;
  double inf = numeric_limits<double>::max();
  left_min = inf;
  left_max = 0;
  right_min = inf;
  right_max = 0;


  vp = points.front();
  points.pop_front();

  if (points.size() == 0)
    {
      return;
    }
  deque<shared_ptr<Point>>::iterator it;
  deque<double> distances;
  try
    {
      for (it = points.begin();it != points.end();++it)
	{
	  double d;
	  shared_ptr<Point> point = *it;
	  d = distance->calculateDistance(vp,point);
	  distances.push_front(d);
	}
    }
  catch (const std::out_of_range& oor)
    {
      std::cerr <<"Out of Range error: " << oor.what() << endl;
      exit(0);
    }
  double median = _findMedian(distances);
  deque<shared_ptr<Point>> left_points,right_points;
  try
    {
      for (auto tup: boost::combine(points,distances))
	{
	  shared_ptr<Point> point;
	  double dist;
	  boost::tie(point,dist) = tup;
	  if (dist >= median)
	    {
	      right_min = std::min(dist,right_min);
	      if (dist > right_max)
		{
		  right_max = dist;
		  right_points.push_front(point);
		}
	      else
		{
		  right_points.push_back(point);
		}
	    }
	  else
	    {
	      left_min = min(dist,left_min);
	      if (dist > left_max)
		{
		  left_max = dist;
		  left_points.push_front(point);
		}
	      else
		{
		  left_points.push_back(point);
		}
	    }
	}
    }
  catch (const std::out_of_range& oor)
    {
      std::cerr <<"Out of Range error: " << oor.what() << endl;
    }

  if (left_points.size() > 0)
    {
      left = std::make_shared<VPTree>();
      left->initializeDistance(distance);
      left->initializeVPTreePoints(left_points);

    }
  if (right_points.size() > 0)
    {
      right = std::make_shared<VPTree>();
      right->initializeDistance(distance);
      right->initializeVPTreePoints(right_points);
    }
}

bool VPTree::_isLeaf()
{
  if (left == nullptr and right == nullptr)
    {
      return true;
    }
  else
    {
      return false;
    }
}

double VPTree::_findMedian(deque<double>distances) 
{ 
  
  size_t size = distances.size();
  
  if (size == 0)
    {
      return 0;
    }
  else
    {
  // First we sort the array 
      sort(distances.begin(),distances.end()); 
      
      if (size % 2 == 0)
	{
	  return (distances[size/2 -1] + distances[size/2])/2;
	}
      else
	{
	  return distances[size/2];
	} 
    }
}
  
vector<pair<double,shared_ptr<Point>>> VPTree::getAllInRange(shared_ptr<Point> query, double maxDistance)
{
  vector<pair<double,shared_ptr<Point>>> neighbors;
  vector<pair<shared_ptr<VPTree>,double>> nodes_to_visit;
  shared_ptr<VPTree> node;
  double d0;
  node = shared_ptr<VPTree>(this);
  nodes_to_visit.push_back(make_pair(node,0));

  while (nodes_to_visit.size() > 0 )
    {
      auto it  = nodes_to_visit.end();
      node = it->first;
      d0 = it->second;
      if (node == nullptr or d0 > maxDistance)
	continue;
      shared_ptr<Point> point = node->vp;

      double dist = distance->calculateDistance(query,point);
      if (dist < maxDistance)
	neighbors.push_back(make_pair(dist,node->vp));
      
      if (node->_isLeaf())
	continue;
      if (node->left_min <= dist && dist <= node->left_max)
	{
	  nodes_to_visit.insert(nodes_to_visit.begin(),make_pair(node->left,0));
	}
      else if (node->left_min-maxDistance <= dist && dist <= node->left_max + maxDistance )
	{
	  double dd;
	  if (dist < node->left_min)
	    dd = node->left_min - dist;
	  else
	    dd = dist - node->left_max;
	  nodes_to_visit.push_back(make_pair(node->left,dd));
	}
      if (node->right_min <= dist && dist <= node->right_max)
	{
	  nodes_to_visit.insert(nodes_to_visit.begin(),make_pair(node->right,0));
	}
      else if (node->right_min-maxDistance <= dist && dist <= node->right_max + maxDistance )
	{
	  double dd;
	  if (dist < node->right_min)
	    dd = node->right_min - dist;
	  else
	    dd = dist - node->right_max;
	  nodes_to_visit.push_back(make_pair(node->right,dd));
	}
      
    }	     
  return neighbors;
}

int main()
{
  return 0;
}
  
