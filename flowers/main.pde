float t = 0.0;
float dt = 0.3;


// x, y, radius, aspect ratio (w/h)
void waterlilly(float x, float y, float r, float asp, float angle) {
  float r1 = random(4, 6); // smaller radius
  float r2 = r;
  float deltaTheta;
  if (r<=120) {
    deltaTheta = r/2000.0;
  } else {
    deltaTheta = r/4000.0;
  }
  noiseDetail(100);
  pushMatrix();
  r /= 2.0;
  r2=r;
  strokeWeight(1);
  noFill();
  float t0 = random(1000);

  //outer outline
  stroke(255);
  strokeWeight(4);
  fill(255);
  pushMatrix();
  translate(x, y);
  rotate(angle);
  t=t0;
  beginShape();
  for (float theta = 0.0; theta < TWO_PI; theta += deltaTheta) {
    float rout = r2 + r2/2 * noise(t);
    float rin = r1 + r1/2 * noise(t+420);
    //vertex(rout*cos(theta), 1.5*rout*sin(theta));
    vertex(rout*cos(theta), 1/asp*rout*sin(theta));
    t += dt;
  }
  endShape(CLOSE);
  popMatrix();




  // lines
  t=t0;
  stroke(50);
  strokeWeight(1.25);
  translate(x, y);
  rotate(angle);
  beginShape();
  for (float theta = 0.0; theta < TWO_PI; theta += deltaTheta) {
    float rout = 2*r2 + r2/2 * noise(t-dt) + r2/2 * noise(t+dt);
    rout /= 2.0;
    float rin = r1 + r1/2 * noise(t+420);
    //vertex(rout*cos(theta), 1.5*rout*sin(theta));

    line(rout*cos(theta), 1/asp*rout*sin(theta), rin*cos(theta), 1/asp*rin*sin(theta));

    t += dt;
  }
  endShape(CLOSE);
  popMatrix();


  //inner outline
  stroke(0);
  strokeWeight(1.5);
  pushMatrix();
  translate(x, y);
  rotate(angle);
  t=t0;
  beginShape();
  for (float theta = 0.0; theta < 0.99*TWO_PI; theta += deltaTheta) {
    float rout = r2 + r2/2 * noise(t);
    float rin = r1 + r1/2 * noise(t+420);
    //vertex(rout*cos(theta), 1.5*rout*sin(theta));
    vertex(rin*cos(theta), 1/asp*rin*sin(theta));
    t += dt;
  }
  endShape(CLOSE);
  popMatrix();

  // anthers
  int n = round(random(5, 8));
  deltaTheta = TWO_PI/n;
  pushMatrix();
  translate(x, y);
  rotate(angle);
  t=t0;
  strokeWeight(1.25);
  beginShape();

  float theta = 0.0;
  for (int i = 0; i < n; i++) {
    float rout = r2/2.0;
    float rin = r1 + r1/2 * noise(t+420);
    //vertex(rout*cos(theta), 1.5*rout*sin(theta));
    float rAnther = random(0.8*rout, 1.2*rout);
    line(rin*cos(theta), 1/asp*rin*sin(theta), rAnther*cos(theta), rAnther*sin(theta));
    fill(#Db617c);
    stroke(#Db617c);
    ellipse(rAnther*cos(theta), rAnther*sin(theta), 4, 4);
    fill(0);
    stroke(0);
    t += dt;
    theta += random(0.5*deltaTheta, 1.5*deltaTheta);
  }
  endShape(CLOSE);
  popMatrix();
}

void setup() {
  size(400, 600);
  background(255);
  stroke(0);
  strokeWeight(2.0);
}

void draw() {
  smooth();
  //waterlilly()
  waterlilly(150, 150, 100, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(220, 225, 110, random(0.75, 1.25), random(-PI/4, PI/4));

  waterlilly(130, 330, 120, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(320, 230, 90, random(0.75, 1.25), random(-PI/4, PI/4));

  waterlilly(130, 460, 130, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(250, 320, 105, random(0.75, 1.25), random(-PI/4, PI/4));

  waterlilly(240, 460, 100, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(170, 535, 90, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(300, 520, 85, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(80, 140, 105, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(290, 100, 100, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(280, 140, 90, random(0.75, 1.25), random(-PI/4, PI/4));

  waterlilly(310, 290, 105, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(115, 235, 90, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(320, 410, 90, random(0.75, 1.25), random(-PI/4, PI/4));
  waterlilly(210, 65, 88, random(0.75, 1.25), random(-PI/4, PI/4));
  
  
    waterlilly(240, 310, 145, random(0.75, 1.25), random(-PI/4, PI/4));

  noLoop();
  saveFrame(String.format("/tmp/flower_%05d.png", round(random(99999))));
}

