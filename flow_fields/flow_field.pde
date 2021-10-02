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
  PVector prevPos = pos.copy();
  PVector vel = new PVector(0, 0);
  PVector acc = new PVector(0, 0);
  float m_maxSpeed = 0.5;

  boolean m_detectCollisions = true;
  boolean m_dead = false;
  color m_colorFill = #ffffff, m_colorStroke = 0xffffff;
  float m_lineWidth = 4.0, m_strokeWidth = 4.0;

  Particle() {
  }

  Particle(float linewidth) {
    m_lineWidth = linewidth;
  }

  Particle(float linewidth, boolean detectCollisions) {
    m_lineWidth = linewidth;  
    m_detectCollisions = detectCollisions;
  }

  Particle(float linewidth, boolean detectCollisions, float maxSpeed ) {
    m_lineWidth = linewidth;  
    m_detectCollisions = detectCollisions;
    m_maxSpeed = maxSpeed;
  }

  Particle(float linewidth, boolean detectCollisions, color colorFill, color colorStroke) {
    m_lineWidth = linewidth;  
    m_detectCollisions = detectCollisions;
    m_colorFill = colorFill;
    m_colorStroke = colorStroke;
  }

  Particle(float linewidth, boolean detectCollisions, color colorFill, color colorStroke, float lineWidth) {
    m_lineWidth = linewidth;  
    m_detectCollisions = detectCollisions;
    m_colorFill = colorFill;
    m_colorStroke = colorStroke;
    m_lineWidth = lineWidth;
  }
    
  Particle(float linewidth, boolean detectCollisions, color colorFill, color colorStroke, float lineWidth, float strokeWidth) {
    m_lineWidth = linewidth;  
    m_detectCollisions = detectCollisions;
    m_colorFill = colorFill;
    m_colorStroke = colorStroke;
    m_lineWidth = lineWidth;
    m_strokeWidth = strokeWidth;
  }



  public void update(PVector[] vectors) {
    vel.add(acc);
    vel.limit(m_maxSpeed);

    // previous position
    int x = floor(pos.x / scl);
    int y = floor(pos.y / scl);
    int index = (x-1) + ((y-1) * cols);
    index = abs((index - 1) % vectors.length);
    if ((m_detectCollisions) && (colls[index] == true)) {
      m_dead = true;
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
    stroke(m_colorStroke);
    strokeWeight(m_strokeWidth);
    fill(m_colorFill);
    pushMatrix();
    beginShape();
    float x0 = prevPos.x, y0 = prevPos.y, x1 = pos.x, y1 = pos.y;
    float w = m_lineWidth/2;
    vertex(x0-w, y0-w);
    vertex(x0-w, y0+w);
    vertex(x1+w, y1+w);
    vertex(x1+w, y1-w);
    endShape(CLOSE);
    popMatrix();
    //line(prevPos.x, prevPos.y, pos.x, pos.y);
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
  int nPoints = 800;
  float scale = 10.0;
  float xyinc = 0.01;
  float zinc = 0.01/50.0;

  int rows = floor(height/scale), cols = floor(width/scale);
  PVector[] flowField;
  float force = 0.1;

  FlowField() {

    flowField = new PVector[(cols*rows)];
  }

  FlowField(int nPoints_) {
    nPoints = nPoints_;
    flowField = new PVector[(cols*rows)];
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
// ParticleLayer class
//------------------------------------------------------------------------
class ParticleLayer {
  // TODO:   follow flow field and draw
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
