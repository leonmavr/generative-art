// Original by Daniel Shiffman


//------------------------------------------------------------------------
// Particle class
//------------------------------------------------------------------------

int cols;
int rows;

int scl = 10;
int noOfPoints = 400;
Particle[] particles = new Particle[noOfPoints];
//PVector[] flowField;
boolean [] colls;


class Particle {
  PVector pos = new PVector(random(width), random(height));
  PVector vel = new PVector(0, 0);
  PVector acc = new PVector(0, 0);
  float maxSpeed = 0.5;
  boolean dead = false;

  PVector prevPos = pos.copy();


  public void update(PVector[] vectors) {
    vel.add(acc);
    vel.limit(maxSpeed);

    // previous position
    int x = floor(pos.x / scl);
    int y = floor(pos.y / scl);
    int index = (x-1) + ((y-1) * cols);
    index = abs((index - 1) % vectors.length);
    if (colls[index] == true) {
      dead = true;
      return;
    }

    // updated position
    pos.add(vel);
    x = floor(pos.x / scl);
    y = floor(pos.y / scl);
    int indexNew = (x-1) + ((y-1) * cols);
    // current index
    indexNew = abs((indexNew - 1) % vectors.length);
    if (indexNew != index) {
      colls[index] = true;
    }

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
    stroke(255);
    strokeWeight(6);
    line(prevPos.x, prevPos.y, pos.x, pos.y);
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
// Flow field class
//------------------------------------------------------------------------
class FlowField {
  int nPoints;
  float scale;
  float zinc;
  float xyinc;
  int rows, cols;
  PVector[] flowField;
  float force;

  FlowField() {
    nPoints = 800;
    scale = 10.0;
    xyinc = 0.01;
    zinc = xyinc / 50.0;
    cols = floor(width/scale);
    rows = floor(height/scale);
    flowField = new PVector[(cols*rows)];
    force = 0.1;
  }

  FlowField(int nPoints_) {
    nPoints = nPoints_;
    scale = 10.0;
    xyinc = 0.01;
    zinc = xyinc / 50.0;
    cols = floor(width/scale);
    rows = floor(height/scale);
    flowField = new PVector[(cols*rows)];
    force = 0.1;
  }

  FlowField(int nPoints_, float scale_) {
    nPoints = nPoints_;
    scale = scale_;
    xyinc = 0.01;
    zinc = xyinc / 50.0;
    cols = floor(width/scale);
    rows = floor(height/scale);
    flowField = new PVector[(cols*rows)];
    force = 0.1;
  }

  FlowField(int nPoints_, float scale_, float xyinc_) {
    nPoints = nPoints_;
    scale = scale_;
    xyinc = xyinc_;
    zinc = xyinc / 50.0;
    cols = floor(width/scale);
    rows = floor(height/scale);
    flowField = new PVector[(cols*rows)];
    force = 0.1;
  }

  FlowField(int nPoints_, float scale_, float xyinc_, float force_) {
    nPoints = nPoints_;
    scale = scale_;
    xyinc = xyinc_;
    zinc = xyinc / 50.0;
    cols = floor(width/scale);
    rows = floor(height/scale);
    flowField = new PVector[(cols*rows)];
    force = force_;
  }

  public void create(int seed_) {
    noiseSeed(seed_);

    float yoff = 0;
    float zoff = 0;
    for (int y = 0; y < rows; y++) {
      float xoff = 0;
      for (int x = 0; x < cols; x++) {
        int index = (x + y * cols);

        float angle = noise(xoff, yoff, zoff) * 2 * TWO_PI;
        PVector v = PVector.fromAngle(angle);
        v.setMag(force);
        flowField[index] = v;
        xoff = xoff + xyinc;
      }
      yoff = yoff + xyinc;
    }
    zoff = zoff + zinc;
  }
}



//------------------------------------------------------------------------
// Setup and main
//------------------------------------------------------------------------
void setup() {
  size(1000, 760, P2D);
  orientation(LANDSCAPE);

  background(0);
  //hint(DISABLE_DEPTH_MASK);

  cols = floor(width/scl);
  rows = floor(height/scl);

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
  FlowField flowField = new FlowField();
  flowField.create(420);

  for (int i = 0; i < particles.length; i++) {
    particles[i].follow(flowField.flowField);
    particles[i].update(flowField.flowField);
    particles[i].edges();
    particles[i].show();
    particles[i].updatePrev();
  }
}
