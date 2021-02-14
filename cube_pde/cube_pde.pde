float x,y;
float rotAngle;
PImage img1, img2;

float [][] sharpenKernel = {
  {1.0/9.0, 1.0/9.0, 1.0/9.0},
  {1.0/9.0, 1.0/9.0, 1.0/9.0},
  {1.0/9.0, 1.0/9.0, 1.0/9.0}
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

boolean skipKernelPosition(int kPos, int iPos, int kHalf, int iDimension){
   int offset = kPos - kHalf;
   int pos = iPos + offset;
   return (pos < 0 || pos >= iDimension);
}


float getPixelAtPosition(color [][] pixels, int iWidth, int iHeight, int line, int col, float[][] kernel){
  
  int kernelS = kernel.length;
  
  int half = kernelS / 2;
  float result = 0;
  
  for(int i = 0 ; i < kernelS; i++){
    int lineOffset = i - half;
    boolean lineSkip = skipKernelPosition(i, line, half, iHeight);
    if(lineSkip)
      continue;
    int imgLine = line + lineOffset;
    for(int j = 0; j < kernelS; j++){
      int colOffset = j - half;
      boolean colSkip = skipKernelPosition(j, col, half, iWidth);
      if(colSkip)
        continue;
      int imgCol = col + colOffset;
      
      float weight = kernel[i][j];
      float value = red(pixels[imgLine][imgCol]); // Get any component, since image is in greyscale.
      result += weight * value;
    }
    
  }
  
  return result;
}

void applyFilter(PImage image, float[][] kernel){
  
  color[][] pixels = getPixelMatrix(image);
  int count = 0;
  
  for(int i = 0; i < image.height; i++){
    for(int j = 0; j < image.width; j++){
      
      float newValue = getPixelAtPosition(pixels, image.width, image.height, i, j, kernel);
      image.pixels[count] = color(newValue);
      count++;
    }
  }
  
  image.updatePixels();
}

void applySobelFilter(PImage image){
  
  float[][] gx ={
    {1, 0, -1},
    {2, 0, -2},
    {1, 0, -1}
  };
  
  float[][] gy ={
    {1, 2, 1},
    {0, 0, 0},
    {-1, -2, -1}
  };
  img2.filter(GRAY);
  //img2.filter(BLUR);
  
  color[][] pixels = getPixelMatrix(image);
  int count = 0;
  
  for(int i = 0; i < image.height; i++){
    for(int j = 0; j < image.width; j++){
      
      float xValue = getPixelAtPosition(pixels, image.width, image.height, i, j, gx);
      float yValue = getPixelAtPosition(pixels, image.width, image.height, i, j, gy);
      float newValue = sqrt(pow(xValue, 2) + pow(yValue, 2));
      image.pixels[count] = color(newValue);
      count++;
    }
  }
  
  image.updatePixels();
}


void setup() {
  size(1024,768,P3D);
  x = 100;
  y = height/2;
  rotAngle = 0;
  img1 = loadImage("engine.png");
  img2 = loadImage("engine.png");
  applySobelFilter(img2);
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
