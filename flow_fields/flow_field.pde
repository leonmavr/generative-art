// Original by Daniel Shiffman


//------------------------------------------------------------------------
// Global variables; to be removed in the future
//------------------------------------------------------------------------
int cols;
int rows;
int scl = 20; // scale - the higher, the less granular the particles
// pallet
color[] sky;
color[] skyFinal;
color[] trees;
color mountains;


//------------------------------------------------------------------------
// Particle class
//------------------------------------------------------------------------
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
  color m_colorStroke = col;
  float m_lineWidth = 4.0, m_strokeWidth = 4.0;
  int m_lifetime = 0; // lifetime; if non-zero, the closer m_life is to lifetime, the thinner the curve 
  int m_life = 0;
  float m_invisible = 0; // how many initial frames line will remain invisible (not drawn) for - 0 to 1
  boolean m_useRectangles = false;
  float m_widthInit = 4.0, m_widthFinal = 4.0; // line width of Pelin noise lines
  color m_colorInit = col, m_colorFinal = col; // line colour in between is interpolated
  // to draw discs at the end of the lines
  color m_colorCircleIn = color(400, 400, 400, 400);
  color m_colorCircleOut = color(400, 400, 300, 400);
  float m_probCircle = 0.00; // the higher this probability, the more circles are drawn at the end of lifetime


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
  }

  Particle (float posx, float posy, float linewidth, int lifetime, boolean detectCollisions, float maxSpeed, color colorFill, float strokeWidth, color colorStroke) {
    pos.x = posx;
    pos.y = posy;
    m_lineWidth = linewidth;
    m_lifetime = lifetime;
    m_detectCollisions = detectCollisions;
    m_maxSpeed = maxSpeed;
    m_strokeWidth = strokeWidth;
    m_colorStroke = colorStroke;
  }

  public void setInvisible(float lifetimeFraction) {
    if (m_lifetime != 0) {
      m_invisible = round(lifetimeFraction * m_lifetime);
    }
  }


  public void update(PVector[] vectors, boolean[] collisions) {
    vel.add(acc);
    vel.limit(m_maxSpeed);

    // previous position
    int x = floor(pos.x / scl);
    int y = floor(pos.y / scl);
    int index = (x-1) + ((y-1) * cols);
    index = abs((index - 1) % vectors.length);
    if ((m_detectCollisions) && (collisions[index] == true)) {
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
      collisions[index] = true;
    }

    acc.mult(0);

    // update lifetime
    if (m_life < m_lifetime) {
      m_life++;
    }
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
    // 2. end of lifetime
    if (m_life >= m_lifetime) {
      return;
    }
    // 3. invisibility set by the user
    if ((m_lifetime != 0) && (m_invisible > 0.0)) {
      if ((float)m_life/m_life < m_invisible ) {
        return;
      }
    }

    if ((float)m_life/m_lifetime < m_invisible) {
      return;
    }

    //println((float)m_life/m_lifetime);
    stroke(lerpColor(m_colorInit, m_colorFinal, (float)m_life/m_lifetime));
    fill(lerpColor(m_colorInit, m_colorFinal, (float)m_life/m_lifetime));

    float x0 = prevPos.x, y0 = prevPos.y, x1 = pos.x, y1 = pos.y;
    float w = m_lineWidth/2;
    if (m_lifetime != 0) {
      float finalLife = max(m_lifetime - m_life, 0);
      float angle = 11.0*PI/20.0 - finalLife/m_lifetime * 11.0*PI/20.0;
      w = m_widthInit + (m_widthFinal - m_widthInit) * sin(angle);
      //println(x0, y0, x1, y1);
    }
    strokeWeight(w);
    if (!m_useRectangles) {
      line(x0, y0, x1, y1);
      if ((m_life == m_lifetime - 1) && (random(1) <= m_probCircle)) {
        fill(m_colorCircleIn);
        strokeWeight(2);
        stroke(m_colorCircleOut);
        int rad = floor(random(20, 40)); 
        ellipse(x1, y1, rad, rad);   
        fill(lerpColor(m_colorInit, m_colorFinal, (float)m_life/m_lifetime));
        stroke(lerpColor(m_colorInit, m_colorFinal, (float)m_life/m_lifetime));
        strokeWeight(w);
      }
    } else {
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
enum FlowFieldDirection {
  RANDOM, VERTICAL, HORIZONTAL
};


class FlowField {
  int nPoints = 800;
  float scale = scl;
  float xyinc = 0.04;
  float zinc = 0.04/40.0;

  int rows = floor(height/scale), cols = floor(width/scale);
  PVector[] flowField;
  float force = 0.05;
  FlowFieldDirection direction = FlowFieldDirection.VERTICAL;


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
        float angle = 0.0;
        if (direction == FlowFieldDirection.HORIZONTAL) {
          angle = noise(xoff, yoff, zoff) * 2 * TWO_PI + 2*TWO_PI*sin(0.015*index/float(rows));
        } else if (direction == FlowFieldDirection.VERTICAL) {
          angle = noise(xoff, yoff, zoff) * 2 * TWO_PI + 2*TWO_PI*sin(0.015*index/float(cols));
        } else {
          angle = noise(xoff, yoff, zoff) * 2 * TWO_PI;
        }
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
  int m_scl = 20;
  int m_cols = floor(width/scl);
  int m_rows = floor(height/scl);
  int m_noOfPoints = 700;
  Particle[] m_particles;
  //boolean [] m_colls;
  int m_seed = 420;
  boolean[] m_colls;


  ParticleLayer() {
    FlowField m_flowField = new FlowField();
    m_colls = new boolean[cols*rows];
    m_particles = new Particle[m_noOfPoints];
    m_flowField.create(m_seed);
    for (int i = 0; i < cols*rows -1; i++) {
      m_colls[i] = false;
    }
  }


  ParticleLayer(int seed) {
    FlowField m_flowField = new FlowField();
    m_particles = new Particle[m_noOfPoints];
    m_colls = new boolean[cols*rows];
    m_seed = seed;
    m_flowField.create(m_seed);
    for (int i = 0; i < cols*rows -1; i++) {
      m_colls[i] = false;
    }
  }


  ParticleLayer(int seed, int nParticles) {
    FlowField m_flowField = new FlowField();
    m_colls = new boolean[cols*rows];
    m_seed = seed;
    m_flowField.create(m_seed);
    for (int i = 0; i < cols*rows -1; i++) {
      m_colls[i] = false;
    }
    m_noOfPoints = nParticles;
    m_particles = new Particle[m_noOfPoints];
  }

  public void create(FlowField flowField, 
    int xmin, 
    int xmax, 
    int ymin, 
    int ymax, 
    boolean detectCollisions, 
    int lifetime, 
    float invisible, 
    boolean useRectangles, 
    color colorInit, 
    color colorFinal, 
    float widthInit, 
    float widthFinal, 
    float maxSpeed
    ) {
    // collision matrix initisalisation
    for (int i = 0; i < cols*rows -1; i++) {
      m_colls[i] = false;
    }
    // set up each particle
    //println(particles.length, m_noOfPoints);
    for (int i = 0; i < m_particles.length; i++) {
      m_particles[i] = new Particle(xmin + (xmax - xmin) * abs(randomGaussian()/2), ymin + (ymax - ymin) * abs(randomGaussian()/2));
      m_particles[i].m_detectCollisions = detectCollisions;
      m_particles[i].m_lifetime = lifetime;
      m_particles[i].m_invisible = invisible;
      m_particles[i].m_useRectangles = useRectangles;
      m_particles[i].m_colorInit = colorInit;
      m_particles[i].m_colorFinal = colorFinal;
      m_particles[i].m_widthInit = widthInit;
      m_particles[i].m_widthFinal = widthFinal;
      m_particles[i].m_maxSpeed = maxSpeed;
    }
    for (int j = 0; j < lifetime; j++) { // TODO: iterate over lifetime (m_life++)
      // apply the flow field (flowField) on each
      for (int i = 0; i < m_particles.length; i++) {
        m_particles[i].follow(flowField.flowField);
        m_particles[i].update(flowField.flowField, m_colls);
        m_particles[i].edges();
        m_particles[i].show();
        m_particles[i].updatePrev();
        //println(m_particles[i].m_life);
      }
    }
  }
}


//------------------------------------------------------------------------
// Draw mountains
//------------------------------------------------------------------------
void mountains(int howMany, float maxHeight, color colorFill, color colorStroke) {
  float minHeight = maxHeight/10;
  fill(mountains);
  stroke(colorStroke);
  strokeWeight(2.5);

  for (int i = 0; i < howMany; i++) {
    int period = floor(random(width/4, width));
    float ampl = minHeight + (float)(howMany-i)/howMany * (maxHeight - minHeight);
    float phase = random(TWO_PI);
    //println(period, ampl);
    beginShape();
    float mean = 0;
    for (int x = 0; x < width; x++) {
      float y = abs(height - 1.2*ampl - ampl/2*sin(TWO_PI/period*x + phase) - ampl/2*sin(TWO_PI/period*0.5*x + phase) + ampl*noise(x/(width/4.0)));
      vertex(x, y);
      mean += y;
    }

    // close the polygon so it can be filled
    vertex(width+100, height);
    vertex(-100, height);
    endShape();

    mean /= width;
    int ntrees = round(random(8));
    for (int j = 0; j < ntrees; j++) {
      beginShape();
      fill(trees[floor(random(5))]);
      int x0 = floor(random(width));
      int y0 = height;
      int y1 =  floor(random(0.8*mean, 1.4*mean));
      int x1  = x0 + floor(random(width/45, width/60));
      vertex(x0, y0);
      vertex(x0, y1);
      vertex(x1, y1);
      vertex(x1, y0);
      endShape();
    }
    fill(mountains);
    stroke(colorStroke);
  }
}


// enter a HSV code from the website https://coolors.co/palettes, e.g. (100, 234, 90), and scale it for this program 
// H, S, V, A all range from 0 to 400 in this program so scaling is required 
color scaleHsv(int h, int s, int v, int a, boolean dark) {
  h = round(h*400.0/360);
  s *= 4;
  v *= 4;
  if (dark) {
    s = max(0, s-10);
    v = max(0, v-80);
  }
  return color(h, s, v, a);
}


//------------------------------------------------------------------------
// Setup and main
//------------------------------------------------------------------------
void setup() {
  size(1200, 741, P2D);
  orientation(LANDSCAPE);
  colorMode(HSB, 400);
  smooth();
  background(100);
  hint(DISABLE_DEPTH_MASK);
  cols = floor(width/scl);
  rows = floor(height/scl);

  sky = new color[5];
  skyFinal = new color[5];
  trees = new color[5];

  sky[0] = scaleHsv(12, 95, 15, 100, false);
  skyFinal[0] = scaleHsv(12, 95, 15, 100, true);
  trees[0] =  scaleHsv(12, 95, 15, 400, false);
  
  sky[1] = scaleHsv(348, 93, 22, 100, false);
  skyFinal[1] = scaleHsv(348, 93, 22, 100, true);
  trees[1] = scaleHsv(348, 93, 22, 400, false);
  
  sky[2] = scaleHsv(355, 87, 39, 100, false);
  skyFinal[2] = scaleHsv(355, 87, 39, 100, true);
  trees[2] = scaleHsv(355, 87, 39, 400, false);
  
  sky[3] = scaleHsv(357, 89, 50, 100, false);
  skyFinal[3] = scaleHsv(357, 89, 50, 100, true);
  trees[3] = scaleHsv(357, 89, 50, 400, false);
  
  sky[4] = scaleHsv(356, 77, 68, 100, false);
  skyFinal[4] = scaleHsv(356, 77, 68, 100, true);
  trees[4] = scaleHsv(356, 77, 68, 400, false);
  
  mountains = color(268, 44, 164, 400);
}



void draw() {
  // seeds
  int noiseSeed = 4775;
  int randomSeed = 13123;
  int flowFieldSeed = floor(random(999999));
  int particleSeed = floor(random(999999));
  noiseSeed(noiseSeed);
  randomSeed(randomSeed);

  // particles
  FlowField flowField = new FlowField();
  flowField.create(flowFieldSeed);
  ParticleLayer layer = new ParticleLayer(particleSeed, 150);
  int yRan = 75;
  int xRan = 100;
  int i;


  // create(
  //FlowField flowField, int xmin, int xmax, int ymin, int ymax, boolean detectCollisions,
  //int lifetime, float invisible, boolean useRectangles,
  //color colorInit, color colorFinal, float widthInit, float widthFinal, float maxSpeed)
  for (int j = 0; j < 37; j++) {
    println(j);
    i = floor(random(5));
    int x0 = floor(random(width));
    int y0 = floor(random(0));
    layer.create(flowField, 
      x0, 
      x0 + width/4 + floor(random(xRan)), 
      y0, 
      y0 + 3*height/4, 
      false, 
      400 + floor(random(100)), 
      0.01, 
      true, 
      sky[i], 
      skyFinal[i], 
      random(15, 20), 
      4, 
      0.5
      );
  }

  mountains(floor(random(7, 30)), height/6, color(0, 0, 110, 400), color(0, 0, 0, 400));

  // important, don't forget it!
  noLoop();
  saveFrame(String.format("/tmp/wildfires_%d_%d.png", randomSeed, noiseSeed));
}
