float rotate = PI/2;
float r = 0;
float dtheta = PI/4;
float rmax = 1200;
float dr = rmax/155;
int i = 0;
int imax = 10*round(rmax/dr);
float theta0 = 0;
float dtheta0 = PI/10;

void setup() {
  size(1300, 1300, P3D);
  colorMode(HSB, 360, 100, 100, 100);
  stroke(350, 100, 100, 15);
  strokeWeight(4.0);
  fill(360, 50, 100, 0);
  blendMode(ADD);
  
  background(350,40,6);
  smooth();
  //noLoop();
}

void draw() {
  //stroke(100);
  translate(width/2, height/2);
  scale(0.25);
  if (abs(r) > rmax) {
    dr = -dr;
  }
  r += dr;
  if (i > imax) {
    exit();
  }

  pushMatrix();
  beginShape(TRIANGLES);
  for (float theta = theta0; theta < theta0 + TWO_PI + dtheta; theta += dtheta) {
    vertex(r*cos(theta), r*sin(theta), r);
    //ellipse(r*cos(theta), r*sin(theta), r, r/2, r/2, r/2);
    //ellipse(r*cos(theta), r*sin(theta), 4,4);
  }
  rotateY(rotate*4);
  rotateX(rotate/4);
  rotateZ(rotate);
  rotate += 0.002;
  endShape(CLOSE);
  popMatrix();

  i++;
  println(i);
  theta0 += dtheta0;
  //saveFrame(String.format("/tmp/frames/frame_%05d.png", i));
}

