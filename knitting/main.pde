void setup() {
  size(800, 600);
  background(0);
  stroke(300,100,100,70);
  strokeWeight(2.0);
  blendMode(ADD);
  colorMode(HSB, 360, 100, 100, 100);
  smooth();
  noLoop();
}

float wave(float ampl, float period, float x) {
  return ampl*sin(TWO_PI/period * x);
}


void draw() {
  //    node inexing:
  //
  //    0           1
  //
  //
  //
  //    2           3
  translate(0, height/2);
  float A1, A2, T1, T2;
  A1 = height/8.0;
  A2 = height/2.5;
  T1 = width/4.0;
  T2 = width/1.5;
  int samplePeriod = 20;
  int samplePeriodMean = 20;
  float dx = 0.05;
  PVector[] nodes = new PVector[4]; // the 4 knitting nodes
  for (int i = 0; i < 4; i++) {
    nodes[i] = new PVector(0, 0);
  }
  nodes[0].x = 0;
  nodes[0].y = wave(A1, T1, 0);

  nodes[1].x = samplePeriod * dx;
  nodes[1].y = wave(A1, T1, nodes[1].x);

  nodes[2].x = samplePeriod/2.0 * dx;
  nodes[2].y = wave(A2, T2, nodes[2].x);

  nodes[3].x = samplePeriod*1.5*dx;
  nodes[3].y = wave(A2, T2, nodes[3].x);

  int i = 0;
  for (float xx = 0; xx < width; xx += dx) {
    float y1 = wave(A1, T1, xx); 
    float y2 = wave(A2, T2, xx);
    //point(xx, y1);
    //point(xx, y2);

    if (i % samplePeriod == 0) {
      // 0 and 2 replaced 
      //println(abs(nodes[1].y-nodes[3].y)/abs(A2-A1));
      float x1new = nodes[1].x + dx*map((abs(nodes[1].y-nodes[3].y)/(2*abs(A2-A1))), 0, 1, 0.02*samplePeriodMean, 12*samplePeriodMean);
      //float x1new = nodes[1].x + dx*samplePeriod;
      float y1new = wave(A1, T1, x1new);

      float x3new = nodes[3].x + dx*map((abs(nodes[0].y-nodes[2].y)/abs(2*(A2-A1))), 0, 1, 0.01*samplePeriodMean, 18*samplePeriodMean);
      //float x3new = nodes[3].x + dx*samplePeriod;
      float y3new = wave(A2, T2, x3new);

      nodes[0].x = nodes[1].x;
      nodes[0].y = nodes[1].y;

      nodes[2].x = nodes[3].x;
      nodes[2].y = nodes[3].y;

      nodes[1].x = x1new;
      nodes[1].y = y1new;

      nodes[3].x = x3new;
      nodes[3].y = y3new;

      //line(nodes[0].x, nodes[0].y, nodes[1].x, nodes[1].y);
      line(nodes[1].x, nodes[1].y, nodes[2].x, nodes[2].y);
      //line(nodes[2].x, nodes[2].y, nodes[3].x, nodes[3].y);
      line(nodes[3].x, nodes[3].y, nodes[0].x, nodes[0].y);
      line(nodes[0].x, nodes[0].y, nodes[2].x, nodes[2].y);
    }
  }
  //saveFrame(String.format("/tmp/sine_%05d.png", round(random(99999))));
}

