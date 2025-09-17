// Built-in texture types - it needs to be [1,10] as it is used in slider range
// and 1 being default.
final int txtTypeCrossHatching = 1; // uniformly distanced cross hatching
final int txtTypeContour = 2;  // repeating contour from patches in the painting
final int txtTypeUniformHorizonal = 3;  // uniformly distanced horizontal lines
final int txtTypeUniformVertical = 4;  // uniformly distanced vertical lines
final int txtTypeFractal01 = 5;  // fractal 01

final int txtLineWidth = 1;  // drawing line width for texture

PGraphics drawTexture(Painting owner, int id, MunsellColor mcBackground, MunsellColor mcLine, float density) 
{
  int type = ctrlTextureType;
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
  buffer.noSmooth();  // no pixel interpolation
  buffer.beginDraw();
  buffer.background(cBackground);
  buffer.noFill();
  buffer.stroke(cLine);
  buffer.strokeWeight(txtLineWidth);
  
  switch (type) {
    case txtTypeCrossHatching: // uniformly distanced cross hatching
    {
      // Calculate thickness of the line crossing diagonal (slanted)
      float diagAngle = 2 * PVector.angleBetween(new PVector(w, 0), new PVector(w, h)) - PI / 2;
      float thickness = txtLineWidth / cos(diagAngle);
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
    case txtTypeContour: // repeat segment of contour lines
    {
      float prevDensity = 0;
      int densityInterval = 5;
      int count = 0;
      while (count < 100000) {
        // randomly select a patch whose contour will be used
        int idx = -1;
        for (int i = 0; i < owner.patches.size(); i++) {
          idx = (int)random(owner.patches.size());
          if (owner.patches.get(idx).getAreaSize() > owner.imgWidth * owner.imgHeight * 0.02)
            break;
        }
        
        ArrayList<PVector> contourPoints = owner.patches.get(idx).contourPoints;
        
        int segStart = (int)random(contourPoints.size());
        int segLength = (int)random(contourPoints.size() / 5, contourPoints.size() / 2);
        PVector org = new PVector(random(w), random(h));
        
        buffer.beginShape();
        PVector ps = contourPoints.get(segStart);
        PVector pp = ps;
        for (int i = 0; i < segLength; i++) {
          PVector p = contourPoints.get((segStart + i)  % contourPoints.size());
          if (pp.dist(p) > 2)
            break;  // disconnected contour; stop
          pp = p;
          if (i % 10 == 0) {
            if (p.x > 0 && p.x < owner.imgWidth - 1 && p.y > 0 && p.y < owner.imgHeight - 1)
              buffer.curveVertex(org.x + p.x - ps.x, org.y + p.y - ps.y);
          }
        }
        buffer.endShape();
        
        count++;
        
        // Check the density periodicall to see if we're done.
        // The check interval gets adjusted depending on speed of progress.
        // Also, early break if it looks like we end up over done.
        if (count % densityInterval == 0) {
          float d = getDensity(buffer, currPatch, cLine);
          if (d + (d - prevDensity) >= density)
            break;
          densityInterval *= (d - prevDensity < 0.05) ? 1.2 : 0.8;
          densityInterval = min(1000, max(2, densityInterval));
          prevDensity = d;
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
        if (apexCount % 100 == 0 && getDensity(buffer, currPatch, cLine) >= density)
          break;
      }
      break;
    }
    case txtTypeUniformHorizonal: // uniform horizontal lines
    case txtTypeUniformVertical: // uniform vertical lines
    default:
    {
      if (type == txtTypeUniformVertical) {
        float numLines = density * w / txtLineWidth;
        for (int i = 0; i < numLines; i++)
          buffer.line(i * w / numLines, 0, i * w / numLines, h);
      }
      else {
        float numLines = density * h / txtLineWidth;
        for (int i = 0; i < numLines; i++)
          buffer.line(0, i * h / numLines, w, i * h / numLines);
      }
      break;
    }
  }
  buffer.endDraw();
  cursor(ARROW);
  float d = getDensity(buffer, currPatch, cLine);
  println("Density:", "id=" + currPatch.id, "desired=" + density, 
      "actual=" + d, "gap=" + (d - density), abs(d - density) > 0.2 ? "BIG" : "");
  return buffer;
}

// Obtain the density of the given color in the graphics buffer
// within the area by the patch.
float getDensity(PGraphics buffer, ColorPatch p, color c)
{
  float sum = 0.0;
  for (PVector v : p.points) {
    if (buffer.get((int)(v.x - p.xMin), (int)(v.y - p.yMin)) == c)
      sum++;
  }
  return sum / p.getAreaSize();
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
