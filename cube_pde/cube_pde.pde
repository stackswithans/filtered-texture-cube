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


void testFilterAccuracy(PImage refImg, PImage filterImg){
    refImg.filter(GRAY);
    filterImg.filter(GRAY);
    refImg.loadPixels();
    filterImg.loadPixels();

    float refSize = refImg.width * refImg.height;
    float filterSize = filterImg.width * filterImg.height;
    assert refSize == filterSize;

    float error = 0;
    for(int i = 0; i < refSize; i++){
        color refPix = refImg.pixels[i];
        color filterPix = filterImg.pixels[i];
        error += abs(red(filterPix) - red(refPix));
    }

    print("Error médio absoluto por pixel: ");
    print(error / refSize);
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
  if(blurLevel > 0)
    image.filter(BLUR, blurLevel);

  image.filter(GRAY);
    
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

void applyCannyDetector(PImage image, int blurLevel, float minThresh, float maxThresh){
    
    PixelData[][] gradientData = applySobelFilter(image, blurLevel);

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
PImage img1, img2, img3, img4, img5, img6;


void setup() {
  size(1200,768,P3D);
  x = width/2;
  y = 100;
  rotAngle = 0;

  String filename = "lizard.jpg";
  //Foto original
  img1 = loadImage(filename);

  //Foto com sobel (sem blur)
  img2 = loadImage(filename);
  applySobelFilter(img2, 0);
  img2.save("lizard_sobel.jpg");

  //Foto com sobel (com blur 3x3)
  img3 = loadImage(filename);
  applySobelFilter(img3, 1);
  img3.save("lizard_sobel_blur.jpg");
  println("Teste lizard_sobel:");
  testFilterAccuracy(loadImage("lizard_sobel_cv.jpg"), img3);

  //Foto com o canny(0.1 -- 0.3)
  img4 = loadImage(filename);
  applyCannyDetector(img4, 1, 0.1, 0.3);
  img4.save("lizard_canny_10_30.jpg");
  println("\nTeste lizard_canny_10_30:");
  testFilterAccuracy(loadImage("lizard_canny_10.0_30.0_cv.jpg"), img4);

  //Foto com o canny(0.2  -- 0.4)
  img5 = loadImage(filename);
  applyCannyDetector(img5, 1, 0.2, 0.4);
  img5.save("lizard_canny_20_40.jpg");
  println("\nTeste lizard_canny_20_40:");
  testFilterAccuracy(loadImage("lizard_canny_20.0_40.0_cv.jpg"), img5);

  //Foto com o canny(0.3  -- 0.5)
  img6 = loadImage(filename);
  applyCannyDetector(img6, 1, 0.3, 0.5);
  img6.save("lizard_canny_30_50.jpg");
  println("\nTeste lizard_canny_30_50:");
  testFilterAccuracy(loadImage("lizard_canny_30.0_50.0_cv.jpg"), img6);
  textureMode(NORMAL);
}


float xmag, ymag = 0;
float newXmag, newYmag = 0; 

void draw() {
  background(255);
  /*
  image(img1, x - (img1.width / 2), 100);
  image(img2, x - (img1.width / 2), y + img1.height + 100);
  image(img3, 1 , 100);*/
  newXmag = mouseX/float(width) * TWO_PI;
  newYmag = mouseY/float(height) * TWO_PI;
  
  float diff = xmag-newXmag;
  if (abs(diff) >  0.01) { 
    xmag -= diff/4.0; 
  }
  
  diff = ymag-newYmag;
  if (abs(diff) >  0.01) { 
    ymag -= diff/4.0; 
  }
  
  translate(width / 2, height / 2, -30);
  rotateX(-ymag); 
  rotateY(xmag);
  drawCube(150);
}


void drawCube(float cSize){

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
  texture(img4);
  vertex( cSize,  -cSize, cSize, 0, 0);
  vertex( cSize,  -cSize, -cSize, 1 ,0);
  vertex( cSize,  cSize, -cSize, 1, 1);
  vertex( cSize,  cSize, cSize, 0, 1);
  endShape(CLOSE);
  
  beginShape(QUADS);
  fill(0, 0, 255);
  texture(img5);
  vertex( -cSize,  -cSize, cSize, 0, 0);
  vertex( -cSize,  -cSize, -cSize, 1, 0);
  vertex( cSize,  -cSize, -cSize, 1, 1);
  vertex( cSize,  -cSize, cSize, 0, 1);
  endShape(CLOSE);
  
  beginShape(QUADS);
  fill(0, 255, 0);
  texture(img6);
  vertex( -cSize,  cSize, cSize, 0, 0);
  vertex( -cSize,  cSize, -cSize, 1, 0);
  vertex( cSize,  cSize, -cSize, 1, 1);
  vertex( cSize,  cSize, cSize, 0, 1);
  endShape(CLOSE);
  
  rotAngle++;  
}
