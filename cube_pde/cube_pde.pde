float x,y;
float rotAngle;
PImage img1, img2;

int [][] sharpenKernel = {
  {0, -1, 0},
  {-1, 5, -1},
  {0, -1, 0}
};



color[][] getPixelMatrix(PImage image){
  image.loadPixels();
  color [][] pixelMatrix = new color[image.height][image.width];
  
  int line = 0;
  int col = 0;
  
  for(int i = 0; i < image.width * image.height; i++){
    if(col == image.width){
        col = 0;
        line ++;
    }
    pixelMatrix[line][col] = image.pixels[i];
    col ++;
  }
  return pixelMatrix;
}

void getNeighbours(int line, int col, int n){
  
}

void convolute(PImage image, int[][] kernel){
}

void testGetPixelMatrix(PImage image){
  color [][] pixelMatrix = getPixelMatrix(image);
  int count = 0;
  for(int i = 0; i < img2.height; i++){
    for(int j = 0; j < img2.width; j++){
      color pixel = pixelMatrix[i][j];
      assert pixel == img2.pixels[count];
      count++;
    }
  }
}

void setup() {
  size(1024,768,P3D);
  x = 100;
  y = height/2;
  rotAngle = 0;
  img1 = loadImage("engine.png");
  img2 = loadImage("engine.png");
  img2.filter(GRAY);
  
}

void draw() {
  background(0);
  image(img1, x, y - (img1.height / 2));
  image(img2, x + img2.width + 200 , y - (img2.height / 2));
}


void drawCube(){
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
