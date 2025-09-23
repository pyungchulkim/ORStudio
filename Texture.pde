// Built-in texture types.
final int txtTypeCrossHatching = 0;
final int txtTypeContour = 1;
final int txtTypeUniformHorizonal = 2;
final int txtTypeUniformVertical = 3;
final int txtTypeFractal01 = 4;
final int txtTypeFractal02 = 5;
final String[] txtTypeNames = {
    "CROSS",
    "CONTOUR",
    "HORIZONTAL",
    "VERTICAL",
    "FRACTAL01",
    "FRACTAL02"
};

// The axis on which background/foreground color will lie
final int txtAxisValue = 0;
final int txtAxisChroma = 1;
final int txtAxisHue = 2;
final String[] txtAxisNames = {"VALUE", "CHROMA", "HUE"};

// Whether to use lower or higher H/V/C as background
final int txtBGHigh = 0;
final int txtBGLow = 1;
final String[] txtBGNames = {"HIGH", "LOW"};

PGraphics drawTexture(Painting owner, int id, MunsellColor mcBackground, MunsellColor mcLine, float density) 
{
  float lineWidth = map(density, 0, 1, 1, 3);  // use thicker lines for higher density

  //DEBUG
  println("ID:", id, mcBackground.getString(), mcLine.getString(), density);
  
  color cBackground = colorTable.munsellToRGB(mcBackground);
  color cLine = colorTable.munsellToRGB(mcLine);

  // Locate the patch
  ColorPatch currPatch = null;
  for (ColorPatch p : owner.patches)
    if (p.id == id) {
      currPatch = p;
      break;
    }
  if (currPatch == null)
    return null; //No patch is found with the id
    
  cursor(WAIT);
  int w = (int)(currPatch.xMax - currPatch.xMin + 1);
  int h = (int)(currPatch.yMax - currPatch.yMin + 1);
  
  PGraphics buffer = createGraphics(w, h);
  buffer.beginDraw();
  buffer.background(cBackground);
  buffer.noFill();
  buffer.stroke(cLine);
  buffer.strokeWeight(lineWidth);
  
  switch (ctrlTextureType) {
    case txtTypeCrossHatching: // uniformly distanced cross hatching
    {
      // Calculate thickness of the line crossing diagonal (slanted)
      float diagAngle = 2 * PVector.angleBetween(new PVector(w, 0), new PVector(w, h)) - PI / 2;
      float thickness = lineWidth / cos(diagAngle);
      float diag = sqrt(w * w + h * h);
      float numLines = density * diag / thickness;
      numLines *= 1 + density / 2; // adjust the effect of cross-hatching and random noise for higher density
      float dist = diag / numLines * 2;
      for (int i = 0; i < numLines / 2; i++)  // forward hatching for half
        buffer.line(i * 4 * w / numLines + random(-dist, dist), 0, 0, i * 4 * h / numLines + random(-dist, dist));
      for (int i = 0; i < numLines / 2; i++)  // backward hatching for another half
        buffer.line(w - i * 4 * w / numLines + random(-dist, dist), 0, w, i * 4 * h / numLines + random(-dist, dist));
      break;
    }
    case txtTypeContour: // repeat segment of contour lines of big patches in the painting
    {
      float lastDensity = 0;
      int batchSize = 2;
      int countTotal = 0;
      while (lastDensity < (density - 0.05)) {  // stop when the density is close enough
        while (batchSize-- > 0) {
          // randomly select a patch to use that:
          // - the shape is not cut by the edge of the image; and
          // - its size is not too small (> .2%) and not too big (< 25% of image)
          int idx = (int)random(owner.patches.size());
          for (int i = 0; i < owner.patches.size(); i++) {
            int j = (idx + i) % owner.patches.size();
            ColorPatch p = owner.patches.get(j);
            if (p.xMin > 0 && p.xMax < owner.imgWidth - 1 &&
                p.yMin > 0 && p.yMax < owner.imgHeight - 1 &&
                p.getAreaSize() > owner.imgWidth * owner.imgHeight * 0.002 &&
                p.getAreaSize() < owner.imgWidth * owner.imgHeight * 0.25)
            {
              idx = j;
              break;
            }
          }
          
          //ArrayList<PVector> contourPoints = owner.patches.get(idx).contourPoints;
          // prepare scale down copy of the selected patch
          ArrayList<PVector> contourPoints = new ArrayList<PVector>();
          float scale = 0.5 + random(0.5);
          for (PVector p : owner.patches.get(idx).contourPoints) {
            PVector v = new PVector(p.x * scale, p.y * scale);
            contourPoints.add(v);
          }
          
          // replicate a random segment of larger than half size
          int segStart = (int)random(contourPoints.size());
          int segLength = (int)random(contourPoints.size() / 2, contourPoints.size());
          PVector org = new PVector(random(w), random(h));
          
          buffer.beginShape();
          PVector ps = contourPoints.get(segStart);
          PVector pp = ps;
          for (int i = 0; i < segLength; i++) {
            PVector p = contourPoints.get((segStart + i)  % contourPoints.size());
            if (//p.x <= 0 || p.x >= owner.imgWidth - 1 || p.y <= 0 || p.y >= owner.imgHeight - 1 ||
                pp.dist(p) > 5)
              break;  // image edge or disconnected contour; stop
            pp = p;
            if (i % 10 == 0)
              buffer.curveVertex(org.x + p.x - ps.x, org.y + p.y - ps.y);
          }
          buffer.endShape();
          countTotal++;
        }
        
        // After done each batch, adjust the next batch size based upon
        // the density process so that each batch increases the density
        // roughly about [gap to goal, 0.05].
        lastDensity = getDensity(buffer, currPatch, cBackground, cLine);
        if (lastDensity <= 0.001) {  // almost nothing has been drawed yet
          batchSize = 2;
        }
        else {
          float dd = lastDensity / countTotal;  // avg density delta per count
          float goal = min(0.05, density - lastDensity);
          batchSize = (int)min(100, max(1, goal / max(dd, Float.MIN_VALUE)));
        }
      }
      break;
    }
    case txtTypeFractal01: // fractal 01
    {
      float nextAngle = 180.0;
      float nextLengthRate = 0.99;
      float minLength = 10;
    
      ArrayList<Apex> apexes = new ArrayList();
      apexes.add(new Apex(new PVector(0, 0), degrees(atan2(h, w)), 1.0, (float)w * 2));
      
      int apexCount = 0;
      while (!apexes.isEmpty()) {
        // Take out the first one
        Apex apexCurrent = apexes.remove(0);
        if (apexCount > 30000) break;
        //println("Apex:", apexCurrent.id, apexCurrent.coord.x, apexCurrent.coord.y, apexCurrent.angle, apexCurrent.length);
        
        // Draw the stem
        PVector stem = PVector.fromAngle(radians(apexCurrent.angle));
        stem.setMag(apexCurrent.length);
        PVector endCoord = PVector.add(apexCurrent.coord, stem);
        buffer.line(apexCurrent.coord.x, apexCurrent.coord.y, endCoord.x, endCoord.y);
        
        // Create new apexes
        float nl = apexCurrent.length * nextLengthRate * random(0.7, 1.0);
        if (nl > minLength) {
          for (int i = 0; i < 40; i++) {
            PVector coord = PVector.add(apexCurrent.coord, PVector.mult(stem, random(1.0)));
            if (coord.x > 0 && coord.x < w && coord.y > 0 && coord.y < h) {
              float na = (apexCurrent.angle + random(-nextAngle, nextAngle)) % 360;
              apexes.add(new Apex(coord, na, 1.0, nl));
            }
          }
        }
        apexCount++;
        if (apexCount % 100 == 0 && getDensity(buffer, currPatch, cBackground, cLine) >= density)
          break;
      }
      break;
    }
    case txtTypeUniformHorizonal: // uniform horizontal lines
    {
      float numLines = density * h / lineWidth;
      for (int i = 0; i < numLines; i++)
        buffer.line(0, i * h / numLines, w, i * h / numLines);
      break;
    }
    case txtTypeUniformVertical: // uniform vertical lines
    default:
    {
      float numLines = density * w / lineWidth;
      for (int i = 0; i < numLines; i++)
        buffer.line(i * w / numLines, 0, i * w / numLines, h);
      break;
    }
  }
  buffer.endDraw();
  cursor(ARROW);
  if (debug) {
    float d = getDensity(buffer, currPatch, cBackground, cLine);
    if (currPatch.getAreaSize() > 1000 && abs(d - density) > 0.2)
      println("BIG DENSITY GAP:", "id=" + currPatch.id, "size=" + currPatch.getAreaSize(), 
              "desired=" + density, "actual=" + d, "gap=" + (d - density));
  }
  return buffer;
}

// Obtain the density of the foreground color against the background color
// in the graphics buffer covered by the patch
float getDensity(PGraphics buffer, ColorPatch p, color cBG, color cFG)
{
  float r = 0.0;
  float g = 0.0;
  float b = 0.0;
  for (PVector v : p.points) {
    color c = buffer.get((int)(v.x - p.xMin), (int)(v.y - p.yMin));
    r += red(c);
    g += green(c);
    b += blue(c);
  }
  color avgColor = color(r / p.points.size(), g / p.points.size(), b / p.points.size());
  float bgDist = rgbDistance(avgColor, cBG);
  float fgDist = rgbDistance(avgColor, cFG);
  return bgDist / (bgDist + fgDist);
}

class Apex
{
  PVector  coord;
  float    angle;
  float    width;
  float    length;

  public Apex(PVector c, float a, float w, float l)
  {
    coord = c;
    angle = a;
    width = w;
    length = l;
  }
}
