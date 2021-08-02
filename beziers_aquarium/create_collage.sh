#!/bin/bash
./src/generate_fish.py

input=`ls /tmp/drawing_*`
rm /tmp/collage*.png

montage -border 5 -bordercolor white\
    -geometry 300x260+5+5\
    -background white\
    -tile 10x10\
    $input\
    /tmp/collage.png
echo "Done. Output at /tmp/collage.png"
