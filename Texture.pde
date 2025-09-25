// Built-in texture types.
final int txtTypeCrossHatching = 0;  // cross-hatching lines
final int txtTypeContour = 1;  // repeating contour lines in all patches in the painting
final int txtTypeGrain = 2;  // small random shaped blots yielding grainy effect
final int txtTypeUniformHorizonal = 3;  // equal-spaced horizontal lines
final int txtTypeUniformVertical = 4;  // equal-spaced vertical lines 
final int txtTypeFractalBranch = 5;  // fractally grown tree branches
final int txtTypeFractalEx = 6;
final String[] txtTypeNames = {
    "CROSS",
    "CONTOUR",
    "GRAIN",
    "HORIZONTAL",
    "VERTICAL",
    "FRTL-BRANCH",
    "FRRL-EX"
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

PGraphics drawTexture(Painting owner, int id, MunsellColor mcBackground, MunsellColor mcForeground, float density) 
{
  //DEBUG
  println("DrawTexture:", txtTypeNames[ctrlTextureType], id, mcBackground.getString(), mcForeground.getString(), density);

  int pi = owner.findPatchIdx(id);
  if (pi < 0)
    return null; // No patch is found with the id
  ColorPatch currPatch = owner.patches.get(pi);
    
  cursor(WAIT);
  float lineWidth = map(density, 0, 1, 1, 3);  // use thicker lines for higher density  
  color cBackground = colorTable.munsellToRGB(mcBackground);
  color cForeground = colorTable.munsellToRGB(mcForeground);

  int w = (int)(currPatch.xMax - currPatch.xMin + 1);
  int h = (int)(currPatch.yMax - currPatch.yMin + 1);
  
  PGraphics buffer = createGraphics(w, h);
  buffer.beginDraw();
  buffer.background(cBackground);
  if (cBackground == cForeground) {  // nothing further to be done
    buffer.endDraw();
    return buffer;
  }
  buffer.noFill();
  buffer.stroke(cForeground);
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
      density = min(density, 0.98);  // cap it so we avoid too many attempts
      while (lastDensity < density) {
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
          // draw
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
        lastDensity = getDensity(buffer, currPatch, cBackground, cForeground);
        if (lastDensity <= 0.001) {  // almost nothing has been drawn yet
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
    case txtTypeGrain: // Grain effect by random blots
    {
      int minSize = 5;
      int maxSize = 20;

      int total = (int)(w * h * min(density, 0.98));  // # of pixels to cover
      while (total > 0) {
        int size = (int)random(minSize, maxSize);
        ArrayList<PVector> q = new ArrayList<PVector>();
        q.add(new PVector(random(w), random(h)));  // start at random point  
        while (!q.isEmpty() && size > 0) {
          PVector pv = q.remove(0);
          if (pv.x < 0 || pv.x >= w || pv.y < 0 || pv.y >= h)
            continue;  // outsize the buffer area
          if (buffer.get((int)pv.x, (int)pv.y) == cForeground)
            continue;  // already covered
          buffer.set((int)pv.x, (int)pv.y, cForeground);
          size--;
          total--;
          if (random(1.0) < 0.5) q.add(new PVector(pv.x, pv.y - 1));
          if (random(1.0) < 0.5) q.add(new PVector(pv.x + 1, pv.y));
          if (random(1.0) < 0.5) q.add(new PVector(pv.x, pv.y + 1));
          if (random(1.0) < 0.5) q.add(new PVector(pv.x - 1, pv.y));
        }
      }
      break;
    }
    case txtTypeFractalBranch: // fractal - tree branches
    case txtTypeFractalEx:
    {
      //randomSeed(999);
      density = min(density, 0.98);  // cap it so we avoid too many attempts
      float lastDensity = 0.0;

      while (lastDensity < density) {
        // start a new growth from a random location
        ArrayList<FractalStem> stems = new ArrayList<FractalStem>();
        stems.add(new FractalStem(ctrlTextureType, new PVector(random(w), random(h)), random(360), 0));
      
        int count = 0;
        while (!stems.isEmpty() && count < 40) {
          FractalStem stem = stems.remove(0);
          if (stem.coord.x < 0 || stem.coord.x >= w || stem.coord.y < 0 || stem.coord.y >= h)
          {  // outside buffer
            continue;
          }
          // draw the stem
          stem.draw(buffer);
          count++;
          // generate child stems and explore them
          ArrayList<FractalStem> children = stem.generateChildren();
          stems.addAll(children);
        }
        // update density after each fractal
        lastDensity = getDensity(buffer, currPatch, cBackground, cForeground);
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
    float d = getDensity(buffer, currPatch, cBackground, cForeground);
    if (currPatch.getAreaSize() > 1000 && abs(d - density) > 0.2)
      println("BIG DENSITY GAP:", "id=" + currPatch.id, "size=" + currPatch.getAreaSize(), 
              "desired=" + density, "actual=" + d, "gap=" + (d - density));
  }
  return buffer;
}

class FractalStem
{
  public static final float minAngle = 10.0;
  public static final float maxAngle = 90.0;
  public static final float minLength = 10;
  public static final float maxLength = 100;
  public static final float minStems = 1;
  public static final float maxStems = 3;
  public static final float lengthRate = 0.8;
  
  int      type;  // fractal type
  PVector  coord;  // starting coordinate
  float    angle;  // angle to grow
  float    length;  // length to grow
  int      depth;  // fractal depth

  // Constructor
  public FractalStem(int t, PVector c, float a, int d)
  {
    type = t;
    coord = c;
    angle = a + random(minAngle, maxAngle) * ((random(1) < 0.5) ? 1 : -1);
    angle = round(angle) % 360;
    if (angle < 0) angle += 360;
    length = random(minLength, maxLength) * pow(lengthRate, d);
    depth = d;
  }
  // Generate child stems
  public ArrayList<FractalStem> generateChildren()
  {
    ArrayList<FractalStem> stems = new ArrayList<FractalStem>();
    int stemCount = (int)random(minStems, maxStems);
    for (int i = 0; i < stemCount; i++) {
      float d = random(length);
      FractalStem stem = new FractalStem(type, PVector.fromAngle(radians(angle)).mult(d).add(coord), angle, depth + 1);
      stems.add(stem);
    }
    return stems;
  }
  
  // Draw the stem
  public void draw(PGraphics buffer)
  {
    float lineWidth = 2.0 * pow(0.8, depth);
    buffer.beginShape();
    buffer.strokeWeight(lineWidth);
    buffer.curveVertex(coord.x, coord.y);
    buffer.curveVertex(coord.x, coord.y);
    float a = angle + random(-20, 20);
    PVector mid = PVector.fromAngle(radians(a)).mult(length / 2.0).add(coord);
    buffer.curveVertex(mid.x, mid.y);
    PVector end = PVector.fromAngle(radians(angle)).mult(length).add(coord);
    buffer.curveVertex(end.x, end.y);
    buffer.curveVertex(end.x, end.y);
    buffer.endShape();
  }
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
