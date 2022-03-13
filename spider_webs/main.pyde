from collections import namedtuple
from collections import OrderedDict as OD
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
        #print "med: ", self._median_dist
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
        are_reachable = lambda node1, node2: self._get_dist(v, u) < 0.3*self._median_dist
        #are_reachable = lambda node1, node2: True
        max_tries = 2*len(visited)*len(unvisited)
        tries = 0
        while len(unvisited) != 0 and tries < max_tries:
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
                tries += 1
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
    
    def draw(self, nodes = True, tree = True, rad = 4, linewidth = 1):
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
 



    
def brick (x0, y0, number = 3, w = 60, h = 100, block_size = 8,\
                origin = 'tl', colors = ['202020bb', '505050bb', '808080bb'],\
                max_rotation = 1.25, line_weight = 0, line_color = '333333df'):
    # smoothstep interpolation: return (1-f(x))*a + f(x)*b, f(x) = 3x^2 - 2x^3"
    smoothstep = lambda a, b, x: (1-(3*x**2 - 2*x**3))*a + (3*x**2 - 2*x**3)*b
    thresh_min = .8 # probability of not drawing pixels at the top
    thresh_max = .1 # probability of not drawing pixels at the bottom 
    pushMatrix()
    translate(x0+w/2, y0+h/2)
    #print "y/h = ", 1.0*y0/height, y0
    if random(1) > 0.5:
        rotate(1.0*y0/height * max_rotation)
    else:
        rotate(-1.0*y0/height * max_rotation)
 
    strokeWeight(1.25)
    n = random(100)
    dn = 0.2
    for y in range(int(round(y0)), int(round(y0+h)), int(round(block_size))):
        for x in range(int(round(x0)), int(round(x0+w)), int(round(block_size))): 
            if random(1) > smoothstep(thresh_min, thresh_max, 1.0*(y-y0)/h):
                beginShape()   
                #ind = int(random(len(colors)))
                ind = int(noise(n)*len(colors))
                col = hex2col(colors[ind])       
                fill(col)            
                stroke(col)
                vertex(x-x0,y-y0)
                vertex(x+block_size-x0, y-y0)
                vertex(x+block_size-x0, y+block_size-y0)
                vertex(x-x0,y+block_size-y0)
                endShape(CLOSE)
                n += dn
    
    # draw brick's outline
    if line_weight > 0:
        
        strokeWeight(line_weight)
        stroke(hex2col(line_color))
        beginShape()
        noFill()
        b = block_size
        vertex(x0, y0)
        vertex(x0 + w, y0)
        vertex(x0 + w, y0+h+b/2)
        vertex(x0, y0+h+b/2)
        endShape(CLOSE)
    popMatrix()
    
'''
class IniRunner:
    def __init__(self, ini_fpath = 'config.ini'):
        self._ini_fpath = ini_fpath
        self._default = {
            'seeds': 4,
            'reps': 8,
            'rattling': 2,
            'width': 4,
            'height': 4,
            'edges': 60,
            'nodes': 60,
            'col_begin': '55434680',
            'col_end': '2a221bd0',
            'coarse': 50,
            'brick_number': 3,
            'brick_width': 60,
            'brick_height': 100,
            'brick_block': 8,
            'brick_colors': ['ff0000ff', '00ff00ff', '0000ffff'],
            'brick_rotations': [0, -0.25, 0.25, -0.5, 0.5],
            'brick_line_width': 0,
            'brick_line_color': '404040d0'
        }
        self._layers = OD()
        self._read_ini()

    @classmethod
    def hex2col(self, hexstr):
        if len(hexstr) == 8:
            return color(int(hexstr[:2], 16), int(hexstr[2:4], 16), int(hexstr[4:6], 16), int(hexstr[6:], 16))
        else:
            return color(int(hexstr[:2], 16), int(hexstr[2:4], 16), int(hexstr[4:6], 16))

    def _read_ini(self):
        with open(self._ini_fpath) as f:
            lines = f.readlines()
        remove_comment = lambda x: x.split('#')[0]
        split_line = lambda x: remove_comment(x).split('=')
        parse = lambda x: (split_line(x)[0].strip(), '') if len(split_line(x)) == 1 else (split_line(x)[0] , split_line(x)[1].strip()) 
        n_layer = 0
        for l in lines:
            lleft, lright = parse(l)
            if 'layer' in lleft:
                n_layer += 1
                self._layers[n_layer] = self._default
                continue
            if 'col' not in lleft:
                if 'brick_rotations' in lleft:
                    self._layers[n_layer][lleft] = [float(lr.strip())  for lr in lright.split(',')] 
                else:
                    try:
                        self._layers[n_layer][lleft] = int(lright)
                    except:
                        pass
            else:
                if 'brick_colors' in lleft:
                    self._layers[n_layer][lleft] = [c  for c in lright.split(',')] 
                else:
                    try:
                        self._layers[n_layer][lleft] = color(hex2col(lright))
                    except:
                        pass


    def draw(self, n_origins = 18):
        n_pixels = width*height
        ind1d_to_2d = lambda xy: (max(int(0.1*width), int(xy) % int(0.9*width)), max(int(0.1*height), int(xy)//height % (0.9*height)))
        create_origin = lambda : ind1d_to_2d(int(n_pixels/2 + randomGaussian()*n_pixels/5) % n_pixels)

        origins = [create_origin() for _ in range(n_origins)]
        for ind, configs in self._layers.items():
            ### layer i
            layer = self._layers[ind]
            nodeset = NodeSet(nodes_per_cloud = layer['nodes'],
                coarse = layer['coarse'],
                color_begin = layer['col_begin'],
                color_end = layer['col_end'],
                rattling = layer['rattling'])

            n_bricks = layer['brick_number']
            #print("----", ind, layer['brick_colors'])
            # TODO: fix rotation in config.ini, fix line colour
            for _ in range(n_bricks):
                brick(random(0.2*width, 0.8*width), random(0.2*height, 0.8*height),
                        w = layer['brick_width'], h = layer['brick_height'],
                        block_size = layer['brick_block'],
                        colors = layer['brick_colors'],
                        line_weight = layer['brick_line_width'])
            
            ### nodes of layer i
            for _ in range(layer['reps']): 
                for i in range(layer['seeds']):
                    ind_or = NodeSet._randint(n_origins)
                    nodeset.create_cloud(*origins[ind_or],
                        w=width/layer['width'],
                        h=height/layer['height'])
                    nodeset.min_tree(layer['edges'],
                    origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
                    nodeset.draw(nodes = True)
                print "rep ", _
                nodeset.clear_cloud()

'''            

def setup():
    size(900,600)
    colorMode(RGB, 255, 255, 255);
    #background(unhex('d1e0de'))
    background(203, 203, 230, 255)
    blendMode(BLEND)
    smooth()
    noLoop()
    #randomSeed(1)
    
    
def draw():
    n_pixels = width*height
    ind1d_to_2d = lambda xy: (max(int(0.1*width), int(xy) % int(0.9*width)), max(int(0.1*height), int(xy)//height % (0.9*height)))
    create_origin = lambda : ind1d_to_2d(int(n_pixels/2 + randomGaussian()*n_pixels/5) % n_pixels)

    n_origins = int(round(width/18))
    origins = [create_origin() for _ in range(n_origins)]
    brick_cols = [['2E232AFF', '635460FF', '696874FF', 'A79AABFF'],
                   ['2E627CFF', '1A2123FF', '142130FF', '0D0D16FF'],
                   ['261D2CFF', '3E3458FF', '666E90FF', 'ACA6CBFF'],
                   ['E1B389FF', 'E67649FF', 'A0B49FFF', '4C4944FF'],
                   ['2A222BFF', '2E101FFF', '1D2436FF', '093244FF']
                   ]

    ### layer 1 of web
    n_bricks = 3
    brick_width = width/6
    brick_height = height/6
    brick_block = 10
    n_seeds = 4
    reps = 8
    rattling = 2 # how much the nodes can deviate (+-) in pixels
    cloud_width, cloud_height = width/4, height/4
    n_edges = 60
    coarse = round(width/50)
    nodeset = NodeSet(nodes_per_cloud = 400, coarse = coarse,
                      color_begin = hex2col('1b1711a0'), color_end = hex2col('161412d0'),
                      rattling = rattling)

    for _ in range(n_bricks):
        brick(random(0.2*width, 0.8*width), random(-0.2*height, 0.8*height),
              w = brick_width, h = brick_height,
              colors = brick_cols[int(random(len(brick_cols)))])

    for _ in range(reps): 
        for i in range(n_seeds):
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = True)
        print "rep ", _
        nodeset.clear_cloud()
    
    ### layer 2 of web
    n_bricks = 2
    brick_width = width/7
    brick_height = height/7
    brick_block = 10
    n_seeds = 3
    reps = 6
    rattling = 2 # how much the nodes can deviate (+-) in pixels
    cloud_width, cloud_height = width/5, height/5
    n_edges = 50
    coarse = round(width/40)
    nodeset = NodeSet(nodes_per_cloud = 300, coarse = coarse,
                      color_begin = hex2col('594B44a0'), color_end = hex2col('3D342Ff0'),
                      rattling = rattling)

    for _ in range(n_bricks):
        brick(random(0.2*width, 0.8*width), random(-0.2*height, 0.8*height),
              w = brick_width, h = brick_height,
              colors = brick_cols[int(random(len(brick_cols)))])

    for _ in range(reps): 
        for i in range(n_seeds):
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = True)
        print "rep ", _
        nodeset.clear_cloud()
    
    ### layer 3 of web
    n_bricks = 2
    brick_width = width/7
    brick_height = height/7
    brick_block = 10
    n_seeds = 5
    reps = 7
    rattling = 2 # how much the nodes can deviate (+-) in pixels
    cloud_width, cloud_height = width/6, height/6
    n_edges = 50
    coarse = round(width/60)
    nodeset = NodeSet(nodes_per_cloud = 300, coarse = coarse,
                      color_begin = hex2col('554336a0'), color_end = hex2col('2a221bd0'),
                      rattling = rattling)

    for _ in range(n_bricks):
        brick(random(0.2*width, 0.8*width), random(-0.2*height, 0.8*height),
              w = brick_width, h = brick_height,
              colors = brick_cols[int(random(len(brick_cols)))])

    for _ in range(reps): 
        for i in range(n_seeds):
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = True)
        print "rep ", _
        nodeset.clear_cloud()
        
    ### layer 4 of web
    n_bricks = 0
    brick_width = width/10
    brick_height = height/10
    brick_block = 10
    n_seeds = 3
    reps = 6
    rattling = 2 # how much the nodes can deviate (+-) in pixels
    cloud_width, cloud_height = width/6, height/6
    n_edges = 60
    coarse = round(width/60)
    nodeset = NodeSet(nodes_per_cloud = 400, coarse = coarse,
                      color_begin = hex2col('0E0F12a0'), color_end = hex2col('070808d0'),
                      rattling = rattling)

    for _ in range(n_bricks):
        brick(random(0.2*width, 0.8*width), random(-0.2*height, 0.8*height),
              w = brick_width, h = brick_height,
              colors = brick_cols[int(random(len(brick_cols)))])

    for _ in range(reps): 
        for i in range(n_seeds):
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = True)
        print "rep ", _
        nodeset.clear_cloud()
        
        
    ### layer 5 of web
    n_bricks = 0
    brick_width = width/10
    brick_height = height/10
    brick_block = 10
    n_seeds = 3
    reps = 5
    rattling = 2 # how much the nodes can deviate (+-) in pixels
    cloud_width, cloud_height = width/4, height/4
    n_edges = 60
    coarse = round(width/80)
    nodeset = NodeSet(nodes_per_cloud = 350, coarse = coarse,
                      color_begin = hex2col('2F3A48a0'), color_end = hex2col('1E252Ed0'),
                      rattling = rattling)

    for _ in range(n_bricks):
        brick(random(0.2*width, 0.8*width), random(-0.2*height, 0.8*height),
              w = brick_width, h = brick_height,
              colors = brick_cols[int(random(len(brick_cols)))])

    for _ in range(reps): 
        for i in range(n_seeds):
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = True)
        print "rep ", _
        nodeset.clear_cloud()
        
    ### layer 6 of web
    n_bricks = 0
    brick_width = width/10
    brick_height = height/10
    brick_block = 10
    n_seeds = 4
    reps = 5
    rattling = 2 # how much the nodes can deviate (+-) in pixels
    cloud_width, cloud_height = width/7, height/7
    n_edges = 60
    coarse = round(width/80)
    nodeset = NodeSet(nodes_per_cloud = 350, coarse = coarse,
                      color_begin = hex2col('0C0C13a0'), color_end = hex2col('0E0E11d0'),
                      rattling = rattling)

    for _ in range(n_bricks):
        brick(random(0.2*width, 0.8*width), random(-0.2*height, 0.8*height),
              w = brick_width, h = brick_height,
              colors = brick_cols[int(random(len(brick_cols)))])

    for _ in range(reps): 
        for i in range(n_seeds):
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = True)
        print "rep ", _
        nodeset.clear_cloud()
        
    ### layer 7 of web
    n_bricks = 0
    brick_width = width/10
    brick_height = height/10
    brick_block = 10
    n_seeds = 4
    reps = 4
    rattling = 2 # how much the nodes can deviate (+-) in pixels
    cloud_width, cloud_height = width/7, height/7
    n_edges = 70
    coarse = round(width/80)
    nodeset = NodeSet(nodes_per_cloud = 350, coarse = coarse,
                      color_begin = hex2col('1b1711a0'), color_end = hex2col('161412d0'),
                      rattling = rattling)

    for _ in range(n_bricks):
        brick(random(0.2*width, 0.8*width), random(-0.2*height, 0.8*height),
              w = brick_width, h = brick_height,
              colors = brick_cols[int(random(len(brick_cols)))])

    for _ in range(reps): 
        for i in range(n_seeds):
            ind_or = NodeSet._randint(n_origins)
            nodeset.create_cloud(*origins[ind_or], w=cloud_width, h=cloud_height)
            nodeset.min_tree(n_edges, origin = (origins[ind_or][0] + random(-25, 25), origins[ind_or][1] + random(-25, 25)))
            nodeset.draw(nodes = True)
        print "rep ", _
        nodeset.clear_cloud()
    
    saveFrame("/tmp/spider_webs_%06d.png" % NodeSet._randint(999999));
    print "=== done! ==="
    
