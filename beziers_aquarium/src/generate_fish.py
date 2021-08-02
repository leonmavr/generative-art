#!/usr/bin/env python3
from fish import Fish, Rect
import random
from numpy.random import randint

for _ in range(100):
    fish = Fish(
            size = (300, 260),
            sub_canvas = Rect(0, 0, 1, 1), # fill the canvas
            outline = 3,
            body_height = 0.6 + 0.1*random.random(),
            body_width = 0.8 + 0.05*random.random(),
            )
    fish.draw(show=False)
    fish.save()
