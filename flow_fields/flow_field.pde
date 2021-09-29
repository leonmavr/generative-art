// Original by Daniel Shiffman

//------------------------------------------------------------------------
float inc = 0.01;
int scl = 2; // quantises the 2D space
float zoff = 0;

int cols;
int rows;

int noOfPoints = 1000;

Particle[] particles = new Particle[noOfPoints];
PVector[] flowField;
boolean [] colls;


class Particle {
  PVector pos = new PVector(random(width), random(height));
  PVector vel = new PVector(0, 0);
  PVector acc = new PVector(0, 0);
  float maxSpeed = 0.5;
  boolean drawThis = true;

  PVector prevPos = pos.copy();

  public void update() {
    vel.add(acc);
    vel.limit(maxSpeed);
    pos.add(vel);
    acc.mult(0);
  }

  public void follow(PVector[] vectors) {
    int x = floor(pos.x / scl);
    int y = floor(pos.y / scl);
    int index = (x-1) + ((y-1) * cols);
    // current index
    index = abs((index - 1) % vectors.length);

    PVector force = vectors[index];
    applyForce(force);
  }

  void applyForce(PVector force) {
    acc.add(force);
  }

  public void show() {
    if (drawThis == false) {
      return;
    } else {
      stroke(255);
      strokeWeight(6);
      //point(pos.x, pos.y);
      line(prevPos.x, prevPos.y, pos.x, pos.y);
    }
  }

  public void updatePrev() {
    prevPos.x = pos.x;
    prevPos.y = pos.y;
  }

  public void edges() {
    if (pos.x > width) {
      pos.x = 0;
      updatePrev();
    }
    if (pos.x < 0) {
      pos.x = width;
      updatePrev();
    }

    if (pos.y > height) {
      pos.y = 0;
      updatePrev();
    }
    if (pos.y < 0) {
      pos.y = height;
      updatePrev();
    }
  }
}

//------------------------------------------------------------------------





void setup() {
  size(1000, 760, P2D);
  orientation(LANDSCAPE);

  background(0);
  //hint(DISABLE_DEPTH_MASK);

  cols = floor(width/scl);
  rows = floor(height/scl);

  flowField = new PVector[(cols*rows)];
  for (int i = 0; i < noOfPoints; i++) {
    particles[i] = new Particle();
  }

  // collision matrix
  colls = new boolean[cols*rows];
  for (int i = 0; i < cols*rows -1; i++) {
    colls[i] = false;
  }
}

void draw() {
  fill(0);

  float yoff = 0;
  for (int y = 0; y < rows; y++) {
    float xoff = 0;
    for (int x = 0; x < cols; x++) {
      int index = (x + y * cols);

      float angle = noise(xoff, yoff, zoff) * 2 * TWO_PI;
      PVector v = PVector.fromAngle(angle);
      v.setMag(1);
      flowField[index] = v;
      xoff = xoff + inc;
    }
    yoff = yoff + inc;
  }
  zoff = zoff + (inc / 50);

  for (int i = 0; i < particles.length; i++) {
    particles[i].follow(flowField);
    particles[i].update();
    particles[i].edges();
    particles[i].show();
    particles[i].updatePrev();
  }
}
