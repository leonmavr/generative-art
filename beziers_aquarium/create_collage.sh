#!/bin/bash
./generate_fish.py

input=`ls /tmp/drawing_*`
montage -border 5 -bordercolor white\
    -geometry 300x260+5+5\
    -background white\
    -tile 10x10\
    $input\
    /tmp/collage.png
