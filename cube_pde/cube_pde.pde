float x,y,z;
float rotAngle;

void setup() {
  size(1024,768,P3D);
  x = width/2;
  y = height/2;
  z = 0;
  rotAngle = 0;
}

void draw() {
  background(0);
  translate(x, y);
  rotateX(radians(rotAngle));
  rotateY(radians(rotAngle));
  //rotateZ(radians(rotAngle));
  fill(255);
  beginShape(QUADS);
  vertex(-100, -100, 100);
  vertex( 100, -100, 100);
  vertex( 100,  100, 100);
  vertex(-100,  100, 100);
  
  vertex(-100, -100, -100);
  vertex( 100, -100, -100);
  vertex( 100,  100, -100);
  vertex(-100,  100, -100);
  
  vertex(-100, -100, 100);
  vertex(-100, -100, -100);
  vertex(-100, 100, -100);
  vertex(-100, 100, 100);
  
  vertex( 100,  -100, 100);
  vertex( 100,  -100, -100);
  vertex( 100,  100, -100);
  vertex( 100,  100, 100);
  
  vertex( -100,  -100, 100);
  vertex( -100,  -100, -100);
  vertex( 100,  -100, -100);
  vertex( 100,  -100, 100);
  
  vertex( -100,  100, 100);
  vertex( -100,  100, -100);
  vertex( 100,  100, -100);
  vertex( 100,  100, 100);
  
  
  endShape(CLOSE);
  
  rotAngle++;
  
  
}
