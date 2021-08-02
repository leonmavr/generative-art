#!/usr/bin/env python3
from PIL import Image
import aggdraw
import numpy as np
import doctest
from typing import List, Tuple, Union
from collections import namedtuple
from numpy import round
from numpy.random import randint
import numpy as np
from canvas import Canvas
import itertools as it

Rect = namedtuple('Rect', ('x0', 'y0', 'x1', 'y1'))

def reset(func):
    # intercepts the method arguments - the first is self so it's a class method
    def inner(self, *args, **kwargs):
        # reset later
        brush_col = self._info['brush']
        out_col = self._info['pen']['color']
        out_w = self._info['pen']['width']
        func(self, *args, **kwargs)
        self._brush = aggdraw.Brush(brush_col)
        self._pen = aggdraw.Pen(out_col, out_w)
        self._info['brush'] = brush_col
        self._info['pen']['color'] = out_col 
        self._info['pen']['width'] = out_w
    return inner


class Fish(Canvas):
    """ Draw a random fish using Bezier curves. Usage:
        fish = Fish()
        fish.draw(show=True)
        # to save:
        fish.save()
    """

    def __init__(self, 
            size = (640, 480),
            sub_canvas = Rect(0, 0, .25, .25),
            outline = 4,
            body_width = 0.8,
            body_height = 0.7,
            col_body: Union[None, Tuple[int, int, int]] = None,
            col_belly: Union[None, Tuple[int, int, int]] = None):              
        """
        b0           b4           p9        p8        b3
        +------------+------------*--------*---------+              
        |            |            f  i  n            |
        *p7   t      |          p2            p1     |
        |          b5+----------*-------------*------+b9
        |            |                               |
        |     a      |                               |
        *p12         *p3       b   o   d   y         *p0 
        |            |                               |
        |     i      |         p4            p5      |
        |          b6+----------*-------------*------+b8
        *p6          |                               |
        |     l      |            f  i  n            |
        +------------+------------*--------*---------+
        b1          b7            p11      p10        b2
        * = main control points (excluding the randomness)
        + = reference points (control points are defined w.r.t them - b as in box)
        >>> fish = Fish()
        >>> area = lambda r: (abs(r.x0 - r.x1) * abs(r.y1 - r.y0))
        >>> area(fish._bboxes['whole']) == area(fish._bboxes['tail']) + area(fish._bboxes['body']) + area(fish._bboxes['fin_upper']) +  area(fish._bboxes['fin_lower']) 
        True
        """
        if col_body is None:
            col_body = (randint(128, 256), randint(128, 256), randint(128, 256)) 
        self._col_body = col_body
        self._col_outline = self.triplet2hex((col_body[0] - 90, col_body[1] - 90, col_body[2] - 90)) 
        self._width_outline = outline
        super(Fish, self).__init__(
                size = size,
                fill_color = self._col_body,
                outline_width = self._width_outline,
                outline_color = self._col_outline,
                pos = (sub_canvas.x0, sub_canvas.y0)
                )
        # Rect functions
        rect_to_int = lambda rect:  Rect(int(round(rect.x0)), int(round(rect.y0)),
                int(round(rect.x1)), int(round(rect.y1)))
        rect_scale = lambda r, width_height:\
            rect_to_int(Rect(r.x0*width_height[0], r.y0*width_height[1],
            r.x0 + r.x1*width_height[0], r.y0 + r.y1*width_height[1]))
        # break the sub-canvas into smaller bounding boxes
        cwidth, cheight = sub_canvas.x1 - sub_canvas.x0, sub_canvas.y1 - sub_canvas.y0
        bbox_whole = rect_scale(sub_canvas, self._canvas_size)
        fin_height = (1-body_height)/2
        rect_tail = Rect(sub_canvas.x0, sub_canvas.y0, (1-body_width)*cwidth, cheight)
        bbox_tail = rect_scale(rect_tail, self._canvas_size)
        rect_body = Rect(rect_tail.x1, fin_height*cheight, sub_canvas.x1, (1-fin_height)*cheight)
        bbox_body = rect_scale(rect_body, self._canvas_size)
        rect_fin_upper = Rect(rect_tail.x1, sub_canvas.y0, sub_canvas.x1, fin_height*cheight)
        bbox_fin_upper = rect_scale(rect_fin_upper, self._canvas_size) 
        rect_fin_lower = Rect(rect_tail.x1, (1-fin_height)*cheight, sub_canvas.x1, cheight)
        bbox_fin_lower = rect_scale(rect_fin_lower, self._canvas_size) 
        # save these to the class
        self._bboxes = {'whole': bbox_whole, 'tail': bbox_tail, 'body': bbox_body,
                'fin_upper': bbox_fin_upper, 'fin_lower': bbox_fin_lower}
        # auxiliary points - control points are defined w.r.t them
        b0, b1, _, _ = self.rect2vecs(bbox_tail)
        _, _, b2, b3 = self.rect2vecs(bbox_whole)
        b4, b5, _, _ = self.rect2vecs(bbox_fin_upper)
        b6,b7, _, b8 = self.rect2vecs(bbox_fin_lower)
        _, _, _, b9 = self.rect2vecs(bbox_body)
        # control points - they define the Bezier curves of the fish
        self._control_points = self.get_control_points((b0, b1, b2, b3, b4, b5, b6, b7, b8, b9))
        if col_belly is None:
            col_belly = (randint(128, 256), randint(128, 256), randint(128, 256)) 
        self._col_belly = col_belly
        self._curve = {}
        # [x0, y0, x1, y1,...] for the upper curve of the body
        self._curve['upper'] = []
        # [x0, y0, x1, y1,...] for the upper curve of the body
        self._curve['lower'] = []
        # DEBUG ONLY:
        self._curve['lower_old'] = []


    @staticmethod
    def triplet2hex(triplet: Tuple[int, int, int]):
        return '#%02x%02x%02x' % (triplet[0], triplet[1], triplet[2])


    @staticmethod
    def hex2triplet(hexstr: str):
        """hex2triplet.

        Parameters
        ----------
        hexstr : str
            e.g. #ab1099
        """
        return int(hexstr[1:3],16), int(hexstr[3:5], 16), int(hexstr[5:], 16)


    @staticmethod
    def rect2vecs(rect: Rect):
        tuples = ((rect.x0, rect.y0), (rect.x0, rect.y1), (rect.x1, rect.y1), (rect.x1, rect.y0))
        return (np.array(t) for t in tuples)


    @staticmethod
    def list_from_to(arr, fr = 0, to = 1, how_many = -1):
        assert to > fr and 0 <= fr <= 1 and 0 <= to <= 1
        round = lambda x: int(np.round(x))
        n = len(arr)
        arr = arr[round(fr*n):round(to*n)]
        if how_many > 0:
            arr = arr[::round(n/how_many)]
        return arr


    def get_control_points(self, aux_points: Tuple[np.ndarray]) -> Tuple[np.ndarray]:
        assert len(aux_points) == 10, 'The specification requires 10 auxiliary points'
        # t left to right and up to down
        segment_point = lambda p0p1, t: (p0p1[0] + t*(p0p1[1]-p0p1[0])).astype(np.int32)
        ret = []
        # append control points p0, p1, ...
        b = aux_points
        ran_p0p3 = np.random.uniform(-0.1, 0.15)
        ran_p1p5 = np.random.uniform(-0.25, 0.075)
        ran_p2p4 = np.random.uniform(-0.2, 0.2)
        t_p3 =  .57 + ran_p0p3
        tail_w = abs(self._bboxes['tail'].x1-self._bboxes['tail'].x0)
        ret.append(segment_point((b[3], b[2]), .57 + ran_p0p3)) # 0
        ret.append(segment_point((b[5], b[9]), .8 + ran_p1p5)) # 1
        ret.append(segment_point((b[5], b[9]), .3 + ran_p2p4)) # 2
        ret.append(segment_point((b[4], b[7]), t_p3)) # 3
        ret.append(segment_point((b[6], b[8]), .3 + ran_p2p4)) # 4
        ret.append(segment_point((b[6], b[8]), .8 + ran_p1p5)) # 5
        ret.append(segment_point((b[0], b[1]), .95)) # 6
        ret.append(segment_point((b[0], b[1]), .05)) # 7
        ret.append(segment_point((b[4], b[3]), .75)) # 8
        ret.append(segment_point((b[4], b[3]), .05)) # 9
        ret.append(segment_point((b[7], b[2]), .75)) # 10
        ret.append(segment_point((b[7], b[2]), .35)) # 11
        ret.append(segment_point((b[0], b[1]), t_p3) +\
                (np.random.randint(0, 0.6*tail_w), 0)
                )
        return ret

    
    @reset
    def draw_body(self):
        ## body (as upper and lower curve)
        p0, p1, p2, p3, p4, p5 = self._control_points[:6]
        self._curve['upper'] = self.draw_curve((p0, p1-p0, p2-p0, p3-p0),
                fill = self._col_body, outline_col = self._col_outline,
                remove_straight_line = False, as_tuples = True)
        self._curve['lower'] = self.draw_curve((p3, p4-p3, p5-p3, p0-p3), fill = self._col_body, remove_straight_line = False, as_tuples = True)
        ## belly
        n = len(self._curve['lower'])
        b31 = self._curve['lower'][int(n/4)]
        b32 = self._curve['lower'][int(3*n/4)]  
        fill_body = self._info['brush']
        self.draw_cressent((p3, p4-p3, p5-p3, p0-p3, b32-p3, b31-p3), fill_col = self._col_belly, fill_inner = fill_body)


    @reset
    def draw_eye(self, size = 1/20):
        assert 0 < size < 1, "Eye size is a fraction of the body's width"
        p0, p1, p2, p3  = self._control_points[:4]
        p_p0p3 = p0 + 0.2*(p3-p0) # how left or right
        ind_p_upper = np.argmin([abs(p_p0p3[0] - p[0]) for p in self._curve['upper']])
        p_upper = self._curve['upper'][ind_p_upper]
        p_eye = p_p0p3 + 1/2*(p_upper - p_p0p3)
        width_body = abs(self._bboxes['body'].x1 - self._bboxes['body'].x0) 
        rad = width_body*size
        pen = aggdraw.Pen('black', 0)
        brush = aggdraw.Brush(self._info['pen']['color'])
        self._draw.ellipse((p_eye[0]-rad, p_eye[1]-rad, p_eye[0]+rad, p_eye[1]+rad), brush, pen)
        brush = aggdraw.Brush('white') if np.random.random() < 0.85 else aggdraw.Brush('yellow')
        rad = 0.7*rad
        self._draw.ellipse((p_eye[0]-rad, p_eye[1]-rad, p_eye[0]+rad, p_eye[1]+rad), brush, pen)
        brush = aggdraw.Brush('#444444')
        rad = 0.7*rad
        self._draw.ellipse((p_eye[0]-rad, p_eye[1]-rad, p_eye[0]+rad, p_eye[1]+rad), brush, pen)
        self._draw.flush()


    @reset
    def draw_fins(self):
        # reset later
        out_col = self._info['pen']['color']
        out_w = self._info['pen']['width']

        # fin colour
        r, g, b = np.random.randint(20, 40), np.random.randint(20, 40), np.random.randint(20, 40)

        try:
            # TODO: self._info['brush'] is supposed to be a hex - BUG
            col_fin = self.hex2triplet(self._info['brush']) + np.array((r, g, b))
        except:
            col_fin = self._info['brush'] + np.array((r, g, b))
        col_fin = [min(c, 255) for c in col_fin]
        col_fin = self.triplet2hex(col_fin)

        cp0, cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11 = self._control_points[:12]
        height_body = abs(self._bboxes['body'].y1 - self._bboxes['body'].y0) 
        width_body = abs(self._bboxes['body'].x1 - self._bboxes['body'].x0) 
        ## upper fin
        # split each curve in n pieces and connect pieces with the same index together
        curve_upper = self._curve['upper']
        n_upper = len(curve_upper)
        ind_p0 = int(0.27*n_upper + np.random.uniform(-0.12*n_upper, 0.02*n_upper))
        ind_p3 = int(0.70*n_upper + np.random.uniform(-0.1*n_upper, 0.2*n_upper))
        cp9 = cp9 + (0, 0.25*height_body)
        p0 = curve_upper[ind_p0]
        p3 = curve_upper[ind_p3]
        pts_fin_lower = curve_upper[ind_p0:ind_p3]

        pts_fin_upper = self.draw_curve((p0, cp8-p0, cp9-p0, p3-p0), remove_straight_line = False, as_tuples = True, fill = col_fin)
        # try to keep only the straight part of the fin
        n_lines = np.random.randint(2, 18)
        pts_fin_upper = self.list_from_to(pts_fin_upper, 0.2, 0.8, n_lines)
        pts_fin_lower = self.list_from_to(pts_fin_lower, 0.2, 0.8, n_lines)
        # draw some lines across the fin
        for pup, plo in zip(pts_fin_upper, pts_fin_lower):
            self.draw_curve((plo, 0.75*(pup-plo), 0.25*(plo-pup), 0.6*(pup-plo)), width = 1)
        self._pen = aggdraw.Pen(out_col, out_w)

        ## lower fin
        # upper curve of the lower fin
        curve_upper = self._curve['lower']
        n_upper = len(curve_upper)
        # 0 = rear, 1 = front
        ind_p4 = int(0.25*n_upper + np.random.uniform(-0.05*n_upper, 0.02*n_upper))
        ind_p5 = int(0.80*n_upper + np.random.uniform(-0.05*n_upper, 0.02*n_upper))
        p4 = curve_upper[ind_p4]
        p5 = curve_upper[ind_p5]
        # lower curve of the lower fin
        curve_lower = self.draw_curve((p4,
            cp11-p4+(-0.15*width_body,-0.2*height_body),
            cp10-p4-(0,0.03*height_body),
            p5-p4), as_tuples = True, fill = col_fin)
        pts_fin_upper = curve_upper
        pts_fin_lower = curve_lower
        # do not draw across the curvy parts
        pts_fin_upper = curve_upper[ind_p4:ind_p5]
        pts_fin_upper = self.list_from_to(pts_fin_upper, 0.2, 0.8, n_lines/2)
        pts_fin_lower = self.list_from_to(pts_fin_lower, 0.2, 0.8, n_lines/2)
        for plo, pup in zip(pts_fin_lower, pts_fin_upper):
            self.draw_curve((pup, -0.25*(pup-plo), -0.45*(pup-plo), -0.6*(pup-plo)), width = 1)
    

    @reset
    def draw_tail(self):
        # reset later
        brush_col = self._info['brush']
        out_w = self._info['pen']['width']
        # use p3, p7, p12, p3
        cp0, cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11, cp12 = self._control_points[:13]
        r, g, b = np.random.randint(20, 40), np.random.randint(20, 40), np.random.randint(20, 40)
        try:
            col_tail = self._info['brush'] + np.array((r, g, b))
            col_tail = [min(c, 255) for c in col_tail]
            col_tail = self.triplet2hex(col_tail)
        except:
            col_tail = self.triplet2hex(self.hex2triplet(self._info['brush']) + np.array((r, g, b)))
        ## draw the tail shape
        tail_line_hi = self.draw_curve((cp3-(out_w,0), cp7-cp3, cp12-cp3, cp12-cp3), fill = col_tail, as_tuples = True)
        tail_line_lo = self.draw_curve((cp3-(out_w,0), cp6-cp3, cp12-cp3, cp12-cp3), fill = col_tail, as_tuples = True)
        ## draw straight lines from tail's curve towards tail's origin
        len_tail_hi = len(tail_line_hi)
        n_lines_hi = np.random.randint(0, np.round(len_tail_hi/5.0)+1)
        round = lambda x: int(np.round(x))
        eps = 1e-6
        # keep only the rather vertical part -> no self-intersections
        # from higher half
        tail_line_hi = tail_line_hi[int(0.55*len_tail_hi):int(0.9*len_tail_hi)]
        p_lines_hi_0 = tail_line_hi[::round(len_tail_hi/(n_lines_hi+eps))]
        for p0 in p_lines_hi_0:
            self.draw_curve((p0, (0,0), (0,0), 0.6*(cp3-p0)), width=1)
        # from lower half
        len_tail_lo = len(tail_line_lo)
        n_lines_lo = np.random.randint(0, np.round(len_tail_lo/5.0)+1)
        tail_line_lo = tail_line_lo[int(0.55*len_tail_lo):int(0.9*len_tail_lo)]
        p_lines_lo_0 = tail_line_lo[::round(len_tail_lo/(n_lines_lo+eps))]
        for p0 in p_lines_lo_0:
            self.draw_curve((p0, (0,0), (0,0), 0.6*(cp3-p0)), width=1)
        # line
        fill = self._info['brush']
        self.draw_curve((cp12 - (out_w/2, 0), (0,0), (0,0), cp3-cp12-(out_w/2, 0)), outline_col = fill, fill_inner = fill, fill = fill)


    @reset
    def draw_head(self):
        # reset later
        brush_col = self._info['brush']
        out_col = self._info['pen']['color']
        out_w = self._info['pen']['width']/2.0

        height_body = abs(self._bboxes['body'].y1 - self._bboxes['body'].y0) 
        width_body = abs(self._bboxes['body'].x1 - self._bboxes['body'].x0) 
        rand_offset = np.random.uniform(0, 0.04*height_body)
        ## curve 2
        p0, p1, p2, p3 = self._control_points[:4]
        p_p0p3 = p0 + 0.35*(p3-p0)
        ind_p0_head = np.argmin([abs(p_p0p3[0] - p[0]) for p in self._curve['upper']])
        p0_head = self._curve['upper'][ind_p0_head] + 0.08*height_body - (0, rand_offset) 
        p2_head = np.array((0, 0.45*height_body)) + (0, rand_offset) 
        p1_head = (-0.1*width_body, 0.18*height_body) 
        p0_head += (-0.05*width_body, 0.05*height_body)
        p2_head += (0.015*width_body, 0) 
        p2_head += (0, -0.05*height_body)
        self.draw_curve((p0_head, p1_head, p1_head, p2_head))
        ## curve1 fill
        p0, p1, p2, p3 = self._control_points[:4]
        p0_head = self._curve['upper'][ind_p0_head] + 0.1*height_body - (0, rand_offset)
        p2_head = np.array((0, 0.45*height_body)) + (0, rand_offset)
        p1_head = np.array((-0.1*width_body, 0.2*height_body))
        p0_head -= (0.015*width_body, 0)
        p2_head -= (0.017*width_body, 0)
        p1_head -= (0.015*width_body, 0)
        # BUG: self._info['brush'] is supposed to be a hex string
        col_fill = self.triplet2hex(np.array(self._info['brush']) - (40, 40, 40))
        self._brush = aggdraw.Brush(col_fill)
        self.draw_curve((p0_head, p1_head, p1_head, p2_head), fill_inner = col_fill, outline_col = col_fill)
        # reset
        self._brush = aggdraw.Brush(brush_col)
        self._pen = aggdraw.Pen(out_col, out_w)
        ## curve 1 outline
        p0, p1, p2, p3 = self._control_points[:4]
        p0_head = self._curve['upper'][ind_p0_head] + 0.1*height_body - (0, rand_offset)
        p2_head = np.array((0, 0.45*height_body)) + (0, rand_offset)
        p1_head = np.array((-0.1*width_body, 0.2*height_body))
        self.draw_curve((p0_head, p1_head, p1_head, p2_head))


    @reset
    def draw_dots(self):
        height_body = abs(self._bboxes['body'].y1 - self._bboxes['body'].y0) 
        width_body = abs(self._bboxes['body'].x1 - self._bboxes['body'].x0) 
        y_head = self._curve['upper'][0][1]
        rad = 0.035*height_body

        # starting points of dots on the fish's body
        pts_upper = self._curve['upper']
        nupper = len(pts_upper)
        nlines = np.random.randint(0, int(nupper/7.0))
        # 0 = head, 1 = tail
        ind_lines = np.random.randint(int(0.4*nupper), int(0.9*nupper), nlines)
        lines_upper0 = pts_upper[ind_lines]

        r, g, b = np.random.randint(20, 60), np.random.randint(20, 60), np.random.randint(20, 60)
        try:
            # if triplet
            col_dots = np.array(self._col_belly) + (r, g, b)
        except:
            col_dots = self.hex2triplet(col_dots)
            col_dots = np.array(self._col_belly) + (r, g, b)
        col_dots = self.triplet2hex([min(c, 255) for c in col_dots])

        # propagate from starting points to y_head
        for p in lines_upper0:
            p0 = (p[0], p[1] + np.random.uniform(2*rad, 3*rad)) 
            stdev = (y_head - p[1])/4.0
            npts_line = np.random.randint(1, 4)
            dots = np.array(list(it.repeat(p0, npts_line))) +\
                    [(np.random.uniform(-rad, rad), n) for n in abs(np.random.normal(0, stdev, npts_line))]
            for i, p0 in enumerate(dots):
                brush = aggdraw.Brush(col_dots)
                pen = aggdraw.Pen(self._info['pen']['color'], 1)
                rad_sc = rad*(i+1)/len(dots) + np.random.uniform(-0.2*rad, 0.2*rad)
                self._draw.ellipse((p0[0]-rad_sc, p0[1]-rad_sc, p0[0]+rad_sc, p0[1]+rad_sc), brush, pen)
        self._draw.flush()


    def draw(self, show = False):
        # parts are drawn in the order listed
        self.draw_body()
        self.draw_fins()
        self.draw_tail()
        self.draw_body()
        self.draw_dots()
        self.draw_head()
        self.draw_eye()
        if show:
            self.show()
