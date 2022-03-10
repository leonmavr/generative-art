from collections import namedtuple
from random import randint # doesn't seem to work in P3 on Arch :(
from math import sqrt
import os
from io import StringIO
import sys
import subprocess


Node = namedtuple('Node', ['id', 'x', 'y'])
Point = namedtuple('Point', ['x', 'y'])


        
def hex2col(hexstr):
    return color(int(hexstr[:2], 16), int(hexstr[2:4], 16), int(hexstr[4:6], 16), int(hexstr[6:], 16))


class Colormap:
    def __init__(self, cwidth, cheight, coarseness = 20,\
                 color_begin = color(255, 0, 0), color_end = color(0, 0, 0)):
        self._width = cwidth
        self._height = cheight
        self._rows = int(cheight/coarseness)+1
        self._cols = int(cwidth/coarseness)+1
        self._coarse = coarseness
        self._color_begin = color_begin
        self._color_end = color_end
        # TODO: rename
        self._colormap = [[color_begin] * self._rows] * self._cols
        # paint the colormap with a horizontal linear gradient
        for row in range(len(self._colormap[0])):
            for col in range(len(self._colormap)):
                self._colormap[col][row] = lerpColor(color_begin, color_end, 1.0*row/len(self._colormap[0]))
        
        
    def __getitem__(self, indxy):
        indcol, indrow = indxy
        try:
            return self._colormap[int(indcol/self._coarse)][int(indrow/self._coarse)]
        except:
            return lerpColor(self._color_begin, self._color_end, 0.5)


class NodeSet:
    INFTY = 2**32-1 # 64-bit ints
    
    def __init__(self, x0 = 450, y0 = 300, w = 200, h = 200, nodes_per_cloud = 80,\
                coarse = 40, color_begin = color(unhex('ff0000')), color_end = color(unhex('333333')),
                rattling = 0):
        self._x0 = x0
        self._y0 = y0
        self._w = w
        self._h = h
        self._nodes = {} # ID -> (x, y)
        self._num_nodes = nodes_per_cloud
        self._distances = {} # ID1-ID2 -> float
        # to avoid collisions in the node ID generation
        self._chosen_ids = set()
        # minimum spanning tree path (list of Points)
        self._path = []
        self._coarse = coarse
        self._colormap = Colormap(width, height, coarse,
                                  color_begin = color_begin, color_end = color_end )
        self._median_dist = None # to be updated every time ._nodes is changed
        self._rattling = rattling
        
        
    def __getitem__(self, ind):
        return self._nodes[ind]
 
    @classmethod   
    def _randint(self, max = 2**32-1):
        cmd = 'echo $(( $RANDOM %% %d ))' % max
        out_stream = os.popen(cmd)
        return int(out_stream.read())
        
    
    def _key(self, id1, id2):
        return '%s-%s' % (min(int(id1), int(id2)), max(int(id1), int(id2)))
    
    def _create_id(self):
        return self._randint()
    
    def _random_id(self):
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
        dists = self._distances.values()
        self._median_dist = sort(dists)[int(round(len(dists)/2))]
        print "med: ", self._median_dist
        #print self._median_dist
    
    
    def clear_cloud(self):
        self._nodes = {}
        self._distances = {}
        self._median_dist = None
    
    def _add_node(self, newnode):
        newid = newnode.id
        for id1, n1 in self._nodes.items(): # key: id, value: node
            self._distances[self._key(id1, newid)] = self._get_dist(newnode, n1)
        self._nodes[newid] = newnode
        # TODO: update median distance?
        
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
        ### Prim's minimum spanning tree - use the median distance to determine reachability
        are_reachable = lambda node1, node2: self._get_dist(v, u) < self._median_dist
        are_reachable = lambda node1, node2: True
        while len(unvisited) != 0:
            for vid, v in visited.items():
                # for each unvisited: find id in unvisited
                # that minimises distance between each visited and all unvisited
                min_dist = self.INFTY
                min_uid = None
                min_node = None
                for uid, u in unvisited.items():
                    if self._get_dist(v, u) < min_dist and are_reachable(u, v):
                        min_dist = self._get_dist(v, u)
                        min_uid = uid
                        min_node = u
                if min_node is None:
                    continue
                ret.append(Point(min_node.x, min_node.y))
                unvisited.pop(min_uid)
                visited[min_uid] = min_node
                if len(unvisited) == 0 or all([not are_reachable(u, v) for _, u in unvisited.items()]):
                    break
        # the origin is not part of the original pointcloud
        self._nodes.pop(node_origin.id)
        self._path = ret
        return ret
    
    def draw(self, nodes = True, tree = True, rad = 6, linewidth = 2, colormap = None):
        if tree:
            strokeWeight(linewidth)
            for p1, p2 in zip(self._path, self._path[1:]):
                stroke(self._colormap[p1.x, p1.y])
                r = self._rattling
                if r == 0:
                    line(p1.x, p1.y,p2.x , p2.y)
                else:
                    line(p1.x + random(-r, r), p1.y + random(-r, r) ,p2.x + random(-r, r) , p2.y + random(-r, r))
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
    colorMode(RGB, 255, 255, 255);
    background(unhex('d1e0de'))
    blendMode(BLEND)
    smooth()
    noLoop()
    #randomSeed(1)
    
    
def draw():
    n_pixels = width*height
    ind1d_to_2d = lambda xy: (max(int(0.2*width), int(xy) % int(0.8*width)), max(int(0.2*height), int(xy)//height % (0.8*height)))
    create_origin = lambda : ind1d_to_2d(int(n_pixels/2 + randomGaussian()*n_pixels/5) % n_pixels)

    coarse = round(width/30)
    n_origins = int(round(width/18))
    origins = [create_origin() for _ in range(n_origins)]
    

    ### layer 1 of web
    n_seeds = 3
    reps = 8
    rattling = 2 # how much the nodes can deviate (+-) in pixels
    cloud_width, cloud_height = width/4, height/4
    n_edges = 50
    nodeset = NodeSet(nodes_per_cloud = 400, coarse = coarse,
                      color_begin = hex2col('55433680'), color_end = hex2col('2a221bd0'),
                      rattling = rattling)
    for _ in range(reps): 
        for i in range(n_seeds):
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = True)
        print "rep ", _
        nodeset.clear_cloud()
    
    ### layer 2 of web
    n_seeds = 2
    reps = 5
    rattling = 2
    cloud_width, cloud_height = width/8, height/8
    n_edges = 50
    nodeset = NodeSet(nodes_per_cloud = 300, coarse = coarse,
                      color_begin = hex2col('9E958160'), color_end = hex2col('665b44D0'),
                      rattling = rattling)
    
    for _ in range(reps): 
        for i in range(n_seeds):
            #origin = create_seed() # tuple
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = False)
        print "rep ", _
        nodeset.clear_cloud()
        
        
    ### layer 3 of web
    n_seeds = 3
    reps = 4
    rattling = 2
    cloud_width, cloud_height = width/8, height/8
    n_edges = 40
    nodeset = NodeSet(nodes_per_cloud = 250, coarse = coarse,
                      color_begin = hex2col('4f5a4080'), color_end = hex2col('252a1eD0'),
                      rattling = rattling)
    
    for _ in range(reps): 
        for i in range(n_seeds):
            #origin = create_seed() # tuple
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = True)
        print "rep ", _
        nodeset.clear_cloud()
        
        
    ### layer 4 of web
    n_seeds = 2
    reps = 6
    rattling = 2
    cloud_width, cloud_height = width/6, height/6
    n_edges = 30
    nodeset = NodeSet(nodes_per_cloud = 250, coarse = coarse,
                      color_begin = hex2col('55353580'), color_end = hex2col('2c1b1bD0'),
                      rattling = rattling)
    
    for _ in range(reps): 
        for i in range(n_seeds):
            #origin = create_seed() # tuple
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = True)
        print "rep ", _
        nodeset.clear_cloud()
    
    saveFrame("/tmp/spider_webs_%06d.tif" % NodeSet._randint(999999));
    print "=== done! ==="
