from collections import namedtuple
from random import randint # doesn't seem to work in P3 on Arch :(
from math import sqrt
import os
from io import StringIO
import sys
import subprocess


Node = namedtuple('Node', ['id', 'x', 'y'])
Point = namedtuple('Point', ['x', 'y'])
Segment = namedtuple('Segment', ['hop', 'x0', 'y0', 'x1', 'y1'])
Point = namedtuple('Point', ['x', 'y'])



class Colormap:
    def __init__(self, cwidth, cheight, coarseness = 20,\
                 color_begin = color(0, 80, 100, 100), color_end = color(360, 80, 100, 100)):
        self._width = cwidth
        self._height = cheight
        self._rows = int(cheight/coarseness)+1
        self._cols = int(cwidth/coarseness)+1
        self._coarse = coarseness
        self._color_begin = color_begin
        self._color_end = color_end
        # TODO: linear interpolation
        self._colormap = [[color_begin] * self._rows] * self._cols
        # paint the colormap with a vertical linear gradient
        for row in range(len(self._colormap[0])):
            for col in range(len(self._colormap)):
                self._colormap[col][row] = lerpColor(color_begin, color_end, 1.0*row/len(self._colormap[0]))
        #print self._colormap
        
        
    def __getitem__(self, indxy):
        indcol, indrow = indxy
        #print ":i ", indrow, indcol, indrow/self._coarse, indcol/self._coarse
        return self._colormap[int(indcol/self._coarse)][int(indrow/self._coarse)]
        


class NodeSet:
    
    INFTY = 2**32-1 # 64-bit ints
    
    def __init__(self, x0 = 450, y0 = 300, w = 200, h = 200, num_nodes = 500,\
                      max_hops = 8, coarse = 40):
        self._x0 = x0
        self._y0 = y0
        self._w = w
        self._h = h
        self._nodes = {} # ID -> (x, y)
        self._num_nodes = num_nodes
        self._max_hops = max_hops
        self._distances = {}
        # to avoid collisions in the node ID generation
        self._chosen_ids = set()
        # minimum spanning tree path (list of Points)
        self._path = []
        self._coarse = coarse
        self._colormap = Colormap(900, 600)
        
        
    def __getitem__(self, ind):
        return self._nodes[ind]
 
    @classmethod   
    def _randint(self, max = 2**16-1):
        cmd = 'echo $(( $RANDOM %% %d ))' % max
        out_stream = os.popen(cmd)
        # "R: ", int(out_stream.read())
        return int(out_stream.read())
        
    
    def _key(self, id1, id2):
        return '%s-%s' % (min(int(id1), int(id2)), max(int(id1), int(id2)))
    
    def _create_id(self):
        return self._randint()
    
    def _random_id(self):
        #print "-> ", self._randint()
        #randomSeed(int(random(0, self.INFTY)))
        #ret = random.choice(list(self._nodes.keys()))
        ind = self._randint(len(self._nodes))
        keys_ = [k for k in self._nodes.keys()]
        ret = keys_[ind]
        self._chosen_ids.add(ret)
        return ret
            
    
    def _random_node(self):
        return self._nodes[self._random_id()]
    
    def _get_dist(self, node1, node2):
        return (node1.x - node2.x)**2 + (node1.y - node2.y)**2
    
        
    def create_cloud(self, x0 = 450, y0 = 300, w = 200, h = 200):    
        for _ in range(self._num_nodes):
            # randomGaussian(): mean 0, std of 1, so typically from -2 to 2
            xi = int(x0 + w/4*randomGaussian())//self._coarse * self._coarse
            yi = int(y0 + h/4*randomGaussian())//self._coarse * self._coarse
            newid = self._create_id()
            self._nodes[newid] = Node(newid, xi, yi)
        for id1, n1 in self._nodes.items(): # key: id, value: node
            for id2, n2 in self._nodes.items():
                if n1 != n2: self._distances[self._key(id1, id2)] = self._get_dist(n1,n2)
    
    
    def clear_cloud(self):
        self._nodes = {}
        self._distances = {}
    
    def _add_node(self, newnode):
        newid = newnode.id
        for id1, n1 in self._nodes.items(): # key: id, value: node
            self._distances[self._key(id1, newid)] = self._get_dis(newnode, n1)
        self._nodes[newid] = newnode
        
    def min_tree(self, n_edges = 5, origin = None):
        """origin: either None or (x, y)"""
        ### initialise visited and unvisited sets
        visited = {}
        unvisited = {}
        i=0
        while i < n_edges-1:
            newnode = self._random_node()
            if newnode.id not in unvisited.keys():
                unvisited[newnode.id] = newnode
                i += 1 
         
        node_origin = Node(self._create_id(), *origin)
        self._add_node(node_origin)

        visited[node_origin.id] = node_origin
        #assert( all(\
        #            [uk == suk for uk, suk in zip(unvisited.keys(), set(unvisited.keys()))]\
        #            ))
        
        ret = [Point(node_origin.x, node_origin.y)] # list of Points
        ### like Prim's minimum spanning tree but everything is reachable
        while len(unvisited) != 0:
            for vid, v in visited.items():
                # for each unvisited: find id in unvisited
                # that minimises distance between each visited and all unvisited
                min_dist = self.INFTY
                min_uid = None
                min_node = None
                for uid, u in unvisited.items():
                    if self._get_dist(v, u) < min_dist:
                        min_dist = self._get_dist(v, u)
                        min_uid = uid
                        min_node = u
                ret.append(Point(min_node.x, min_node.y))
                unvisited.pop(min_uid)
                visited[min_uid] = min_node
                if len(unvisited) == 0:
                    break
        # the origin is not part of the original pointcloud
        self._nodes.pop(node_origin.id)
        self._path = ret
        return ret
    
    def draw(self, nodes = True, tree = True, rad = 9, linewidth = 2, colormap = None):
        #print self._path  
        if tree:
            strokeWeight(linewidth)
            for p1, p2 in zip(self._path, self._path[1:]):
                stroke(self._colormap[p1.x, p1.y])
                line(p1.x, p1.y, p2.x, p2.y)
                if nodes:
                    noStroke()
                    fill(self._colormap[p1.x, p1.y])
                    ellipse(p1.x, p1.y, rad, rad)
            if nodes:
                noStroke()
                fill(self._colormap[p1.x, p1.y])
                ellipse(self._path[-1].x, self._path[-1].y, rad, rad)
        
        

def setup():
    size(900,600)
    colorMode(HSB, 360, 100, 100, 100);
    background(0, 0 ,0)
    blendMode(BLEND)
    smooth()
    noLoop()
    #randomSeed(1)
    
    
def draw():
    stroke(0)
    strokeWeight(5)
    coarse = 14
    nodeset = NodeSet(num_nodes = 300, coarse = coarse)
    
    strokeWeight(1)
    stroke(210,100,100,50)
    fill(210,100,100,50)
    nodeset.create_cloud(x0 = 350, y0 = 200, w = 120, h = 130)
    nodeset.create_cloud(x0 = 500, y0 = 350, w = 80, h = 80)
    for _ in range(3):
        nodeset.min_tree(30, (random(200,210)//coarse*coarse,random(200,210)//coarse*coarse))
        nodeset.draw(nodes = True)
    for _ in range(3):
        nodeset.min_tree(30, (random(260,270)//coarse*coarse,random(200,210)//coarse*coarse))
        nodeset.draw(nodes = True)
    for _ in range(3):
        nodeset.min_tree(30, (random(400,450)//20*20,random(300,350)//coarse*coarse))
        nodeset.draw(nodes = True)t
