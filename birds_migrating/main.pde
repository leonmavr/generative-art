float flen = 300.0; // focal length (pinhole model)


void setup() {
  size(1920, 1080);
  orientation(LANDSCAPE);

  noStroke();
  background(77, 190, 217);
  // smooth edges
  smooth();
}


float gaussian(float x, float std, float ampl) {
  return ampl * 1/(std*sqrt(TWO_PI)) * exp(-1/2.0 * x/std * x/std);
}


// based on: https://openprocessing.org/sketch/79108/
void drawSky(int ncolors, int r, int g, int b) {

  int[] seeds_x = new int[ncolors];
  int[] seeds_y = new int[ncolors];
  color[] seed_colors = new color[ncolors];

  int minDistance = 0;
  int minIndex = 0;

  int myw = width;
  int myh = height;

  for (int i = 0; i < ncolors; i++) 
  {
    seed_colors[i] = color(round(random(255)), round(random(255)), round(random(255)));
  }

  // Set seeds position, random
  for (int i=0; i < ncolors; i = i+1)
  {
    // Keep them not too close to the borders, otherwise it's not fun
    // TODO: should also check that two or more are not generated in the same spot!
    seeds_x[i] = round(random(20.0, myw - 20.0));
    //seeds_y[i] = round(random(20.0, myh - 200.0));
  }
  float sstd = (float)height/2.0;
  for (int i=0; i < ncolors; i++) {
    float xx = (float) seeds_x[i];
    seeds_y[i] = round(randomGaussian()*height/4.0);
  }
  // 157,225,233 -> 12,116,167
  for (int i = 0; i < ncolors; i++) 
  {
    float xx = seeds_x[i];
    float yy = seeds_y[i];
    float dist_top_left = sqrt(xx*xx + yy*yy); 
    float t = dist_top_left/(sqrt(width*width + height*height));
    if (dist_top_left > 150) {
      seed_colors[i] = color(157 + t*(12-157), 225+t*(116-225), 233+t*(167-233));
    } else {
      seed_colors[i] = color(10, 10, 10);
    }
  }

  for (int px = 0; px < myw; px = px +1)
  {
    for (int py = 0; py < myh; py = py +1)
    {
      // Check distances to colors
      minDistance = ((px  - seeds_x[0]) * (px - seeds_x[0])) +  ((py  - seeds_y[0]) * (py  - seeds_y[0]));
      minIndex = 0;

      for (int nc = 1; nc < ncolors; nc = nc+1)
      {
        int dist = ((px  - seeds_x[nc]) * (px - seeds_x[nc])) +  ((py  - seeds_y[nc]) * (py  - seeds_y[nc]));

        if (dist <= minDistance)
        {
          minDistance = dist;
          minIndex = nc;
        }
      }
      stroke(seed_colors[minIndex]);
      point(px, py);
    }
  }
}


void drawHexCloud(int x, int y, int cwidth, int cheight) {
  int rad = 25;
  rad = min((int)(rad*(float)y/flen), 30);
  int nmeans_left = 1 + round(random(3));
  int nmeans_right = 1 + round(random(3));

  float ampl = cwidth*cheight/8*sqrt(TWO_PI);
  float std = cheight/4;

  float[] outline_right = new float[cheight];
  float[] outline_left = new float[cheight];
  int i = 0;

  float[] ampls_right = new float[nmeans_right]; 
  float[] ampls_left = new float[nmeans_left]; 
  float[] stds_right = new float[nmeans_right]; 
  float[] stds_left = new float[nmeans_left];

  // sum of gaussians
  float ampl_max = cwidth*cheight/8*sqrt(TWO_PI);
  float std_max = cheight/4;
  for (int j = 0; j < nmeans_right; j++) {
    ampls_right[j] = 0.5*ampl_max + random(0.5*ampl_max);
    stds_right[j] = 0.5*std_max + random(0.5*std_max);
  }
  for (int j = 0; j < nmeans_left; j++) {
    ampls_left[j] = 0.5*ampl_max + random(0.5*ampl_max);
    stds_left[j] = 0.5*std_max + random(0.5*std_max);
  }

  for (int xx = -cheight/2; xx < cheight/2; xx++) {
    outline_right[i] = 0.0;
    float y_centre;
    for (int ind_gauss = 0; ind_gauss < nmeans_right; ind_gauss++) {
      y_centre = -0.5*cheight + random(cheight);
      outline_right[i] += min(max(x + gaussian(xx, std, ampl), y_centre), width)/nmeans_right;
    }
    i++;
  }
  i=0;
  for (int xx = -cheight/2; xx < cheight/2; xx++) {
    outline_left[i] = 0.0;
    float y_centre = -0.4*cheight; // -0.4*h to 0.4*h
    for (int ind_gauss = 0; ind_gauss < nmeans_left; ind_gauss++) {
      y_centre += random(0.8*cheight);
      outline_left[i] += min(max(x - gaussian(xx, std, ampl), y_centre), width)/nmeans_left;
    }
    i++;
  }

  i = 0;
  stroke(200);
  strokeWeight(1.25);
  int rad_step = round(1.35*rad);
  for (int yy = y - cheight/2; yy < y + cheight/2; yy += rad_step) {
    for (int xx = (int)outline_left[i]; xx < outline_right[i]; xx += rad_step) {
      // r,g,b,a: TODO: make "a" a parameter
      fill(180+noise(xx/50.0, yy/50.0)*75, 180+noise(xx/50.0, yy/50.0)*75, 180+noise(xx/50.0, yy/50.0)*75, 60);
      polygon(xx, yy, 0.5*rad + random(4.5*rad), 6, 0, round(180+noise(xx/50.0, yy/50.0)*75), round(180+noise(xx/50.0, yy/50.0)*75), round(180+noise(xx/50.0, yy/50.0)*75), 100);
    }
    i += rad_step;
  }
}


void drawBird(int x, int y) {
  //float size = 40 + (float)y/width*120;
  float size = 50;
  float r = y;
  size = r*size/flen;
  println("Drawing bird at ", x, y);

  //--- body
  pushMatrix();
  translate(x, y);
  beginShape();
  // 128, 54, 36
  fill(128, 54, 36, 30);
  stroke(128, 54, 36, 255);
  strokeWeight(2);
  vertex(x, y);
  vertex(x+size, y);
  vertex(x+size, y+size);
  vertex(x, y+size);
  vertex(x, y);
  vertex(x+size, y);
  //vertex(x+size, y+size);
  vertex(x, y+size);
  vertex(x, y);
  //vertex(x+size, y);
  vertex(x+size, y+size);
  vertex(x, y+size);
  endShape(CLOSE);
  popMatrix();

  //---wings
  //left
  pushMatrix();
  translate(x, y);
  beginShape();
  // 128, 54, 36
  fill(128, 54, 36, 30);
  stroke(128, 54, 36, 255);
  strokeWeight(2);
  vertex(x, y);
  vertex(x-round(0.25+random(1))*size, y+round(random(1))*size);
  vertex(x, y+size);
  //vertex(x+round(1.25+random(1))*size, y+round(random(1))*size);
  endShape(CLOSE);
  popMatrix();
  //right
  pushMatrix();
  translate(x, y);
  beginShape();
  // 128, 54, 36
  fill(128, 54, 36, 30);
  stroke(128, 54, 36, 255);
  strokeWeight(2);
  vertex(x+size, y+size);
  vertex(x+size, y);
  vertex(x+round(1.25+random(1))*size, y+round(random(1))*size);
  endShape(CLOSE);
  popMatrix();
  // beak
  pushMatrix();
  translate(x, y);
  beginShape();
  // 128, 54, 36
  fill(128, 54, 36, 30);
  stroke(128, 54, 36, 255);
  strokeWeight(2);
  vertex(x, y);
  vertex(x+(float)size/2, y-(float)size/2);
  vertex(x+(float)size, y);
  endShape(CLOSE);
  popMatrix();

  //--- joints
  pushMatrix();
  translate(x, y);
  beginShape();
  // 128, 54, 36
  fill(128, 54, 36, 255);
  stroke(128, 54, 36, 255);
  noStroke();
  int rad = 6;
  ellipse(x, y, rad, rad);
  ellipse(x+size, y, rad, rad);
  ellipse(x+size, y+size, rad, rad);
  ellipse(x, y+size, rad, rad);
  ellipse(x+(float)size/2, y+(float)size/2, rad, rad);
  endShape(CLOSE);
  popMatrix();
}


void polygon(float x, float y, float radius, int npoints, float rangle, int cr, int cg, int cb, int ca) {
  pushMatrix();
  translate(x, y);
  rotate(rangle);
  float angle = TWO_PI / npoints;
  beginShape();
  fill(cr, cg, cb, ca);
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius;
    float sy = y + sin(a) * radius;
    vertex(sx, sy);
  }
  endShape(CLOSE);
  popMatrix();
}

void drawFlock(int x, int y) {
  float len = (float)y/flen*450;
  int n_birds = 2 + round(random(3));
  drawBird(x/2, y/2);
  int xi = x;
  int yi = y;
  int xi_neg = x;
  float angle = PI/6 + random(PI/12);
  for (int i = 0; i < n_birds; i++) {
    xi += -sin(angle)*len/n_birds;
    yi += cos(angle)*len/n_birds;
    xi_neg += sin(angle)*len/n_birds;
    drawBird(xi/2, yi/2); // I have no idea why birds are on a frame of different scale!!!
    drawBird(xi_neg/2, yi/2); // I have no idea why birds are on a frame of different scale!!!
  }
}


void drawSunRays() {
  int rad = height/6;
  int n_rays = 4 + round(random(3));
  float[] angles = new float[n_rays];
  for (int i = 0; i < n_rays; i++) {
    angles[i] = PI/30 + random(PI/2.5); 
    int n_specks = 8 + round(random(7));
    for (int j = 0; j < n_specks; j++) {
      int rad_j = round(rad*randomGaussian());
      //void polygon(float x, float y, float radius, int npoints, float rangle, int cr, int cg, int cb, int ca) 
      noStroke();
      float x = max(50 + rad_j*cos(angles[i]), 50);
      float y = max(50 + rad_j*sin(angles[i]), 50);
      polygon(x, y, 8 + sqrt(x*x + y*y)/sqrt(width*height)*(116-8), 6, 0, 223, 211, 35, 80+round(random(1))*30);
    }
  }
}


void draw() {
  // x, y, w, h
  drawSky(800, 0, 0, 0);
  drawHexCloud(200, 100, 180, 100);
  drawHexCloud(375, 160, 230, 80);
  drawHexCloud(50, 350, 250, 200);
  drawHexCloud(800, 225, 350, 150); 
  drawHexCloud(850, 350, 175, 120);
  drawFlock(300, 375);
  drawFlock(width-300, (int)(0.15*height));
  drawFlock((int)(0.75*width), (int)(0.55*height));  
  drawFlock((int)(0.5*width), (int)(0.075*height)); 
  drawHexCloud(350, 475, 150, 120);
  drawSunRays();
  noLoop();
}
