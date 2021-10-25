/**
 * Picture This.
 * The Vector field that starts from the edges of some photo.
 * More information: https://www.deconbatch.com/2020/11/picture-this-vector-field-method-to.html
 * All credits to the original author.
 * 
 * @author @deconbatch
 * @version 0.1
 * @license GPL Version 3 http://www.gnu.org/licenses/
 * Processing 3.5.3
 * 2020.11.19
 */

void setup() {

  size(980, 980);
  colorMode(HSB, 360, 100, 100, 100);
  smooth();
  noLoop();

}

void draw() {

  int imgMax     = 3;
  int initMax    = 5000;
  int caseWidth  = 30;
  int baseCanvas = width - caseWidth * 2;

  // original photo load
  PImage img = loadImage("your_photo.png");
  float rateSize = baseCanvas * 1.0 / max(img.width, img.height);
  img.resize(floor(img.width * rateSize), floor(img.height * rateSize));
  img.loadPixels();

  // detect edges
  ArrayList<PVector> edges = detectEdge(img, initMax);
  float initHue = typicalHue(img, edges) + 120.0;
  
  for (int imgCnt = 0; imgCnt < imgMax; imgCnt++) {
    println(imgCnt);
    float curlMult = random(4.0,8.0);
    float noiseDiv = 0.006 / curlMult;
    float uneven   = random(5.0, 10.0);
    float baseSiz  = 1.5;
    initHue += 30.0;

    // calculate the vector field
    ArrayList<ArrayList<PVector>> paths = getPaths(edges, curlMult, noiseDiv, uneven, imgCnt * 2 + 5);

    // draw background
    pushMatrix();
    translate((width - img.width) / 2, (height - img.height) / 2);
    background(initHue % 360.0, 80.0, 60.0, 100);
    noStroke();

    // draw shadow
    blendMode(DARKEST);
    for (ArrayList<PVector> path : paths) {
      
      float xInit = path.get(0).x;
      float yInit = path.get(0).y;
      float xPoint = xInit;
      float yPoint = yInit;
      int pIdx = floor(yPoint * img.width + xPoint);
      float baseHue = hue(img.pixels[pIdx]);
      float baseBri = brightness(img.pixels[pIdx]);
      for (int i = 0; i < path.size(); i++) {
        //println(i);
        PVector p = path.get(i);
        float pRatio = i * 1.0 / path.size();
        float eHue = baseHue + floor(((xInit * yInit) * 1.0) % 4.0) * 20.0;
        float eBri = baseBri * sin(PI * pRatio) * (8.0 + floor(((xInit * yInit) * 20000.0) % 5.0)) / 30.0;
        float eSiz = baseSiz * sin(PI * pRatio);
        fill(eHue % 360.0, 100.0, eBri, 100);
        translate(eSiz * 2.0, eSiz * 2.0);
        ellipse(p.x, p.y, eSiz, eSiz);
        translate(-eSiz * 2.0, -eSiz * 2.0);
      }
    }

    // draw foreground
    blendMode(LIGHTEST);
    for (ArrayList<PVector> path : paths) {
      float xInit = path.get(0).x;
      float yInit = path.get(0).y;
      float xPoint = xInit;
      float yPoint = yInit;
      int pIdx = floor(yPoint * img.width + xPoint);
      float baseHue = hue(img.pixels[pIdx]);
      float baseBri = brightness(img.pixels[pIdx]);
      for (int i = 0; i < path.size(); i++) {
        PVector p = path.get(i);
        float pRatio = i * 1.0 / path.size();
        float eHue = baseHue + floor(((xInit * yInit) * 1.0) % 4.0) * 20.0;
        float eSat = map(sin(PI * pRatio), 0.0, 1.0, 70.0, 90.0) * (6.0 + floor(((xInit * yInit) * 30000.0) % 4.0)) / 9.0;
        float eBri = baseBri * sin(PI * pRatio) * (8.0 + floor(((xInit * yInit) * 20000.0) % 5.0)) / 10.0;
        float eSiz = baseSiz * sin(PI * pRatio);
        fill(eHue % 360.0, eSat, eBri, 100.0);
        ellipse(p.x, p.y, eSiz, eSiz);
      }
    }
    popMatrix();

    casing();
    saveFrame("/tmp/frames/" + String.format("%04d", imgCnt + 1) + ".png");

  }

  exit();

}

/**
 * casing : draw fancy casing
 */
private void casing() {
  blendMode(BLEND);
  fill(0.0, 0.0, 0.0, 0.0);
  strokeWeight(60.0);
  stroke(0.0, 0.0, 0.0, 100.0);
  rect(0.0, 0.0, width, height);
  strokeWeight(50.0);
  stroke(0.0, 0.0, 100.0, 100.0);
  rect(0.0, 0.0, width, height);
  noStroke();
  noFill();
}

/**
 * getPaths : calculate the Vector Field paths.
 * @param _pvs      : start points coordinate of the Vector Field.
 * @param _curlMult : curl ratio of the path.
 * @param _noiseDiv : noise parameter step ratio.
 * @param _uneven   : make uneven the Vector Field with 3rd parameter of the noise.
 * @param _angles   : slant of the path. 
 * @return array of the Vector Field path, path is the array of the PVector coordinates.
 */
private ArrayList<ArrayList<PVector>> getPaths(ArrayList<PVector> _pvs, float _curlMult, float _noiseDiv, float _uneven, int _angles) {

  int   plotMax = 2000;
  float plotDiv = 0.2;
  ArrayList<ArrayList<PVector>> paths = new ArrayList<ArrayList<PVector>>();

  for (PVector p : _pvs) {

    ArrayList<PVector> path = new ArrayList<PVector>();
    
    float xInit = p.x;
    float yInit = p.y;
    float xPoint = xInit;
    float yPoint = yInit;

    for (int plotCnt = 0; plotCnt < plotMax; ++plotCnt) {
      float xPrev = xPoint;
      float yPrev = yPoint;
      float nX = noise(xPrev * _noiseDiv, yPrev * _noiseDiv, noise(yPrev * _noiseDiv * 3.0) * _uneven);
      float nY = noise(yPrev * _noiseDiv, xPrev * _noiseDiv, noise(xPrev * _noiseDiv * 3.0) * _uneven);
      xPoint += plotDiv * cos(TWO_PI * round(nX * _curlMult * _angles) / _angles);
      yPoint += plotDiv * sin(TWO_PI * round(nY * _curlMult * _angles) / _angles);
      path.add(new PVector(xPoint, yPoint));
    }
    if (dist(path.get(0).x, path.get(0).y, path.get(path.size() - 1).x, path.get(path.size() - 1).y) > 20.0) {
      paths.add(path);
    }
  }
  return paths;
}

/**
 * detectEdge : detect edges of photo image.
 * @param  _img     : detect edges of this image.
 * @param  _edgeNum : return edge points number.
 * @return array of the edges locations.
 */
private ArrayList<PVector> detectEdge(PImage _img, int _edgeNum) {

  ArrayList<PVector> edges = new ArrayList<PVector>();

  _img.loadPixels();
  for (int idxW = 1; idxW < _img.width - 1; idxW++) {  
    for (int idxH = 1; idxH < _img.height - 1; idxH++) {

      int pixIndex = idxH * _img.width + idxW;

      // saturation difference
      float satCenter = saturation(_img.pixels[pixIndex]);
      float satNorth  = saturation(_img.pixels[pixIndex - _img.width]);
      float satWest   = saturation(_img.pixels[pixIndex - 1]);
      float satEast   = saturation(_img.pixels[pixIndex + 1]);
      float satSouth  = saturation(_img.pixels[pixIndex + _img.width]);
      float lapSat = pow(
                         - satCenter * 4.0
                         + satNorth
                         + satWest
                         + satSouth
                         + satEast
                         , 2);

      // brightness difference
      float briCenter = brightness(_img.pixels[pixIndex]);
      float briNorth  = brightness(_img.pixels[pixIndex - _img.width]);
      float briWest   = brightness(_img.pixels[pixIndex - 1]);
      float briEast   = brightness(_img.pixels[pixIndex + 1]);
      float briSouth  = brightness(_img.pixels[pixIndex + _img.width]);
      float lapBri = pow(
                         - briCenter * 4.0
                         + briNorth
                         + briWest
                         + briSouth
                         + briEast
                         , 2);

      // hue difference
      float hueCenter = hue(_img.pixels[pixIndex]);
      float hueNorth  = hue(_img.pixels[pixIndex - _img.width]);
      float hueWest   = hue(_img.pixels[pixIndex - 1]);
      float hueEast   = hue(_img.pixels[pixIndex + 1]);
      float hueSouth  = hue(_img.pixels[pixIndex + _img.width]);
      float lapHue = pow(
                         - hueCenter * 4.0
                         + hueNorth
                         + hueWest
                         + hueSouth
                         + hueEast
                         , 2);

      // bright and saturation difference
      if (
          brightness(_img.pixels[pixIndex]) > 40.0
          && lapSat > 30.0
          ) edges.add(new PVector(idxW, idxH));

      // bright and some saturation and hue difference
      if (
          brightness(_img.pixels[pixIndex]) > 40.0
          && saturation(_img.pixels[pixIndex]) > 20.0
          && lapHue > 100.0
          ) edges.add(new PVector(idxW, idxH));

      // just brightness difference
      if (
          lapBri > 100.0
          ) edges.add(new PVector(idxW, idxH));

    }
  }

  int removeCnt = edges.size() - _edgeNum;
  for (int i = 0; i < removeCnt; i++) {
    edges.remove(floor(random(edges.size())));
  }

  return edges;

}

/**
 * typicalHue : detect typical hue value.
 * @param  _img : pick up hue value from this image.
 * @param  _pvs : coordinates in _img.
 * @return hue value.
 */
private float typicalHue(PImage _img, ArrayList<PVector> _pvs) {

  int[] cnt = new int[12];
  for (int i : cnt) {
    i = 0;
  }
  
  for (PVector p : _pvs) {
    int pIdx = floor(p.y * _img.width + p.x);
    cnt[floor(hue(_img.pixels[pIdx]) / 30.0)]++;
  }

  int hueValue = 0;
  int maxNum   = 0;
  for (int i = 0; i < 12; i++) {
    if (cnt[i] > maxNum) {
      hueValue = i;
      maxNum = cnt[i];
    }
  }

  return hueValue * 30.0;
  
}


/*
Copyright (C) 2020- deconbatch

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>
*/
