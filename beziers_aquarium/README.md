<h1 align="center">Bezier's aquarium</h1>
<p align="center"><i>Using Bezier/De Chasteljau curves to create random fish designs</i></p>	
<hr><p align="center">
<img src="https://raw.githubusercontent.com/0xLeo/generative-art/master/beziers_aquarium/assets/logo.png" alt="drawing" height="150"/>

### About
The purpose of this project is to demonstrate how Bezier/De Chasteljau curves can easily generate some nice random designs. This project generates random fish designs based on cubic Bezier/De Chasteljau curves.  
Each fish is bound within a rectangle (box) and each part of it in a sub-rectangle. The high-level rectangle contrails 13 control points p0,...,p12 which define the shape of the fish (each 4 control points define a single curve according to the Bezier curve theory).  
The rectangles and control points are listed below:
```
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

```

### Usage
File `generate_fish.py` defines how many fish will be generated, what size, colour, etc. File `create_collage.sh` runs everything and in the end creates a collage of all fish (by default saved as `/tmp/collage.png`). Therefore to execute everything, simply run:
```
./create_collage.sh
```
Example output:  
<img src="https://raw.githubusercontent.com/0xLeo/generative-art/master/beziers_aquarium/assets/output1.png" alt="drawing" height="400"/>


### TODOs
This little project is still at very early stage, the code messy, and there may be bugs. For the future:

- [ ] `Canvas.draw_curve` method: define all brush (fill) and pen (outline) option via one dictionary instead of loose options
- [ ] Draw more than one upper/lower fin
- [ ] More fish designs (catfish? marlin?)
- [ ] Define a random seed in `Fish`'s constructor. Random seed will in turn define the randomness of the control points, and the proportions (body width, tail width, etc.) of the fish.
- [ ] In `Fish.__init__`, `sub_canvas = Rect(0, 0, .25, .25)` does not work when we want the fish not to start from the origin, e.g. for `Rect(0.125, 0.125, 0.25, 0.25)`. In this case it draws a distorted fish. Fix this so i can stop using the `create_collage.sh` script. 

