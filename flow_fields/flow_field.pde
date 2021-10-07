// Original by Daniel Shiffman


//------------------------------------------------------------------------
// Particle class
//------------------------------------------------------------------------

int cols;
int rows;

int scl = 20;
int noOfPoints = 70;
Particle[] particles = new Particle[noOfPoints];
boolean [] colls;


class Particle {
  PVector pos = new PVector(random(width), random(height));
  PVector prevPos = pos.copy();
  PVector vel = new PVector(0, 0);
  PVector acc = new PVector(0, 0);
  float m_maxSpeed = 0.4;

  boolean m_detectCollisions = false;
  boolean m_dead = false;
  boolean m_collided = false;
  color col = color(random(200, 400), 400, 400, random(400));
  color m_colorFill = col, m_colorStroke = col;
  float m_lineWidth = 4.0, m_strokeWidth = 4.0;
  int m_lifetime = 0; // lifetime; if non-zero, the closer m_life is to lifetime, the thinner the curve 
  int m_life = 0;
  float m_invisible = 0; // how many initial frames line will remain invisible (not drawn) for - 0 to 1
  boolean m_useRectangles = false;
  float m_witdthInit = 4.0, m_widthFinal = 4.0; // line width of Pelin noise lines
  color m_colorInit = col, m_colorFinal = col; // line colour in between is interpolated


  Particle() {
  }

  Particle (float posx, float posy) {
    pos.x = posx;
    pos.y = posy;
  }

  Particle (float posx, float posy, float linewidth) {
    pos.x = posx;
    pos.y = posy;
    m_lineWidth = linewidth;
  }

  Particle (float posx, float posy, float linewidth, int lifetime) {
    pos.x = posx;
    pos.y = posy;
    m_lineWidth = linewidth;
    m_lifetime = lifetime;
  }

  Particle (float posx, float posy, float linewidth, int lifetime, boolean detectCollisions) {
    pos.x = posx;
    pos.y = posy;
    m_lineWidth = linewidth;
    m_lifetime = lifetime;
    m_detectCollisions = detectCollisions;
  }

  Particle (float posx, float posy, float linewidth, int lifetime, boolean detectCollisions, float maxSpeed) {
    pos.x = posx;
    pos.y = posy;
    m_lineWidth = linewidth;
    m_lifetime = lifetime;
    m_detectCollisions = detectCollisions;
    m_maxSpeed = maxSpeed;
  } 

  Particle (float posx, float posy, float linewidth, int lifetime, boolean detectCollisions, float maxSpeed, color colorFill) {
    pos.x = posx;
    pos.y = posy;
    m_lineWidth = linewidth;
    m_lifetime = lifetime;
    m_detectCollisions = detectCollisions;
    m_maxSpeed = maxSpeed;
    m_colorFill = colorFill;
  }

  Particle (float posx, float posy, float linewidth, int lifetime, boolean detectCollisions, float maxSpeed, color colorFill, float strokeWidth, color colorStroke) {
    pos.x = posx;
    pos.y = posy;
    m_lineWidth = linewidth;
    m_lifetime = lifetime;
    m_detectCollisions = detectCollisions;
    m_maxSpeed = maxSpeed;
    m_colorFill = colorFill;
    m_strokeWidth = strokeWidth;
    m_colorStroke = colorStroke;
  }

  public void setInvisible(float lifetimeFraction) {
    if (m_lifetime != 0) {
      m_invisible = round(lifetimeFraction * m_lifetime);
    }
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
      m_collided = true;
      return;
    }

    pos.add(vel);

    // updated position
    x = floor(pos.x / scl);
    y = floor(pos.y / scl);
    int indexNew = (x-1) + ((y-1) * cols);
    // current index
    indexNew = abs((indexNew - 1) % vectors.length);
    if (indexNew != index) {
      colls[index] = true;
    }

    acc.mult(0);

    // update lifetime
    m_life = (m_life < m_lifetime) ? m_life+1 : m_life;
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
    // exit conditions
    // 1. collision
    if (m_collided == true) {
      return;
    }
    // 2. invisibility as set by the user
    if ((m_lifetime * m_invisible != 0) && (m_life < m_invisible * m_lifetime)) {
      return;
    }
    // 3. life span exceeded
    if (m_life >= m_lifetime) {
      return;
    }
    //println((float)m_life/m_lifetime);
    stroke(lerpColor(m_colorInit, m_colorFinal, (float)m_life/m_lifetime));
    fill(lerpColor(m_colorInit, m_colorFinal, (float)m_life/m_lifetime));

    float x0 = prevPos.x, y0 = prevPos.y, x1 = pos.x, y1 = pos.y;
    float w = m_lineWidth/2;
    if (m_lifetime != 0) {
      float finalLife = max(m_lifetime - m_life, 0);
      w = m_lineWidth + (finalLife - m_life)/m_life * (0 - m_lineWidth);
      w = 8; // TODO
    }
    strokeWeight(w);
    if (!m_useRectangles) {
      line(x0, y0, x1, y1);
    } else {
      //stroke(400);
      //strokeWeight(0.5);
      pushMatrix();
      beginShape();
      translate(x1, y1);
      vertex(-w/2, -w/2);
      vertex(0, -w/2);
      vertex(0, 0);
      vertex(-w/2, 0);
      endShape(CLOSE);
      popMatrix();
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
// Flow field class
//------------------------------------------------------------------------
class FlowField {
  int nPoints = 800;
  float scale = scl;
  float xyinc = 0.04;
  float zinc = 0.04/40.0;

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
    cols = floor(width/scale);
    rows = floor(height/scale);
    flowField = new PVector[(cols*rows)];
  }

  FlowField(int nPoints_, float scale_, float xyinc_) {
    nPoints = nPoints_;
    scale = scale_;
    xyinc = xyinc_;
    zinc = xyinc / 50.0;
    cols = floor(width/scale);
    rows = floor(height/scale);
    flowField = new PVector[(cols*rows)];
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
  colorMode(HSB, 400);
  smooth();

  background(400);
  //hint(DISABLE_DEPTH_MASK);

  cols = floor(width/scl);
  rows = floor(height/scl);

  for (int i = 0; i < noOfPoints; i++) {
    particles[i] = new Particle(random(100,800), random(100,800));
    particles[i].m_detectCollisions = true;
    particles[i].m_lifetime = 500;
    particles[i].m_invisible = 0.05;
    particles[i].m_useRectangles = false;
    particles[i].m_colorFill = color(300,400,300+round(random(0,1))*100,400);
    particles[i].m_colorInit = color(100,400,400,200);
    particles[i].m_colorFinal = color(300,400,400,200);
    //particles[i].m_maxSpeed = 2;
  }

  // initialise collision matrix
  colls = new boolean[cols*rows];
  for (int i = 0; i < cols*rows -1; i++) {
    colls[i] = false;
  }
}



void draw() {
  //fill(0);
  FlowField flowField = new FlowField();
  flowField.create(421);
  flowField.force = 0.1;

  for (int i = 0; i < particles.length; i++) {
    particles[i].follow(flowField.flowField);
    particles[i].update(flowField.flowField);
    particles[i].edges();
    particles[i].show();
    particles[i].updatePrev();
  }
}
