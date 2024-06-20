final float similarColorGap = 3;  // color gap that is considered similar
final float similarTensionGap = 4;  // tension gap that is considered similar
final float similarGrayGap = 1.5;  // gray gap that is considered similar
final float similarHueGap = 9;  // hue degree that is considered similar

// The Painter class to generate a collection of paintings that are optimized
// to the target parameters
public class Painter
{
  int maxPaintings;  // max # of paintings in the collection
  Painting master;  // the master specification for the collection of paintings
  ArrayList<MunsellColor> colors;  // colors to use for painting
  float[] targetComplexity;  // target complexity: min, max

  ArrayList<Painting> paintings;  // the paintings
  float avgComplexity;  // avg complexity of the current collection
  
  // Constructor from parameters
  public Painter(int n, Painting mp, Chord[] ch, MunsellColor c, float hv, float ts, float[] tc)
  {
    master = new Painting(mp, c, hv, ts);
    maxPaintings = n;
    targetComplexity = tc;
    
    // Obtain paint-ready colors from the chords
    colors = getColorsFromAllChords(ch);
    // Randomize them
    for (int i = 0; i < colors.size(); i++) {
      int j = (int)random(colors.size());
      MunsellColor mc = colors.get(i);
      colors.set(i, colors.get(j));
      colors.set(j, mc);
    }
  }
  
  // Initialize the collection of paintings based upon the master
  public boolean initialize(boolean forced)
  {
    paintings = new ArrayList<Painting>();
    
    // Populate initial paintings and calcuate their statistics
    boolean bSuccess = true;
    for (int i = 0; i < maxPaintings && bSuccess; i++) {
      Painting p = new Painting(master);
      if (!p.paint(colors) && !forced)
        bSuccess = false;
      p.updateStatistics();
      paintings.add(p);
    }
    calculateStats();
    
    return bSuccess;
  }
  
  // Calculate the average value of the parameters of the current paintings
  public void calculateStats()
  {
    avgComplexity = 0;

    for (Painting p : paintings) {
      avgComplexity += p.complexity;      
    }
    avgComplexity /= paintings.size();
  }

  public float optimize()
  {
    int dir = (avgComplexity < targetComplexity[0]) ? 1 :
              (avgComplexity > targetComplexity[1]) ? -1 : 0;
    if (dir != 0) {
      // Optimize for complexity
      for (Painting p : paintings) {
        p.optimizeForComplexity(dir, colors);
        p.updateStatistics();
      }
      calculateStats();
    }
    return avgComplexity;
  }
}

// Class for an individual painting: collection of patches
class Painting
{
  public int imgWidth, imgHeight;  // dimension of the painting
  public ArrayList<ColorPatch> patches;  // the patches. NOTE: not a copy but a reference.
  public MunsellColor centroid;  // the centroid color
  public float hueVariance;  // tolerable hue range from master hue
  public float tensionScale;  // scale factor for the master tension value
  
  float[] grayTension;  // statistics: gray tension and its complexity (entropy)
  float[] tension;  // statistics: color tension and its complexity (entropy)
  float tensionGap;  // MSE to the target tension
  float complexity;  // entropy of distinct colors and their areas
  
  // default constructor
  public Painting() {}
  
  // Constructor from patches
  public Painting(int w, int h, ArrayList<ColorPatch> p, MunsellColor mc)
  {
    imgWidth = w;
    imgHeight = h;
    patches = p;
    centroid = mc;
    hueVariance = 0;
    tensionScale = 1;
    updateStatistics();
  }

  // Copy constructor: copy everything with new painter parameters: centroid, 
  // hue range, tension scale. Note that it refreshes all stats if centroid is new.
  public Painting(Painting org, MunsellColor mc, float hv, float ts)
  {
    imgWidth = org.imgWidth;
    imgHeight = org.imgHeight;
    ArrayList<ColorPatch> newPatches = new ArrayList<ColorPatch>();
    for (ColorPatch p : org.patches) {
      newPatches.add(new ColorPatch(p));
    }
    patches = newPatches;
    centroid = new MunsellColor(mc);
    hueVariance = hv;
    tensionScale = ts;
    if (centroid.isEqual(org.centroid)) {  // all the stats remain the same
      grayTension = org.grayTension.clone();
      tension = org.tension.clone();
      tensionGap = org.tensionGap;
      complexity = org.complexity;
    }
    else {  // different centroid - stats need update
      updateStatistics();
    }
  }

  // Copy constructor: simple case that copies everything
  public Painting(Painting org)
  {
    this(org, org.centroid, org.hueVariance, org.tensionScale);
  }
  
  // Serialize to save
  public void Serialize(ObjectOutputStream oos) throws IOException
  {
    oos.writeInt(imgWidth);
    oos.writeInt(imgHeight);
    oos.writeInt(patches.size());
    for (ColorPatch p : patches) p.Serialize(oos);
    centroid.Serialize(oos);
    oos.writeFloat(hueVariance);
    oos.writeFloat(tensionScale);
    oos.writeFloat(grayTension[0]); oos.writeFloat(grayTension[1]);
    oos.writeFloat(tension[0]); oos.writeFloat(tension[1]);
    oos.writeFloat(tensionGap);
    oos.writeFloat(complexity);
  }

  // Deserialize to load
  public void Deserialize(ObjectInputStream ois) throws IOException, ClassNotFoundException
  {
    imgWidth = ois.readInt();
    imgHeight = ois.readInt();
    int i = ois.readInt();
    patches = new ArrayList<ColorPatch>();
    for (int j = 0; j < i; j++) {
      ColorPatch p = new ColorPatch(); p.Deserialize(ois);
      patches.add(p);
    }
    centroid = new MunsellColor(); centroid.Deserialize(ois);
    hueVariance = ois.readFloat();
    tensionScale = ois.readFloat();
    grayTension = new float[2]; grayTension[0] = ois.readFloat(); grayTension[1] = ois.readFloat();
    tension = new float[2]; tension[0] = ois.readFloat(); tension[1] = ois.readFloat();
    tensionGap = ois.readFloat();
    complexity = ois.readFloat();
  }

  // Update gap values of all patches relative to centroid.
  public void updateGap()
  {
    for (ColorPatch p : patches) {
      p.gGap = abs(p.mColor.value - centroid.value);
      p.cGap = p.mColor.getGap(centroid);
    }  
  }
  
  // Calculate color tension and tension complexity over all patches.
  // Color tension of a painting indicates how much color tension is
  // created by the patches in relation to surrounding color area (centroid).
  // I use mean square deviation (MSD) for the measurement of the tension.
  // Smaller MSD indicates that all patches are similar to centroid
  // while larger MSD indicates patches have quite different colors to centroid.
  // MSD is calculated as
  // MSD = sum((C(pi) - c)^2) / N, where C(pi) is the color of pixel pi,
  // c is the center color, N is the number of pixels.
  // Using the patches given, the same calculation is done as follows:
  // MSD = sum((color gap of patch)^2 * area of patch) / sum of all patch areas
  //
  // Unlike Tension as MSD (although highly related), Tension Complexity
  // measures how uniform (or diverse) the tensions are. Lower
  // tension complexity means that deviation from the center are more
  // uniform (deviation could still be high) across the picture area.
  // The tension complexity is measured as entropy over the tension distribution,
  // which is 0.5 * log(TWO_PI * variance) + 0.5.
  // For instance, variance of 20 yields complexity of 2.917.
  public void calculateTension()
  {
    grayTension = new float[2];  // gray tension (MSD), and its complexity (entropy).
    tension = new float[2];  // color tension (MSD), and its complexity (entropy).

    // Calculate MSD
    float sumG = 0, sumC = 0;
    float ssumG = 0, ssumC = 0;
    float area = 0;
    for (ColorPatch p : patches) {
      sumG += p.gGap * p.getArea();
      sumC += p.cGap * p.getArea();
      ssumG += p.gGap * p.gGap * p.getArea();
      ssumC += p.cGap * p.cGap * p.getArea();
      area += p.getArea();
    }
    float msdG = ssumG / area;
    float msdC = ssumC / area;
    
    // Calculate entropy over Gaussian variance
    float varG = (ssumG - sumG * sumG / area) / (area - 1);
    float varC = (ssumC - sumC * sumC / area) / (area - 1);
    float entropyG =  0.5 * log(TWO_PI * varG) + 0.5;
    float entropyC =  0.5 * log(TWO_PI * varC) + 0.5;
    
    grayTension[0] = msdG;
    grayTension[1] = entropyG;
    tension[0] = msdC;
    tension[1] = entropyC;
    
    // Calculate Tension gap as mean square error
    // TODO: The calculation is based up pixels (i.e., getArea()), 
    // but is our experience of tension "linear proportional" to the area?
    float ssumErr = 0;
    for (ColorPatch p : patches) {
      float td = p.cGap - p.masterTension;
      ssumErr += td * td * p.getArea();
    }
    tensionGap = ssumErr / area;
  }
  
  // Calculate Color Complexity.
  // Color Complexity is the measurement how easy (or hard) to describe the colors
  // in the image. Less number of colors being used would be less
  // complex (i.e., easier to explain). When there are many colors, 
  // it would be less complex as long as there are a few dominant colors
  // than there is no dominant color. Very low complex image could be boring while
  // very high complex image could be noisy.
  // Color complexity is measured by the information entropy of colors in the image.
  // The entropy indicates how many bits are needed to code the colors.
  // The entropy of the image (set of patches) are calculated as follows:
  // Suppose there are N distinct colors, C1, C2, ..., CN for all patches.
  // Pi is the probability of color Ci for any pixel in the image.
  // Entropy = -sum(Pi * log2(Pi)) for all Pi.
  // The max entropy is log2(N) when all Pi is the same, meaning equal amount of
  // each color appear in the image, while the min entropy is 0 when a Pi = 1,
  // meaning only one color is used.
  public void calculateComplexity()
  {
    HashMap<MunsellColor, Float> histogram = buildHistogram(similarColorGap);
  
    float totalArea = 0;
    for (Map.Entry<MunsellColor, Float> h : histogram.entrySet()) {
      totalArea += h.getValue();
    }

    complexity = 0;
    for (Map.Entry<MunsellColor, Float> h : histogram.entrySet()) {
      float pi = h.getValue() / totalArea;
      complexity -= pi * log(pi);
    }
  }
  
  // Build a color histogram - Area for each color
  public HashMap<MunsellColor, Float> buildHistogram(float gap)
  {
    HashMap<MunsellColor, Float> histogram = new HashMap<MunsellColor, Float>();
    
    for (ColorPatch p : patches) {
      MunsellColor mc = null;
      Float cnt = null;
      // See if the color is already in the histogram
      for (Map.Entry<MunsellColor, Float> h : histogram.entrySet()) {
        if (p.mColor.getGap(h.getKey()) < gap) {
          mc = h.getKey();
          cnt = h.getValue();
          break;
        }
      }
      if (mc != null) {  // Similar one is found; add the count.
        histogram.put(mc, cnt + p.getArea());
      }
      else {  // No similar color is found; create a new entry
        histogram.put(p.mColor, p.getArea());
      }
    }
    
    
    return histogram;
  }

  // Update all statistics of the painting
  public void updateStatistics()
  {
    updateGap();
    calculateTension();
    calculateComplexity();
  }
  
  // Update the painting:
  // 'what' indicates what part of the painting to update,
  // 'how' indicates how to update.
  // c1, c2 are the from/to colors to convert master hue for 'r' command
  public void update(int what, char how, MunsellColor mc1, MunsellColor mc2)
  {
    int dir;
    
    switch (how) {
      case 'p':  
      case 'P':  //  copy from current painting (gray, hue or tension)
        if (what == areaViewMGray)
          for (ColorPatch p : patches) p.masterGray = p.mColor.value;
        if (what == areaViewMHue)
          for (ColorPatch p : patches) 
            p.masterHue = p.mColor.isGray() ? -1 : p.mColor.hueDegree;
        if (what == areaViewMTension)
          for (ColorPatch p : patches) p.masterTension = p.cGap;
        break;
        
      case '+':  // scale up gray or tension by 10% from the current average
      case '-':  // scale down gray or tension by 10% from the current average
        dir = (how == '+') ? 1 : -1;
        if (what == areaViewMGray) {
          // Calculate the average
          float avg = 0;
          int n = 0;
          for (ColorPatch p : patches) {
            if (p.masterGray == 0) continue;
            avg += p.masterGray;
            n++;
          }
          avg /= n;
          // Scale by 10%
          for (ColorPatch p : patches) {
            if (p.masterGray == 0) continue;
            p.masterGray += dir * (p.masterGray - avg) * 0.1;
            p.masterGray = min(18, p.masterGray);  // cap it within [2, 18]
            p.masterGray = max(2, p.masterGray);
          }
        }
        if (what == areaViewMTension) {
          // Calculate the average
          float avg = 0;
          int n = 0;
          for (ColorPatch p : patches) {
            if (p.masterTension == 0) continue;
            avg += p.masterTension;
            n++;
          }
          avg /= n;
          // Scale by 10%
          for (ColorPatch p : patches) {
            if (p.masterTension == 0) continue;
            p.masterTension += dir * (p.masterTension - avg) * 0.1;
            p.masterTension = min(40, p.masterTension);  // cap it within [0.1, 40]
            p.masterTension = max(0.1, p.masterTension);
          }
        }        
        break;
        
      case '>':  // shift up gray or tension by 1.0
      case '<':  // shift down gray or tension by 1.0
        dir = (how == '>') ? 1 : -1;
        if (what == areaViewMGray) {
          for (ColorPatch p : patches) {
            if (p.masterGray == 0) continue;
            p.masterGray += dir;
            p.masterGray = min(18, p.masterGray);  // cap it within [2, 18]
            p.masterGray = max(2, p.masterGray);
          }
        }
        if (what == areaViewMTension) {
          for (ColorPatch p : patches) {
            if (p.masterTension == 0) continue;
            p.masterTension += dir;
            p.masterTension = min(40, p.masterTension);  // cap it within [0.1, 40]
            p.masterTension = max(0.1, p.masterTension);
          }
        }        
        break;

      case 'c':  // clear (reset) color, gray, hue or tension
      case 'C':
        if (what == areaViewColors)
          for (ColorPatch p : patches) p.setColor(munsellBlack);
        if (what == areaViewMGray)
          for (ColorPatch p : patches) p.masterGray = 0;
        if (what == areaViewMHue)
          for (ColorPatch p : patches) p.masterHue = -1;
        if (what == areaViewMTension)
          for (ColorPatch p : patches) p.masterTension = 0;
        break;
        
      case 'g':  // change the colors to gray
      case 'G':
        if (what == areaViewColors)
          for (ColorPatch p : patches) p.setColor(new MunsellColor(0, 0, p.mColor.value));
        break;
        
      case 'r':  // replace master hue or color from mc1 to mc2
      case 'R':
        if (what == areaViewMHue && mc1 != null && mc2 != null) {
          for (ColorPatch p : patches) {
            if (mc1.isGray() && p.masterHue < 0 ||
                !mc1.isGray() && p.masterHue >= 0 &&
                degreeDistance(mc1.hueDegree, p.masterHue) < similarHueGap)
            {
              p.masterHue = mc2.isGray() ? -1 : mc2.hueDegree;
            }
          }
        }
        if (what == areaViewColors && mc1 != null && mc2 != null) {
          for (ColorPatch p : patches) {
            if (mc1.getGap(p.mColor) < similarColorGap)
              p.setColor(mc2);
          }
        }
        break;
        
      default:
        break;
    }

    updateStatistics();  // Re-calculate stats against changed master
  }

  // Draw all color patches to the image.
  public void draw(PImage img, int kind)
  {
    for (ColorPatch p : patches) {
      p.draw(img, kind);
    }
  }

  // Find the patch index that contains the given pixel
  public int findPatch(int x, int y)
  {
    for (int i = 0; i < patches.size(); i++) {
      if (patches.get(i).contains(x, y))
        return i;
    }
    return -1;
  }

  // Plot coordinates of all patch colors to a square area.
  // xAngle and zAngle are used to rotate the coordinates.
  // All color points are layered so that closer ones (less y-value) shows on top of
  // farther ones (higher y-value).
  void plotColors(int x, int y, int s, float xAngle, float zAngle)
  {
    final float scaleMax = 20.0;  // cap the coordinates to this.
    
    // clear the area and draw x-axis, z-axis.
    fill(colorBG); stroke(colorEdge); 
    rect(x, y, s, s);
    line(x + s/2, y, x + s/2, y + s); 
    line(x, y + s/2, x + s, y + s/2); 
    
    pushMatrix();
    translate(x + s/2, y + s/2);
    noStroke();
    scale(s / (scaleMax * 2), s / (scaleMax * 2));  // scale everything to the range
    
    // HACK: Create a fake ColorPatch with the color of centroid and add it to
    // the patches so I handle centroid color point just as other points.
    ColorPatch fakePatch = new ColorPatch(patches.get(0));
    fakePatch.id = -1;
    fakePatch.setColor(centroid);
    patches.add(fakePatch);
    
    // Update coordinates of the colors of the patches for the screen space
    for (ColorPatch p : patches) {
      p.coord = p.mColor.getCoordinate().copy();
      p.coord.z = 10 - p.coord.z;  // fix z (value) coordinate centered at 0 
      rotateCoordinate(p.coord, xAngle, zAngle);
    }
    
    // Build an array over the patches and sort them
    // in the order of y so farthest comes first
    ColorPatch[] arrP = new ColorPatch[patches.size()];
    for (int i = 0; i < arrP.length; i++) {
      arrP[i] = patches.get(i);
    }
    Arrays.sort(arrP, Comparator.comparing((ColorPatch p) -> p.coord.y));
    
    // Display points
    for (ColorPatch p : arrP) {
      float m = scaleMax - 2; // scale coord so the circles are within the box
      float sx = max(-m, min(m, p.coord.x));
      float sy = max(-m, min(m, p.coord.y));
      float sz = max(-m, min(m, p.coord.z));
      float d = 2 + sy / scaleMax;  // circle size as 2 +- 1
      fill(p.rgbColor);
      if (p.id == -1) stroke(color(255));
      circle(sx, sz, d);
      if (p.id == -1) noStroke();
    }
    
    // Remove the fake patch
    patches.remove(fakePatch);
    popMatrix();
  }
  
  // Select a random color that meets master color specification from given colors
  // Matching master spec in the following order:
  // - similar gray level, if specified;
  // - similar hue, if specified
  // - similar match tension level, if specified
  // - pick any if nothing specified
  // A pure gray will be excluded for selection.
  MunsellColor selectColor(ColorPatch mp, ArrayList<MunsellColor> colors)
  {
    // Select color with less tension gap as possible
    MunsellColor nmc = null;
    for (float tensionGap = 2.0; tensionGap <= similarTensionGap; tensionGap += 2.0) {
      nmc = selectColorInternal(mp, colors, tensionGap);
      if (nmc != null)
        break;
    }
    return nmc;
  }
  
  MunsellColor selectColorInternal(ColorPatch mp, ArrayList<MunsellColor> colors, float tensionGap)
  {
    MunsellColor nmc = null;
    int s = (int)random(colors.size());  // random position to start searching
    for (int i = 0; i < colors.size() && nmc == null; i++) {
      MunsellColor c = new MunsellColor(colors.get((s + i) % colors.size()));
      if (c.isGray())
        continue;  // a pure gray is excluded from selection
      if (mp.masterGray > 0 && abs(c.value - mp.masterGray) > similarGrayGap) {  
        // master gray level is specified, but it is not similar
        continue;
      }
      if (mp.masterHue >= 0) {  
        // master hue is specified; match if is within the hue range
        if (degreeDistance(mp.masterHue, c.hueDegree) > hueVariance)
          continue;  // too far from the master hue
      }
      if (mp.masterTension > 0 && abs(mp.masterTension - centroid.getGap(c)) > tensionGap) {
        // master tension is specified, but it is too far from the centroid
        continue;
      }
      // It's a match (or no master restriction)
      nmc = c;
    }
  
    return nmc;
  }
  
  // Paint all the patches with the colors according to the master color specification.
  // Any patch that cannot find a color meeting the master specification will
  // be painted as pure black and the function will return false.
  boolean paint(ArrayList<MunsellColor> colors)
  {
    // Reset to pure black first to indicate failed patches, if any
    for (ColorPatch p : patches)
      p.setColor(munsellBlack);
      
    if (colors.size() < 1)
      return false;
  
    // Scale master tension by the scale factor
    for (ColorPatch p : patches) {
      if (p.masterTension > 0)
        p.masterTension *= tensionScale;
    }
    
    boolean bSuccess = true;
     
    // Paint the patches
    for (ColorPatch p : patches) {
      MunsellColor mc = selectColor(p, colors);
      if (mc == null) {
        bSuccess = false;
      }
      else
        p.setColor(mc);     
    }
    
    // Reset the scale of master tension
    for (ColorPatch p : patches) {
      if (p.masterTension > 0)
        p.masterTension /= tensionScale;
    }
    
    return bSuccess;
  }

  // Replace colors to toward complexity direction: negative for reduce,
  // positive for increase.
  public void optimizeForComplexity(int dir, ArrayList<MunsellColor> colors)
  {
    float rate = 0.5;
    
    // Build the existing colors
    ArrayList<MunsellColor> colorsExisting = new ArrayList<MunsellColor>();
    for (ColorPatch p : patches) {
      colorsExisting.add(p.mColor);
    }
    
    for (int i = 0; i < patches.size(); i++) {
      if (random(1) > rate)
        continue;
        
      ColorPatch p = patches.get(i);
      // skip unpainted patch
      if (p.mColor.isEqual(munsellBlack))
        continue;

      if (dir < 0) {  
        // need to reduce complexity; replace with another existing color
        colorsExisting.set(i, munsellBlack);  // take it out
        MunsellColor mc = selectColor(p, colorsExisting);
        if (mc != null)
          p.setColor(mc);
        colorsExisting.set(i, p.mColor);  // put the new one back
      }
      if (dir > 0) {  
        // need to increase complexity; try a new color up to 5 times.
        for (int j = 0; j < 5; j++) {
          MunsellColor mc = selectColor(p, colors);
          if (mc != null && mc.getGap(p.mColor) > similarColorGap) {
            p.setColor(mc);
            break;
          }
        }
      }
    }
  }
  
  // Save the color palette of the painting to a file
  void savePalette(String pathName)
  {
    int maxCols = 4;
    int maxRows = 20;
    int maxColors = maxCols * maxRows;
    
    // Obtain a histogram of all distinct colors
    HashMap<MunsellColor, Float> histogram = buildHistogram(0.1);
    
    // Sort them by area
    List<Map.Entry<MunsellColor, Float> > list = new LinkedList<Map.Entry<MunsellColor, Float> >(histogram.entrySet());
    Collections.sort(list, Comparator.comparing((Map.Entry<MunsellColor, Float> e) -> -e.getValue()));

    // Extract the first maxColors and sort them in the order of hue/value/chroma
    MunsellColor[] arrMC = new MunsellColor[min(maxColors, list.size())];
    for (int i = 0; i < maxColors && i < list.size(); i++) {
      arrMC[i] = list.get(i).getKey();
    }
    Arrays.sort(arrMC, Comparator.comparing((MunsellColor mc) -> mc.hueDegree * 10000 + mc.value * 100 + mc.chroma));
    
    // Save it to the file
    int cellWidth = 200;
    int cellHeight = 50;
    PGraphics pg = createGraphics(cellWidth * maxCols, cellHeight * maxRows);
    int col = 0;
    int row = 0;
    pg.beginDraw();
    pg.noStroke();
    pg.fill(color(255));
    pg.rect(0, 0, pg.width, pg.height);
    pg.textFont(createFont("Arial", 18)); pg.textAlign(LEFT, TOP); 
    for (MunsellColor mc : arrMC) {
      pg.fill(colorTable.munsellToRGB(mc));
      pg.rect(col * cellWidth, row * cellHeight, cellHeight - 10, cellHeight - 10);
      pg.fill(color(0));
      pg.text(mc.getString(), col * cellWidth + cellHeight, row * cellHeight + 2);
      String s = String.format("%,dK", round(histogram.get(mc) / 1000));
      pg.text(s, col * cellWidth + cellHeight, row * cellHeight + cellHeight / 2);
      row++;
      if (row == maxRows) {
        col++;
        if (col == maxCols)
          col = 0;
        row = 0;
      }
    }
    pg.endDraw();
    pg.save(pathName);
  }
}

// Build a set of color patches from the image.
// Each patch must be contoured with cContour color.
// Patches are first built from imgSrc and then
// all coordinates are scaled to imgScaleTo
Painting buildPatchesFromContour(PImage imgSrc, color cContour, PImage imgScaleTo) 
{
  color cVisited = color(128);  // use gray to mark visited while traversal
  color cDone = color(255);  // use white to mark done after a patch is done
  ArrayList<ColorPatch> patches = new ArrayList<ColorPatch>();
  PImage imgMark = createImage(imgSrc.width, imgSrc.height, RGB);  // to mark done or visited

  for (int i = 0; i < imgSrc.width; i++) {
    for (int j = 0; j < imgSrc.height; j++) {
      color s = imgSrc.get(i, j);
      color m = imgMark.get(i, j);
      if (m == cDone || rgbDistance(s, cContour) < contourColorThreshold)
        continue;  // done in previous patch or a contour line

      // Create a new patch and add the points and contour to the patch
      // using floodfill algorithm.
      ArrayList<PVector> points = new ArrayList<PVector>();
      ArrayList<PVector> contourPoints = new ArrayList<PVector>();
      
      Stack<PVector> ps = new Stack<PVector>();
      ps.push(new PVector(i, j));      
      while (!ps.empty()) {
        PVector pv = ps.pop();
        int px = (int)pv.x;
        int py = (int)pv.y;
        s = imgSrc.get(px, py);
        m = imgMark.get(px, py);
        if (m == cVisited)
          continue;  // Already visited this pixel.
          
        if (rgbDistance(s, cContour) < contourColorThreshold ||
            px == 0 || px == imgSrc.width - 1 || py == 0 || py == imgSrc.height - 1) {
          // Has reached the contour or the image boundary
          contourPoints.add(pv);
        }
        else {
          // Has reached a new pixel; store and mark it visited
          points.add(pv);
          imgMark.set(px, py, cVisited);

          // Visit pixels that are adjacent either vertically or horizontally.
          if (px + 1 < imgSrc.width)
            ps.push(new PVector(px + 1, py));
          if (px - 1 >= 0)
            ps.push(new PVector(px - 1, py));
          if (py + 1 < imgSrc.height)
            ps.push(new PVector(px, py + 1));
          if (py - 1 >= 0)
            ps.push(new PVector(px, py - 1));
        }
      }
      if (points.size() > minPatchSize) {
        ColorPatch p = new ColorPatch(patches.size(), imgSrc, points);
        patches.add(p);
        p.drawPoints(imgMark, cDone); // mark its area and contour as done
      }
    }
  }

  if (imgScaleTo != null) {
    float xScale = (float)imgScaleTo.width / imgSrc.width;
    float yScale = (float)imgScaleTo.height / imgSrc.height;
    
    for (ColorPatch p : patches) {
      p.scale(xScale, yScale);
    }
  }
  else
    imgScaleTo = imgSrc;
  
  // Calculate centroid
  float areaSum = 0;
  MunsellColor centroid = null;
  for (ColorPatch p : patches) {
    centroid = (centroid == null) ? p.mColor : centroid.getMixture(p.mColor, p.getArea() / areaSum);
    areaSum += p.getArea();
  }
  
  return new Painting(imgScaleTo.width, imgScaleTo.height, patches, centroid);
}

// Build a set of color patches from the image.
// Each distinct color creates a separate patch.
// Patches are first built from imgSrc and then
// all coordinates are scaled to imgScaleTo
Painting buildPatchesFromSolid(PImage imgSrc, PImage imgScaleTo) 
{
  ArrayList<ColorPatch> patches = new ArrayList<ColorPatch>();
  HashMap<Integer, ArrayList<PVector> > map = new HashMap<Integer, ArrayList<PVector> >();

  for (int i = 0; i < imgSrc.width; i++) {
    for (int j = 0; j < imgSrc.height; j++) {
      Integer c = imgSrc.get(i, j);
      // Skip an island pixel - this will reduce # of patches to cover trivial
      // pixels that might have been created by gradation of paint brush tools.
      if (c != imgSrc.get(i - 1, j - 1) && c != imgSrc.get(i, j - 1) && c != imgSrc.get(i + 1, j - 1) &&
          c != imgSrc.get(i - 1, j) && c != imgSrc.get(i + 1, j) &&
          c != imgSrc.get(i - 1, j + 1) && c != imgSrc.get(i, j + 1) && c != imgSrc.get(i + 1, j + 1))
        continue;

      // See if the color is already in the map
      ArrayList<PVector> pts = map.get(c);
      if (pts == null) {
        // a new color: create a new points vector and put it to the map
        pts = new ArrayList<PVector>();
        pts.add(new PVector(i, j));
        map.put(c, pts);
      }
      else {
        pts.add(new PVector(i, j));
      }
    }
  }
    
  // Create all patches from the map
  for (Map.Entry<Integer, ArrayList<PVector> > m : map.entrySet()) {
    ArrayList<PVector> pts = m.getValue();
    if (pts.size() > minPatchSize) {
      ColorPatch p = new ColorPatch(patches.size(), imgSrc, pts);
      patches.add(p);
    }
  }
  
  if (imgScaleTo != null) {
    float xScale = (float)imgScaleTo.width / imgSrc.width;
    float yScale = (float)imgScaleTo.height / imgSrc.height;
    
    for (ColorPatch p : patches) {
      p.scale(xScale, yScale);
    }
  }
  else
    imgScaleTo = imgSrc;
  
  // Calculate centroid
  float areaSum = 0;
  MunsellColor centroid = null;
  for (ColorPatch p : patches) {
    centroid = (centroid == null) ? p.mColor : centroid.getMixture(p.mColor, p.getArea() / areaSum);
    areaSum += p.getArea();
  }
  
  return new Painting(imgScaleTo.width, imgScaleTo.height, patches, centroid);
}

// Euclidean distance between the two RGB colors
float rgbDistance(color c1, color c2) 
{
  if (c1 == c2) return 0;  // special case optimization
  
  float rd = red(c1) - red(c2);
  float gd = green(c1) - green(c2);
  float bd = blue(c1) - blue(c2);
  return sqrt(rd * rd + gd * gd + bd * bd);
}

void rotateCoordinate(PVector coord, float xAngle, float zAngle) 
{
  float xRadian = radians(xAngle);
  float zRadian = -radians(zAngle);

  // Calculate the transformation matrix
  PVector xv = new PVector(cos(zRadian), -sin(zRadian) * cos(xRadian), sin(zRadian) * sin(xRadian));
  PVector yv = new PVector(sin(zRadian), cos(zRadian) * cos(xRadian), -cos(zRadian) * sin(xRadian));
  PVector zv = new PVector(0, sin(xRadian), cos(xRadian));
  
  // Calculate the new coordinates
  PVector org = coord.copy();
  coord.x = org.dot(xv);
  coord.y = org.dot(yv);
  coord.z = org.dot(zv);
}

// Get the degree difference
float degreeDistance(float d1, float d2)
{
  float a = abs(d1 - d2);
  if (a > 180) a = 360 - a;
  return a;
}
