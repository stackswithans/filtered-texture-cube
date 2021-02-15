class PixelData{
  
  float gradient;
  float direction;
  int strength;

  
  public PixelData(float gradient, float direction){
    this.gradient = gradient;
    this.strength = -1;

    if((direction >= 0 && direction <= 22.5) || (direction >= 157.5))
        this.direction = 0;
    else if(direction > 22.5 && direction <= 67.5)
        this.direction = 45;
    else if(direction > 67.5 && direction <= 112.5)
        this.direction = 90;
    else
        this.direction = 135;
  }
  
  
}


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



PixelData[][] applySobelFilter(PImage image, int blurLevel){
  
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
  image.filter(GRAY);
  if(blurLevel > 0)
    image.filter(BLUR, blurLevel);
    
    
  PixelData[][] gradientData = new PixelData[image.height][image.width];
  color[][] pixels = getPixelMatrix(image);
  int count = 0;
  
  for(int i = 0; i < image.height; i++){
    for(int j = 0; j < image.width; j++){
      
      float xValue = getPixelAtPosition(pixels, image.width, image.height, i, j, gx);
      float yValue = getPixelAtPosition(pixels, image.width, image.height, i, j, gy);
      float newValue = sqrt(pow(xValue, 2) + pow(yValue, 2));
      image.pixels[count] = color(newValue);
      float direction = abs(atan2(yValue, xValue));
      gradientData[i][j] = new PixelData(newValue, degrees(direction));
      count++;
    }
  }
  image.updatePixels();
  return gradientData;
}

void applyCannyOperator(PImage image){
    
    PixelData[][] gradientData = applySobelFilter(image, 1);

    //Non-maximum suppression
    image.loadPixels();
    int count = 0;
    for(int i = 0; i < image.height; i++){
        for(int j = 0; j < image.width; j++){
            PixelData data = gradientData[i][j];
            float maxValue = data.gradient;
            if(data.direction == 0){
                if(j > 0)
                    maxValue = max(maxValue, gradientData[i][j - 1].gradient);
                if(j < image.width - 1)
                    maxValue = max(maxValue, gradientData[i][j + 1].gradient);
            }
            else if(data.direction == 45){
                if(j < image.width - 1 && i > 0)
                    maxValue = max(maxValue, gradientData[i - 1][j + 1].gradient);
                if(j > 0 && i < image.height - 1)
                    maxValue = max(maxValue, gradientData[i + 1][j - 1].gradient);
                
            }
            else if(data.direction == 90){
                if(i > 0)
                    maxValue = max(maxValue, gradientData[i - 1][j].gradient);
                if(i < image.height - 1)
                    maxValue = max(maxValue, gradientData[i + 1][j].gradient);
                
            }
            else if(data.direction == 135){
                if(j > 0 && i > 0)
                    maxValue = max(maxValue, gradientData[i - 1][j - 1].gradient);
                if(j < image.width - 1 && i < image.height - 1)
                    maxValue = max(maxValue, gradientData[i + 1][j + 1].gradient);
            }
            if (maxValue != data.gradient){
                image.pixels[count] = color(0); //Supress pixel
                gradientData[i][j].gradient = 0;
            }
            count++;
        }
    }
    image.updatePixels();

    //Double-thresholding
    float maxThresh = 0.5;
    float minThresh = 0.3;

    image.loadPixels();
    color [][] pixels = getPixelMatrix(image);
    count = 0;
    for(int i = 0; i < image.height; i++){
        for(int j = 0; j < image.width; j++){
            PixelData data = gradientData[i][j];
            float intensity = data.gradient / 255.0;
            if(intensity < minThresh){
                image.pixels[count] = color(0);
                data.strength = 0;
            }
            else if(intensity > maxThresh){
                data.strength = 2;
                image.pixels[count] = color(255);
            }
            else{
                data.strength = 1;
            }
            count++;
        }
    }
    image.updatePixels();

    //Applying Hysteresis
    image.loadPixels();
    pixels = getPixelMatrix(image);
    count = 0;
    for(int i = 0; i < image.height; i++){
        for(int j = 0; j < image.width; j++){
            PixelData data = gradientData[i][j];
            if(data.strength != 1){
                count++;
                continue;
            }
            boolean connected = false;
            //Checking for connections to strong neighbours
            if(j > 0)
                connected = connected || (gradientData[i][j - 1].strength == 2);
            if(j < image.width - 1)
                connected = connected || (gradientData[i][j + 1].strength == 2);
            if(j < image.width - 1 && i > 0)
                connected = connected || (gradientData[i - 1][j + 1].strength == 2);
            if(j > 0 && i < image.height - 1)
                connected = connected || (gradientData[i + 1][j - 1].strength == 2);
            if(i > 0)
                connected = connected || (gradientData[i - 1][j].strength == 2);
            if(i < image.height - 1)
                connected = connected || (gradientData[i + 1][j].strength == 2);
            if(j > 0 && i > 0)
                connected = connected || (gradientData[i - 1][j - 1].strength == 2);
            if(j < image.width - 1 && i < image.height - 1)
                connected = connected || (gradientData[i + 1][j + 1].strength == 2);
            if(!connected){
                image.pixels[count] = color(0);
            }
            else
                image.pixels[count] = color(255);
            count++;
        }
    }
    image.updatePixels();
}

float x,y;
float rotAngle;
PImage img1, img2, img3;


void setup() {
  size(1200,768,P3D);
  x = width/2;
  y = 100;
  rotAngle = 0;
  img1 = loadImage("lizard.jpg");
  img1.resize(450, 250);
  img2 = loadImage("lizard.jpg");
  img2.resize(450, 250);
  img3 = loadImage("lizard.jpg");
  img3.resize(450, 250);
  applyCannyOperator(img2);
  applySobelFilter(img3, 0);
  textureMode(NORMAL);
}

void draw() {
  background(0);
  /*
  image(img1, x - (img1.width / 2), 100);
  image(img2, x - (img1.width / 2), y + img1.height + 100);
  image(img3, 1 , 100);*/
  drawCube(150);
}


void drawCube(float cSize){
  translate(width / 2, height / 2, -30);
  //rotateZ(radians(rotAngle));
  //scale(cSize, cSize, 0);
  //rotateX(radians(rotAngle));
  rotateY(radians(rotAngle));
  fill(255);


  beginShape(QUADS);
  texture(img1);
  vertex(-cSize, -cSize, cSize, 0, 0);
  vertex( cSize, -cSize, cSize, 1, 0);
  vertex( cSize,  cSize, cSize, 1, 1);
  vertex(-cSize,  cSize, cSize, 0, 1);
  endShape(CLOSE);
  
  beginShape(QUADS);
  texture(img2);
  vertex(-cSize, -cSize, -cSize, 0, 0);
  vertex( cSize, -cSize, -cSize, 1, 0);
  vertex( cSize,  cSize, -cSize, 1, 1);
  vertex(-cSize,  cSize, -cSize, 0, 1);
  endShape(CLOSE);
  
  beginShape(QUADS);
  texture(img3);
  vertex(-cSize, -cSize, cSize, 0, 0);
  vertex(-cSize, -cSize, -cSize, 1, 0);
  vertex(-cSize, cSize, -cSize, 1, 1);
  vertex(-cSize, cSize, cSize, 0, 1);
  endShape(CLOSE);
  
  beginShape(QUADS);
  fill(255, 255, 0);
  //texture(img3);
  vertex( cSize,  -cSize, cSize, 0, 0);
  vertex( cSize,  -cSize, -cSize, 1 ,0);
  vertex( cSize,  cSize, -cSize, 1, 1);
  vertex( cSize,  cSize, cSize, 0, 1);
  endShape(CLOSE);
  
  beginShape(QUADS);
  fill(0, 0, 255);
  //texture(img3);
  vertex( -cSize,  -cSize, cSize, 0, 0);
  vertex( -cSize,  -cSize, -cSize, 1, 0);
  vertex( cSize,  -cSize, -cSize, 1, 1);
  vertex( cSize,  -cSize, cSize, 0, 1);
  endShape(CLOSE);
  
  beginShape(QUADS);
  fill(0, 255, 0);
  //texture(img3);
  vertex( -cSize,  cSize, cSize, 0, 0);
  vertex( -cSize,  cSize, -cSize, 1, 0);
  vertex( cSize,  cSize, -cSize, 1, 1);
  vertex( cSize,  cSize, cSize, 0, 1);
  endShape(CLOSE);
  
  rotAngle++;  
}
