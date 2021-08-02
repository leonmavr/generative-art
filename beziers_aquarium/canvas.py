#!/usr/bin/env python3
from PIL import Image
import aggdraw
import numpy as np
import doctest
from typing import List, Tuple, Union
from collections import namedtuple
import numpy as np
import os
 
Rect = namedtuple('Rect', ('x0', 'y0', 'x1', 'y1'))

class Canvas(object):
    """Docstring for Canvas. """
    def __init__(self, size = (1280, 960),
            outline_color = 'black',
            outline_width = 4,
            fill_color = '#ffffff',
            pos = (0, 0)):
        self._canvas_size = size
        self._img = Image.new("RGBA", size)
        self._draw = aggdraw.Draw(self._img)
        # outline = pen, fill = brush
        self._pen = aggdraw.Pen(outline_color, outline_width)
        self._brush = aggdraw.Brush(fill_color)
        self._info = {'pen': {'color': outline_color, 'width': outline_width},
                'brush': fill_color}
        self.drawing_pos(pos)
        self.coords = None # coordinates of last drawn curve as [x1,y1,x2,y2,...]
    

    def drawing_pos(self, xy: Tuple):
        self._drawing_pos = xy 


    def draw_curve(self, points: Tuple[Tuple], fill = None, outline_col = None, width = None, show = False, remove_straight_line = True, debug = False, fill_inner = None, as_tuples = False) -> List[int]: 
        points = [np.array(p) for p in points]
        if remove_straight_line:
            if fill_inner is None:
                fill_inner = self._info['brush']
            eps = 1e-6 # to avoid the division by zero surprises
            is_horizontal = abs(points[3][1]/(points[3][0] + eps)) < 0.2
            is_vertical = abs(points[3][0]/(points[3][1] + eps)) < 0.2
            w = self._info['pen']['width']
            if is_horizontal:
                pathstring = self.tuple2pathstring(
                        (points[0] + (w*2, 0), (0,0),(0,0), points[3] - (w*2, 0)))
                symbol = aggdraw.Symbol(pathstring)
                outline = aggdraw.Pen(fill_inner, w+3)
                self._draw.symbol(self._drawing_pos, symbol, outline, fill_inner)

        ### draw main Bezier curve
        pathstring = self.tuple2pathstring(points)
        polygon = aggdraw.Symbol(pathstring)
        ret = polygon.coords() # [x0,y0,x1,y1,...]
        # update outline and fill for next time 
        if outline_col is not None and width is not None:
            self._pen = aggdraw.Pen(outline_col, width)
            self._info['pen']['color'] = outline_col
            self._info['pen']['width'] = width
        elif outline_col is not None:
            self._pen = aggdraw.Pen(outline_col, self._info['pen']['width'])
            self._info['pen']['color'] = outline_col
        elif width is not None:
            self._pen = aggdraw.Pen(self._info['pen']['color'], width)
            self._info['pen']['width'] = width 
        if fill is not None:
            self._brush = aggdraw.Brush(fill)
            self._info['brush'] = fill
        self._draw.symbol(self._drawing_pos, polygon, self._pen, self._brush)

        if remove_straight_line and is_vertical:
            pathstring = self.tuple2pathstring(
                    (points[0] + (0, w), (0,0),(0,0), points[3] - (0, w)))
            symbol = aggdraw.Symbol(pathstring)
            outline = aggdraw.Pen(fill_inner, w+1)
            self._draw.symbol(self._drawing_pos, symbol, outline, fill_inner)
        # done; refresh the canvas and leave
        self._draw.flush()
        if show:
            self.show()
        if not as_tuples:
            return ret
        else:
            tuples_every2 = lambda x: np.array(list(zip(x[::2], x[1::2])))
            return tuples_every2(ret)


    def draw_cressent(self, points, fill_col = None, outline_col = None, width = None, show = False, debug = False, fill_inner = None):
        assert points[0][0] < points[3][0]
        assert len(points) == 6 and len(points[0]) == 2,\
            'Provide a list of 2D points p0,p1,p2,p3,p4,p5, where p0 and p3'\
            ' are the two extreme points, p1 and p2 shape the bigger arc.'
        # TODO: assert p0,p1,p2,p3,p4,p5,p0 are ccw 
        fill_main_shape = self._brush
        fill_col_main_shape = self._info['brush']
        width_old = self._info['pen']['width']
        outline_old = self._pen
        self.draw_curve(points[:4], fill = fill_col, outline_col = outline_col, width = width, show = show, debug = debug)
        self.draw_curve((points[0], points[5], points[4], points[3]), fill = fill_col_main_shape, width = 0, debug = debug, fill_inner = fill_inner)
        # reset. TODO: do that in a decorator
        self._info['pen']['width'] = width_old
        self._info['brush'] = fill_col_main_shape
        self._brush = fill_main_shape
        self._pen = outline_old
    

    def draw_circle(self, xy, rad, fill_col, outline_col, outline_width):
        pen = aggdraw.Pen(outline_col, outline_width)
        brush = aggdraw.Brush(fill_col)
        self._draw.ellipse((xy[0],xy[1],rad,rad), brush, pen)
        self._draw.flush()


    def show(self):
        self._img.show()


    def save(self, path = '/tmp'):
        self._img.save(
                os.path.join(path, 'drawing_%06d.png' % np.random.randint(0, 1e6)))


    @staticmethod
    def tuple2pathstring(points):
        """tuple2pathstring.
        Doctests
        --------
        (python -m doctest -v this_file.py)
        >>> canvas = Canvas()
        >>> points = ((50,0), (300,-300), (500,-300), (601,0))
        >>> exp_result = "m50,0 c300,-300,500,-300,601,0 z"
        >>> canvas.tuple2pathstring(points) == exp_result 
        True

        Parameters
        ----------
        points :
            list of (x, y) tuples
        """
        assert len(points) >= 2
        ret = "m%d,%d c" % (points[0][0], points[0][1])
        for p in points[1:-1]:
            ret += '%d,%d,' % (p[0], p[1])
        ret += '%d,%d z' % (points[-1][0], points[-1][1])
        return ret
