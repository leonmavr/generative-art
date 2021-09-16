float t = 0.0;
float dt = 0.01; 
float t0 = 1337.0;

void twister(int x, int y, float r, float theta, color cfill1, color cfill2, color cfill3, color cstroke) {
  pushMatrix();
  translate(x, y);
  beginShape();

  stroke(cstroke);
  strokeWeight(1.5);
  int n; // how many circles to draw
  if (r <= 100) {
    n = round(random(4, 6));
  } else if (r <= 200) {
    n = round(random(r/30, r/18));
  } else {
    n = round(random(r/30, r/18));
  }
  int rExt = round(r);
  int rExtStepMin = round(0.25*r/n); // how much to decrement the external radius
  int rExtStepMax = round(1.2*r/n); // how much to decrement the external radius
  int rSeed = 0;
  int rSeedStep = round(rExtStepMin*n);
  for (int i = 0; i < n; i++) {
    if (random(0, 1) <= 0.8) {
      if (random((float)i/n) <= 0.4) {
        fill(cfill1, 240);
      } else {
        fill(cfill2, 240);
      }
    } else {
      fill(cfill3, 240);
    }
    rExt = round(random(0.9*rExt, 1.1*rExt));
    ellipse(rSeed*cos(theta), rSeed*sin(theta), rExt, rExt); // convert seed radius to coordinates
    rExt -= round(random(rExtStepMin, rExtStepMax)); // external radius
    //rSeed += round(random(-0.5*rSeedStep/n, 1.5*rSeedStep/n)); // seed position
    rSeed += round(-0.6*rSeedStep/n + randomGaussian()/4 * 3 * rSeedStep/n); // seed position
  }
  endShape(CLOSE);
  popMatrix();
}


void waterfall(color cwater, color cwater2, color cfoam, color cstroke) {
  // river
  int y0 = round(random(0.95*height, height));
  int y1 = round(random(0, 0.075*height));
  float theta = atan(abs(y1-y0)/(float)width);
  float rlinemax = round((float)height/cos(theta));

  float r = 8;
  int n = 9; // twisters per wave
  float rTwisterMin = 25;
  float rTwisterMax = 250;
  int iTwister = 0;
  //int nTwisters = round(width/(r/sin(theta))); // ????
  float thetaWave = 0.0; // the orientation of each twister drawing in the waves
  float thetaWaveInc = 0.05;
  color color1alt = #CE4106;
  color color2alt = #F7731A;
  color color3alt = #FCCDAC;


  // water droplets
  // water drop
  //line(0,r/cos(theta),r/sin(theta),0);
  float r1 = 0.9*rlinemax;
  float r2 = 1.5*rlinemax;
  float x1hi = 0.0;
  float y1hi = r1/cos(theta);
  float x2hi = width;
  float y2hi = r1/sin(theta);

  float x1lo = 0.0;
  float y1lo = r2/cos(theta);
  float x2lo = width;
  float y2lo = r2/sin(theta);

  int ndrops = 200;
  //int y =  round(r/cos(theta) + (float)0/n * (0 - r/cos(theta)));
  r = 0.9*r1;
  //line(0,r1/cos(theta),r1/sin(theta),0);
  //line(0, r/cos(theta), r/sin(theta), r/cos(theta)-1000);
  for (int i = 0; i < ndrops; i++) {
    println(i);
    int x =  round(0 + (float)i/ndrops * r/sin(theta));
    int y =  round(r/cos(theta) + (float)i/ndrops * (0 - r/cos(theta)));
    int indy = 0;
    for (int yy = y; yy < y + height; yy+=2) {
      if (indy <= 800) {
        fill(color2alt, (float)(max((255- indy/300.0*255), 0))); 
        stroke(color2alt, (float)(max((255- indy/300.0*255), 0))); 
        //fill(color2alt, (float)(max((255- indy/4000.0*255), 0))); 
        if (random(1) < 0.38) {
          ellipse(x, yy, 2, 2);
        }
        indy++;
      }
    }
  }

  // river

  r = 8;
  while (r/sin(theta) < 1.15*width) {

    // 0 -> r/sin(theta), r/cos(theta) -> 0
    for (int i = 0; i < n; i++) {


      int x =  round(0 + (float)i/n * r/sin(theta));
      int y =  round(r/cos(theta) + (float)i/n * (0 - r/cos(theta)));
      x = round(random(0.975*x, 1.025*x));
      y = round(random(0.975*y, 1.025*y));
  float pFish;
      if (i <= n/4) {
        pFish = 0.4 ;
      } else if (i<= n/2)
       pFish = 0.3;
      else {
       pFish = 0.2;
      }
      if (random(1) <= 2*pFish) {
        // draw fish
        drawFish(x, y + round(random(0,height/10.0)), 100+r/sqrt(height*height + width*width)*300, random(-PI/4, 0));
      }
      // NOTE: change the hardcoded iTwister/30 below to change the radius 
      float rTwister = rTwisterMin + (float)iTwister/30 * (rTwisterMax - rTwisterMin);
      rTwister = random(0.975*rTwister, 1.025*rTwister);
      println(r, rlinemax);
      if (random(0, r/rlinemax) <0.15) {
        twister(x, y, rTwister, noise(thetaWave)*TWO_PI, color1alt, color2alt, color3alt, #FCDEC8);
      } else {
        twister(x, y, rTwister, noise(thetaWave)*TWO_PI, cwater, cwater2, cfoam, cstroke);
      }
     if (random(1) <= pFish*0.3) {
        // draw fish
        drawFish(x, y + round(random(-height/30.0,height/30.0)), 100+r/sqrt(height*height + width*width)*300, random(-PI/6, PI/6));
      }
      thetaWave += thetaWaveInc;
    }
    //line(0,r/cos(theta),r/sin(theta),0);
    r *= 1.13;
    iTwister++;
  }
}


void drawFish(int x, int y, float fwidth, float fangle) {
  float fheight = fwidth/3;
  float w = fwidth, h = fheight;
  // body
  float x0 = 0.0, y0 = 0.0, 
    x1 = -w/3.0, y1 = -0.2*h, 
    x2 = -w/5.0, y2 = -0.9*h, 
    x3 = -2.0/3*w, y3 = -0.95*h, 
    x4 = -0.8*w, y4 = -0.1*h, 
    x5 = -1.1*w, y5 = 0.15*h, 
    // fins
    x6 = -0.6*w, y6 = -1.5*h, 
    x7 = -0.65*w, y7 = 0.3*h, 
    // tail
    x8 = -1.3*w, y8 = 0.9*h, 
    x9 = -1.4*w, y9 = 0.15*h, 
    // eye - interpolate
    x10 = x0 + 0.29*(x3-x0), y10 = y0 + 0.45*(y3-y0);
  noStroke();

  // light to dark
  color c1 = #B3B3B3, c2 = #7C8388, cfin = #606A74, c3 = #646D74;

  //upper fin
  fill(cfin);
  pushMatrix();

  translate(x, y);
  rotate(fangle);
  beginShape();

  vertex(x2, y2);
  vertex(x6, y6);
  vertex(x1, y1);
  endShape(CLOSE);

  popMatrix();

  //lower fin
  fill(cfin);
  pushMatrix();

  translate(x, y);
  rotate(fangle);
  beginShape();

  vertex(x3, y3);
  vertex(x7, y7);
  vertex(x1, y1);
  endShape(CLOSE);

  popMatrix();

  // triangle 1 (head)
  fill(c1);
  pushMatrix();

  translate(x, y);
  rotate(fangle);
  beginShape();
  vertex(x0, y0);
  vertex(x1, y1);
  vertex(x2, y2);
  endShape(CLOSE);
  popMatrix();

  // triangle 2
  fill(c2);
  pushMatrix();

  translate(x, y);
  rotate(fangle);
  beginShape();

  vertex(x1, y1);
  vertex(x2, y2);
  vertex(x3, y3);
  endShape(CLOSE);

  popMatrix();

  // triangle 3
  fill(c3);
  pushMatrix();

  translate(x, y);
  rotate(fangle);
  beginShape();

  vertex(x4, y4);
  vertex(x1, y1);
  vertex(x3, y3);
  endShape(CLOSE);

  popMatrix();

  // tail
  fill(c1);
  pushMatrix();

  translate(x, y);
  rotate(fangle);
  beginShape();

  vertex(x8, y8);
  vertex(x5, y5);
  vertex(x9, y9);
  endShape(CLOSE);

  popMatrix();

  // triangle 4
  fill(c2);
  pushMatrix();

  translate(x, y);
  rotate(fangle);
  beginShape();

  vertex(x4, y4);
  vertex(x5, y5);
  vertex(x3, y3);
  endShape(CLOSE);

  popMatrix();

  // eye
  fill(#333333);
  pushMatrix();

  translate(x, y);
  rotate(fangle);
  beginShape();
  ellipse(x10, y10, (float)w/12.0, (float)w/12.0);
  endShape(CLOSE);

  popMatrix();
}


void setup() {
  size(1920, 1080);
  background(0);
  noStroke();
}

void draw() {
  smooth();

  // Get a noise value based on xoff and scale it according to the window's width
  waterfall(#117bad, #47b7d0, #7dd3e2, #e1f1f0);
  drawFish(500, 400, 100, PI/10.0);
  noLoop();
  saveFrame(String.format("/tmp/waterfall_%05d.png", round(random(99999))));//"/tmp/waterfall.png");
}
