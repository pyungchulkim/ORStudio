final float similarColorGap = 2;  // color gap that is considered similar
final float similarTensionGap = 4;  // tension gap that is considered similar
final float similarHueGap = 9;  // hue degree gap that is considered similar
final float similarChromaGap = 2;  // chroma gap that is considered similar
final float similarValueGap = 1;  // value gap that is considered similar

// flag to show reference lines in transition view
boolean bShowReferenceLine = false;
boolean bClearNeeded = false;

// The Painter class to generate a collection of paintings that are optimized
// to the target parameters
public class Painter
{
  Painting master;  // the master specification for the collection of paintings
  ArrayList<MunsellColor> colors;  // colors to use for painting
  int maxPaintings;  // max # of paintings in the collection
  MunsellColor centroid;  // the centroid to use to calcualte master tension
  float hueVariance;  // variance to apply to adjust master hue
  float tensionScale;  // scale to apply to adjust master tension spec
  float[] targetComplexity;  // target complexity: min, max

  ArrayList<Painting> paintings;  // the paintings
  int currPaintingIdx;  // current painting to work on
  
  // Constructor from parameters
  public Painter(Painting mp, Chord[] ch, int n, MunsellColor c, float hv, float ts, float[] tc)
  {
    master = mp;
    
    // Obtain paint-ready colors from the chords
    colors = getColorsFromAllChords(ch);
    // Randomize them
    for (int i = 0; i < colors.size(); i++) {
      int j = (int)random(colors.size());
      MunsellColor mc = colors.get(i);
      colors.set(i, colors.get(j));
      colors.set(j, mc);
    }
    
    maxPaintings = n;
    centroid = c;
    hueVariance = hv;
    tensionScale = ts;
    targetComplexity = tc;
  }
  
  // Initialize the collection of paintings based upon the master
  public void initialize()
  {
    paintings = new ArrayList<Painting>();
    
    // Populate initial paintings with no colors
    for (int i = 0; i < maxPaintings; i++) {
      Painting p = new Painting(master);
      // reset as unpainted
      for (ColorPatch cp : p.patches)
        cp.mColor = munsellBlack;
      p.updateStatistics();
      paintings.add(p);
    }
    currPaintingIdx = 0;
  }
  
  // Paint (or optimize if already painted) the current painting and 
  // return its index.
  public int paintOne()
  {
    Painting p = paintings.get(currPaintingIdx);
    if (p.coverage < 0.01) {  // consider not painted yet
      p.paint(colors, centroid, hueVariance, tensionScale);
      p.updateStatistics();
    }
    else {  // painted already - optimize if needed
      int dir = (p.complexity < targetComplexity[0]) ? 1 :
                (p.complexity > targetComplexity[1]) ? -1 : 0;
      if (dir != 0) {
        // Optimize for complexity
        p.optimizeForComplexity(dir, colors, centroid, hueVariance, tensionScale);
        p.updateStatistics();
      }
    }

    int ret = currPaintingIdx;
    currPaintingIdx++;
    if (currPaintingIdx == paintings.size())
      currPaintingIdx = 0;
      
    return ret;
  }
}

// Class for an individual painting: collection of patches
class Painting
{
  public int imgWidth, imgHeight;  // dimension of the painting
  public ArrayList<ColorPatch> patches;  // the patches
  public MunsellColor centroid;  // the centroid color
  float tension;  // statistics: color tension
  float tensionComplexity;  // statistics: color tension complexity (entropy)
  float complexity;  // statistics: color complexity (entropy)
  float coverage;  // statistics: percentage of area that have been painted
  
  // default constructor
  public Painting() {}
  
  // Constructor from patches
  public Painting(int w, int h, ArrayList<ColorPatch> ps)
  {
    imgWidth = w;
    imgHeight = h;
    patches = ps;
    
    updateStatistics();
  }

  // Copy constructor: copy everything from a painting.
  public Painting(Painting org)
  {
    imgWidth = org.imgWidth;
    imgHeight = org.imgHeight;
    ArrayList<ColorPatch> newPatches = new ArrayList<ColorPatch>();
    for (ColorPatch p : org.patches)
      newPatches.add(new ColorPatch(p));
    patches = newPatches;
    centroid = new MunsellColor(org.centroid); //<>//
    tension = org.tension;
    tensionComplexity = org.tensionComplexity;
    complexity = org.complexity;
    coverage = org.coverage;
  }

  // Serialize to save
  public void Serialize(ObjectOutputStream oos) throws IOException
  {
    oos.writeInt(imgWidth);
    oos.writeInt(imgHeight);
    oos.writeInt(patches.size());
    for (ColorPatch p : patches) p.Serialize(oos);
    centroid.Serialize(oos);
    oos.writeFloat(tension);
    oos.writeFloat(tensionComplexity);
    oos.writeFloat(complexity);
    oos.writeFloat(coverage);
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
    tension = ois.readFloat();
    tensionComplexity = ois.readFloat();
    complexity = ois.readFloat();
    coverage = ois.readFloat();
  }
  
  // Update centroid.
  public void updateCentroid()
  {
    centroid = null;
    float areaSum = 0;
    for (ColorPatch p : patches) {
      centroid = (centroid == null) ? p.mColor : centroid.getMixture(p.mColor, p.getAreaSize() / areaSum);
      areaSum += p.getAreaSize();
    }
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
  // created by the patches in relation to average color of the painting (centroid).
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
    // Calculate MSD
    float sum, ssum, area;
    sum = ssum = area = 0;
    for (ColorPatch p : patches) {
      sum += p.cGap * p.getAreaSize();
      ssum += p.cGap * p.cGap * p.getAreaSize();
      area += p.getAreaSize();
    }
    tension = ssum / area;
    
    // Calculate entropy over Gaussian variance
    float v = (ssum - sum * sum / area) / (area - 1);
    tensionComplexity = 0.5 * log(TWO_PI * v) + 0.5;
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
      if (mc != null && cnt != null) {  // Similar one is found; add the count.
        histogram.put(mc, cnt + p.getAreaSize());
      }
      else {  // No similar color is found; create a new entry
        histogram.put(p.mColor, p.getAreaSize());
      }
    }
    
    return histogram;
  }

  // Update all statistics of the painting
  public void updateStatistics()
  {
    updateCentroid();
    updateGap();
    calculateTension();
    calculateComplexity();
    float areaTotal, areaNotPainted;
    areaTotal = areaNotPainted = 0;
    for (ColorPatch p : patches) {
      areaTotal += p.getAreaSize();
      if (p.mColor.isGray())
        areaNotPainted += p.getAreaSize();
    }
    coverage = 1 - areaNotPainted / areaTotal;
  }
  
  // Update the painting:
  // 'what' indicates what part of the painting to update,
  // 'how' indicates how to update.
  // c1, c2 are the from/to colors to convert master hue for 'r' command.
  // If the update affects stats, it will update statistics as well.
  public void update(int what, char how, MunsellColor mc1, MunsellColor mc2)
  {
    int dir;
    boolean bUpdateStats = false;  // indicate stats to be updated
    
    switch (how) {
      case 'p':  
      case 'P':  //  copy from current painting (gray, hue or tension)
        if (what == areaViewMGray)
          for (ColorPatch p : patches) 
            p.masterGray = p.mColor.value;
        if (what == areaViewMHue)
          for (ColorPatch p : patches) {
            p.masterHue = p.mColor.isGray() ? -1 : p.mColor.hueDegree;
            p.masterChroma = p.mColor.isGray() ? -1 : p.mColor.chroma;
          }
        if (what == areaViewMTension)
          for (ColorPatch p : patches) 
            p.masterTension = p.cGap;
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
        
      case '>':  // shift up gray or tension by 1.0 or chroma by 2.0
      case '<':  // shift down gray or tension by 1.0 or chroma by 2.0
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
        if (what == areaViewMHue) {
          dir *= 2;
          for (ColorPatch p : patches) {
            if (p.masterChroma <= 0) continue;
            p.masterChroma += dir;
            // cap it within max chroma
            p.masterChroma = max(2, min(colorTable.getMaxChroma(p.masterHue), p.masterChroma));
          }
        }
        if (what == areaViewColors) {
          dir *= 2;
          for (ColorPatch p : patches) {
            if (p.mColor.isGray()) continue;
            MunsellColor mc = new MunsellColor(p.mColor);
            mc.chroma += dir;
            // cap it within max chroma of the value
            mc.chroma = max(2, min(colorTable.getMaxChroma(mc.hueDegree, mc.value), mc.chroma));
            p.setColor(mc);
          }
          bUpdateStats = true;
        }
        break;

      case 'C':
      case 'c':  // clear (reset) color, gray, hue or tension
        if (what == areaViewColors) {
          for (ColorPatch p : patches) 
            p.setColor(munsellBlack);
          bUpdateStats = true;
        }
        if (what == areaViewMGray)
          for (ColorPatch p : patches) 
            p.masterGray = 0;
        if (what == areaViewMHue)
          for (ColorPatch p : patches) 
            p.masterHue = p.masterChroma = -1;
        if (what == areaViewMTension)
          for (ColorPatch p : patches) 
            p.masterTension = 0;
        if (what == areaViewMTransition) {
          for (ColorPatch p : patches) {
            p.masterTransition = "";
            p.transParsed = false;
          }
        }
        break;
        
      case 'G':
      case 'g':  // change the colors to gray
        if (what == areaViewColors) {
          for (ColorPatch p : patches) 
            p.setColor(new MunsellColor(0, 0, p.mColor.value));
          bUpdateStats = true;
        }
        break;
        
      case 'R':  // replace master hue or color from mc1 to mc2.
      case 'r':  // or refresh in case of viewTexture
        if (what == areaViewColors && mc1 != null && mc2 != null) {
          for (ColorPatch p : patches) {
            if (mc1.isEqual(p.mColor)) {
              p.setColor(mc2);
              bUpdateStats = true;
            }
          }
        }
        if (what == areaViewMHue && mc1 != null && mc2 != null) {
          for (ColorPatch p : patches) {
            if (mc1.isGray() && p.masterHue < 0 ||
                !mc1.isGray() && p.masterHue >= 0 &&
                mc1.hueDegree == p.masterHue &&
                mc1.chroma == p.masterChroma)
            {
              p.masterHue = mc2.isGray() ? -1 : mc2.hueDegree;
              p.masterChroma = mc2.isGray() ? -1 : mc2.chroma;
            }
          }
        }
        if (what == areaViewMGray && mc1 != null && mc2 != null) {
          for (ColorPatch p : patches) {
            if (p.masterGray == 0) continue;
            if (p.masterGray == mc1.value)
              p.masterGray = mc2.value;
          }
        }
        if (what == areaViewTexture) {
          for (ColorPatch p : patches) {
            p.texture = null;  // release the current texture so it refreshes.
          }
        }
        break;
        
      case 'S':
      case 's':  // simplify the number of colors used by 10% or -1
        if (what == areaViewColors) {
          simplifyColors();
          bUpdateStats = true;
        }
        break;
        
      case 'H':
      case 'h':  // increase hue by hueDegreePerSector.
                 // Note that it may lose high chroma as hue changes
        if (what == areaViewMHue) {
          for (ColorPatch p : patches) {
            if (p.masterChroma <= 0) continue;
            p.masterHue = (p.masterHue + hueDegreePerSector) % 360;
            // cap the chroma within max chroma of the new hue
            p.masterChroma = max(2, min(colorTable.getMaxChroma(p.masterHue), p.masterChroma));
          }
        }
        if (what == areaViewColors) {
          for (ColorPatch p : patches) {
            if (p.mColor.isGray()) continue;
            float r = radians((p.mColor.hueDegree + hueDegreePerSector) % 360);
            MunsellColor mc = new MunsellColor(p.mColor.chroma * cos(r), p.mColor.chroma * sin(r), p.mColor.value);
            // cap the chroma within max chroma of the new hue
            mc.chroma = max(2, min(colorTable.getMaxChroma(mc.hueDegree, mc.value), mc.chroma));
            p.setColor(mc);
          }
          bUpdateStats = true;
        }
        break;
        
      case 'M':
      case 'm':  // merge patches with the selected color into one
        if (what == areaViewColors) {
          MunsellColor mc = colorTable.rgbToMunsell(colorSelected);
          ArrayList<ColorPatch> cleanup = new ArrayList<ColorPatch>();
          ColorPatch merged = null;
          for (ColorPatch p : patches) {
            if (mc.isEqual(p.mColor)) {
              // merge it
              if (merged == null)
                merged = p;
              else {
                merged.add(p);
                cleanup.add(p);
              }
            }
          }
          // cleanup
          for (ColorPatch p : cleanup)
            patches.remove(p);
          currPatchIdx = -1;  // invalidate the global reference to patches by index
          
          bUpdateStats = true;
        }
        break;

      case 'B':
      case 'b':  // Break patches with the selected color into separate solids
        if (what == areaViewColors) {
          ArrayList<ColorPatch> orgs = new ArrayList<ColorPatch>();
          int idMax = -1;
          for (ColorPatch p : patches) {
            if (p.id > idMax)
              idMax = p.id;
            if (p.rgbColor == colorSelected)
              orgs.add(p);
          }         
          // Prepare an image with these patches
          PImage imgTemp = createImage(imgWidth, imgHeight, RGB);  // black by default
          for (ColorPatch o : orgs) {
            for (PVector pv : o.points) {
                  imgTemp.set((int)pv.x, (int)pv.y, colorSelected);
            }
          }          
          // Build a painting from the image
          Painting paintingTemp = buildPatchesByBoundary(imgTemp, color(0), imgTemp);
          // Delete originals and add the new patches
          for (ColorPatch o : orgs)
            patches.remove(o);
          for (ColorPatch p : paintingTemp.patches) {
            p.id = ++idMax;  // make sure ID's are uniquely generated
            patches.add(p);
          }
          currPatchIdx = -1;  // invalidate the global reference to patches by index
          
          bUpdateStats = true;
        }
        break;

      default:
        break;
    }

    if (bUpdateStats)
      updateStatistics();  // Re-calculate stats
  }

  // Replace masterTransition of the painting in batch
  public void replaceMasterTransition(String strOld, String strNew)
  {
    strOld = trim(String.valueOf(strOld)).toUpperCase();
    for (ColorPatch p : patches) {
      if (p.masterTransition.equals(strOld))
        p.setMasterTransition(strNew);
    }
  }

  // Create string for the painting statistics
  public String getStatString()
  {
    return "# of Patches: " + patches.size() + //<>//
           "\nPaint Coverage: " + String.format("%.1f%%", coverage * 100) +
           "\nCentroid: " + centroid.getString() +
           "\nTension: " + String.format("%.1f", tension) +
           " (C: " + String.format("%.1f", tensionComplexity) + ")" +
           "\nComplexity: " + String.format("%.1f", complexity);
  }

  // Draw all color patches to the image.
  public void draw(PImage img, int kind)
  {
    // Clear the area if necessary
    if (bClearNeeded) {
      for (int x = 0; x < img.width; x++)
        for (int y = 0; y < img.height; y++)
          img.set(x, y, colorBG);
      bClearNeeded = false;
    }
        
    if (kind == areaViewMTransition) {
      
      // visualize the transition as an illustration
      Painting trans = new Painting(this);
      trans.illustrateMTransition();
      trans.draw(img, areaViewColors);

      if (bShowReferenceLine) {  // show reference lines between patches
        // draw reference lines between patches
        for (ColorPatch p : trans.patches) {
          if (p.transRefIdx >= 0) {
            float x1 = (p.xMin + p.xMax) / 2;
            float y1 = (p.yMin + p.yMax) / 2;
            ColorPatch pRef = trans.patches.get(p.transRefIdx);
            float x2 = (pRef.xMin + pRef.xMax) / 2;
            float y2 = (pRef.yMin + pRef.yMax) / 2;
            drawLine(img, x1, y1, x2, y2);
          }
        }
        bClearNeeded = true;
      }
    }
    else {
      for (ColorPatch p : patches) {
        p.draw(img, kind, this);
      }
    }
  }

  // Find the patch index that contains the given pixel
  public int findPatchIdx(int x, int y)
  {
    for (int i = 0; i < patches.size(); i++) {
      if (patches.get(i).contains(x, y))
        return i;
    }
    return -1;
  }
  
  // Find the patch index by id
  public int findPatchIdx(int id)
  {
    for (int i = 0; i < patches.size(); i++) {
      if (patches.get(i).id == id)
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
  
  // Select a random color that meets master color specification from given colors.
  // If nothing is specified in the master spec, any color is picked.
  // A pure gray will be excluded for selection.
  //
  // Note that transition spec must have been parsed into parameters before this call.
  // It returns null if no color matches. A gray color if its reference patch is
  // not painted yet.
  MunsellColor selectColor(ColorPatch mp, ArrayList<MunsellColor> colors, MunsellColor centroid, float hueVariance)
  {
    // Select color with less tension gap as possible
    MunsellColor nmc = null;
    for (float tensionGap = 2.0; tensionGap <= similarTensionGap; tensionGap += 2.0) {
      nmc = selectColorInternal(mp, colors, centroid, hueVariance, tensionGap);
      if (nmc != null)
        break;
    }
    return nmc;
  }
  
  MunsellColor selectColorInternal(ColorPatch mp, ArrayList<MunsellColor> colors, MunsellColor centroid, float hueVariance, float tensionGap)
  {
    MunsellColor nmc = null;
    int s = (int)random(colors.size());  // random position to start searching
    for (int i = 0; i < colors.size() && nmc == null; i++) {
      MunsellColor c = new MunsellColor(colors.get((s + i) % colors.size()));
      if (c.isGray())
        continue;  // a pure gray is excluded from selection
      if (mp.masterGray > 0 && abs(c.value - mp.masterGray) > similarValueGap) {  
        // master gray level is specified, but it is not similar
        continue;
      }
      if (mp.masterHue >= 0) {  
        // master hue/chroma is specified; match if it is within the hue range
        if (degreeDistance(c.hueDegree, mp.masterHue) > hueVariance ||
            abs(c.chroma - mp.masterChroma) > similarChromaGap)
          continue;  // too far from the master hue/chroma
      }
      if (mp.masterTension > 0) {
        // master tension is specified; match if it is within the gap
        if (abs(mp.masterTension - centroid.getGap(c)) > tensionGap)
        continue;
      }
      if (mp.transRefIdx >= 0 && mp.transRefIdx < patches.size() && mp.transRefIdx != mp.id) {
        // master transition is specified; match if it complies with the transition
        
        MunsellColor mcRef = patches.get(mp.transRefIdx).mColor;
        if (mcRef.isGray()) {
          nmc = munsellBlack;
          continue;  // pick gray to wait until reference patch has been painted
        }
        
        // Apply the transition rule to the reference
        float gap = similarColorGap;
        float hueDegree = mcRef.hueDegree;
        float chroma = mcRef.chroma;
        float value = mcRef.value;
        for (int[] r : mp.transRules) {
          switch (r[0]) {
            case 'O':  hueDegree += 20 * hueDegreePerSector; break;
            case 'H':  hueDegree += r[1] * hueDegreePerSector; break;
            case 'C':  chroma += r[1]; break;
            case 'V':  value += r[1]; break;
            case 'A':  gap = r[1]; break;
            default:   break;
          }
          // Move it inside the sphere: first value, then chroma
          hueDegree = (int)hueDegree % 360;
          if (hueDegree < 0) hueDegree += 360;
          value = max(2, min(18, value));
          chroma = max(2, min(colorTable.getMaxChroma(hueDegree, value), chroma));
        }
        
        float r = radians(hueDegree);
        MunsellColor mc = new MunsellColor(chroma * cos(r), chroma * sin(r), value);
      
        if (c.getGap(mc) > gap)
          continue;  // does not match the transition rule
      }
      
      // It's a match (or no master restriction)
      nmc = c;
    }
  
    return nmc;
  }
  
  // Illustrate all the patches according to the transition specification.
  // See comments of ColorPatch::parseTransParams() for transition spec.
  // An illustrative color for a transition rule is calculated as follows:
  //  (1) If there is no reference, use black (unspecified).
  //  (2) If it references to itself, use 0R0-0 (black) as reference.
  //      Self-reference is only for illustration purpose.
  //      This patch is used as starting point of a reference chain.
  //      Actual painting for this patch will treat it as the same as unspecified.
  //  (3) If the rule is 'A', use the same color as ref.
  //  (4) Otherwise, use the color by interpreting the rule. In order to
  //      make sure the illustrative color is a valid one, it caps the value
  //      range within [2, 18], and then, it tries to pick the nearest chroma
  //      that matches the spec within Munsell shpere.
  void illustrateMTransition()
  {
    // Populate transition parameters from the spec
    for (ColorPatch p : patches)
      p.parseTransParams();

    // First pass: initialize all patches as black (unspecified).
    for (ColorPatch p : patches) {
      p.setColor(munsellBlack);
    }

    // Second pass: illustrate the patches with references.
    // This may require multiple passes as a patch depends on
    // its reference patch to be illustrated first.
    boolean bDone = false;
    while (!bDone) {
      bDone = true;
      for (ColorPatch p : patches) {
        if (p.transRefIdx < 0 || !p.mColor.isGray())
          continue;  // done - either no reference or colored already
          
        if (p.transRefIdx >= patches.size())
          continue;  // an invalid reference patch
          
        MunsellColor mcRef = patches.get(p.transRefIdx).mColor;
        if (p.transRefIdx != p.id && mcRef.isGray())
          continue;  // wait until reference patch has been illustrated

        // Now, interpret the transition rule with the reference
        float hueDegree = mcRef.hueDegree;
        float chroma = mcRef.chroma;
        float value = mcRef.value;
        for (int[] r : p.transRules) {
          switch (r[0]) {
            case 'O':  hueDegree += 20 * hueDegreePerSector; break;
            case 'H':  hueDegree += r[1] * hueDegreePerSector; break;
            case 'C':  chroma += r[1]; break;
            case 'V':  value += r[1]; break;
            case 'A':  break;
            default:   break;
          }
          // Move it inside the sphere: first value, then chroma
          hueDegree %= 360;
          if (hueDegree < 0) hueDegree += 360;
          value = max(2, min(18, value));
          int cMax = colorTable.getMaxChroma(hueDegree, value);
          if (cMax == 0)  // adjust value to have a non-gray color
            value += (value < 10) ? 2 : -2;
          chroma = max(2, min(cMax, chroma));
        }
        
        float r = radians(hueDegree);
        p.setColor(new MunsellColor(chroma * cos(r), chroma * sin(r), value));

        bDone = false;  // a new illustrated patch triggers another loop
      }
    }
  }

  // Paint all the patches with the colors according to the master color specification.
  // The centroid, hueVariance, tension scale will affect whether a color matches the master spec.
  // Any patch that cannot find a color meeting the master specification will
  // be painted as pure black.
  void paint(ArrayList<MunsellColor> colors, MunsellColor centroid, float hueVariance, float tensionScale)
  {
    // Reset every patch to black to indicate unpainted.
    for (ColorPatch p : patches)
      p.setColor(munsellBlack);
      
    if (colors == null || colors.size() < 1)
      return;
  
    // Populate transition parameters from the spec
    for (ColorPatch p : patches)
      p.parseTransParams();

    // Scale master tension by the scale factor
    for (ColorPatch p : patches) {
      if (p.masterTension > 0)
        p.masterTension *= tensionScale;
    }

    // Paint the patches.
    // This may require multiple passes if there is transition spec
    // with reference patch, which must be painted first before referenced.
    boolean bDone = false;
    while (!bDone) {
      bDone = true;      
      for (ColorPatch p : patches) {
        if (!p.mColor.isGray())
          continue;  // done this patch
        MunsellColor mc = selectColor(p, colors, centroid, hueVariance);
        if (mc == null || mc.isGray()) {
          // no color found or the referenced patch is not painted yet
          continue;
        }
        else {
          p.setColor(mc);
          bDone = false;  // a new painted patch triggers another loop
        }
      }
    }
    
    // Reset the scale of master tension
    for (ColorPatch p : patches) {
      if (p.masterTension > 0)
        p.masterTension /= tensionScale;
    }
  }

  // Replace colors to toward complexity direction: negative for reduce,
  // positive for increase.
  public void optimizeForComplexity(int dir, ArrayList<MunsellColor> colors, MunsellColor centroid, float hueVariance, float tensionScale)
  {
    float rate = 0.5;
    
    // Populate transition parameters from the spec
    for (ColorPatch p : patches)
      p.parseTransParams();

    // Scale master tension by the scale factor
    for (ColorPatch p : patches) {
      if (p.masterTension > 0)
        p.masterTension *= tensionScale;
    }

    // First pass: optimize patches that have no reference

    // Build an array of the existing colors.
    ArrayList<MunsellColor> colorsExisting = new ArrayList<MunsellColor>();
    for (ColorPatch p : patches) {
      if (p.transRefIdx < 0)
        colorsExisting.add(p.mColor);
      else
        colorsExisting.add(munsellBlack);
    }

    for (int i = 0; i < patches.size(); i++) {
      ColorPatch p = patches.get(i);
      if (p.transRefIdx >= 0)
        continue;  // won't optimize a patch whose color is derived from its reference
        
      if (random(1) > rate)
        continue;
        
      // skip if unpainted as it won't find any other color that matches the spec
      if (p.mColor.isGray())
        continue;

      if (dir < 0) {  
        // need to reduce complexity; replace with another existing color
        colorsExisting.set(i, munsellBlack);  // take it out
        MunsellColor mc = selectColor(p, colorsExisting, centroid, hueVariance);
        if (mc != null)
          p.setColor(mc);
        colorsExisting.set(i, p.mColor);  // put the new one back
      }
      if (dir > 0) {  
        // need to increase complexity; try a new color up to 5 times.
        for (int j = 0; j < 5; j++) {
          MunsellColor mc = selectColor(p, colors, centroid, hueVariance);
          if (mc != null && mc.getGap(p.mColor) > similarColorGap) {
            p.setColor(mc);
            break;
          }
        }
      }
    }
    
    // Second pass: re-calculate patch colors based on their references that
    // might have been changed in the previous step.
    
    for (ColorPatch p : patches) {  // reset
      if (p.transRefIdx >= 0)
        p.setColor(munsellBlack);
    }
    
    boolean bDone = false;
    while (!bDone) {
      bDone = true;      
      for (ColorPatch p : patches) {
        if (p.transRefIdx < 0)
          continue;  // done in the first pass
        if (!p.mColor.isGray())
          continue;  // done this patch
        MunsellColor mc = selectColor(p, colors, centroid, hueVariance);
        if (mc == null || mc.isGray()) {
          // no color found or the referenced patch is not painted yet
          continue;
        }
        else {
          p.setColor(mc);
          bDone = false;  // a new painted patch triggers another loop
        }
      }
    }
    
    // Reset the scale of master tension
    for (ColorPatch p : patches) {
      if (p.masterTension > 0)
        p.masterTension /= tensionScale;
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

    // Save it to the file up to maxColors
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
    for (int i = 0; i < maxColors && i < list.size(); i++) {
      MunsellColor mc = list.get(i).getKey();
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
  
  // Simplify colors by reducing the number of colors used by 10% or 1.
  // Reducing colors are done by replacing the color that uses less area by
  // the nearest color that uses more area.
  void simplifyColors()
  {
    float gap = 0.1;
    
    // Obtain a histogram of all distinct colors
    HashMap<MunsellColor, Float> histogram = buildHistogram(gap);
    
    // Sort them by area
    List<Map.Entry<MunsellColor, Float> > list = new LinkedList<Map.Entry<MunsellColor, Float> >(histogram.entrySet());
    Collections.sort(list, Comparator.comparing((Map.Entry<MunsellColor, Float> e) -> -e.getValue()));

    // Calculate the new max # of colors
    int maxColors = max(1, list.size() - max(round(list.size() * 0.1), 1));
    
    // Simplify colors so they are limited to maxColors
    for (ColorPatch p : patches) {
      boolean bFound = false;
      for (int i = 0; i < maxColors && i < list.size(); i++) {
        if (p.mColor.getGap(list.get(i).getKey()) <= gap) {
          bFound = true;  // not a victim - no need to replace
          break;
        }
      }
      if (!bFound) {  // replace with the nearest color
        float minGap = 100.0;
        int m = -1;
        for (int j = 0; j < maxColors && j < list.size(); j++) {
          float g = p.mColor.getGap(list.get(j).getKey());
          if (g < minGap) {
            m = j;
            minGap = g;
          }
        }
        if (m >= 0)
          p.setColor(list.get(m).getKey());
      }
    }
  }  
}

// Build a set of color patches from the image by boundary.
// Each continuous solid constitutes a patch if it is
// bounded by either cContour (Contour-based) or 
// a different color (Solid-based)
// Patches are first built from imgSrc and then
// all coordinates are scaled to imgScaleTo
Painting buildPatchesByBoundary(PImage imgSrc, color cContour, PImage imgScaleTo) 
{
  color cVisited = color(128);  // use gray to mark visited while traversal
  color cDone = color(255);  // use white to mark done after a patch is done
  ArrayList<ColorPatch> patches = new ArrayList<ColorPatch>();
  PImage imgMark = createImage(imgSrc.width, imgSrc.height, RGB);  // to mark done or visited
  
  for (int i = 0; i < imgSrc.width; i++) {
    for (int j = 0; j < imgSrc.height; j++) {
      color m = imgMark.get(i, j);
      if (m == cDone)
        continue;  // done in previous patch

      color s = imgSrc.get(i, j);
      if (cContour != colorNone && rgbDistance(s, cContour) < contourColorThreshold)
        continue;  // it's the contour
        
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
        m = imgMark.get(px, py);
        if (m == cVisited)
          continue;  // Already visited this pixel.
          
        // Has reached a new pixel; store and mark it visited
        points.add(pv);
        imgMark.set(px, py, cVisited); 
        
        // Try neighbors. Also add it to contour if a neighbor is another patch
        boolean bContour = false;
        PVector[] arrNPV = new PVector[4];
        arrNPV[0] = new PVector(px, py - 1);
        arrNPV[1] = new PVector(px + 1, py);
        arrNPV[2] = new PVector(px, py + 1);
        arrNPV[3] = new PVector(px - 1, py);
        for (PVector npv : arrNPV) {
          // Boundary criteria are different between contour-based and solid-based;
          // Contour-based: a similar color to contour is considered as boundary;
          // Solid-based: any color that is different to the current one is boundary.
          color n = imgSrc.get((int)npv.x, (int)npv.y);
          if (npv.x < 0 || npv.x >= imgSrc.width || 
              npv.y < 0 || npv.y >= imgSrc.height ||
              cContour != colorNone && rgbDistance(n, cContour) < contourColorThreshold ||
              cContour == colorNone && s != n)
          { // this neighbor is boundary
            bContour = true;
          }
          else {  // continue to explore the neighbor
            ps.push(npv);
          }
        }
        if (bContour)
          contourPoints.add(pv);
      }
      // Mart points of patch as done (from visisted)      
      for (PVector pv : points)
        imgMark.set((int)pv.x, (int)pv.y, cDone);
      
      ColorPatch p = new ColorPatch(patches.size(), imgSrc, points, contourPoints);
      patches.add(p);
    }
  }

  if (patches.size() < 1)  // no valid patches are found
    return null;
    
  if (imgScaleTo != null) {
    float xScale = (float)imgScaleTo.width / imgSrc.width;
    float yScale = (float)imgScaleTo.height / imgSrc.height;
    
    for (ColorPatch p : patches) {
      p.scale(xScale, yScale);
    }
  }
  else
    imgScaleTo = imgSrc;
  
  return new Painting(imgScaleTo.width, imgScaleTo.height, patches);
}

// Build a set of color patches from the image by colors.
// Each color creates a separate patch.
// Patches are first built from imgSrc and then
// all coordinates are scaled to imgScaleTo
Painting buildPatchesByColor(PImage imgSrc, PImage imgScaleTo) 
{
  ArrayList<ColorPatch> patches = new ArrayList<ColorPatch>();
  HashMap<MunsellColor, ArrayList<PVector> > mapPoints = new HashMap<MunsellColor, ArrayList<PVector> >();
  HashMap<MunsellColor, ArrayList<PVector> > mapContourPoints = new HashMap<MunsellColor, ArrayList<PVector> >();

  for (int i = 0; i < imgSrc.width; i++) {
    for (int j = 0; j < imgSrc.height; j++) {
      Integer c = imgSrc.get(i, j);
        
      // See if the color is already in the map
      MunsellColor m = colorTable.rgbToMunsell(c);
      ArrayList<PVector> points = mapPoints.get(m);
      ArrayList<PVector> contourPoints = mapContourPoints.get(m);
      if (points == null) {
        // a new color: create a new points vector and put it to the map
        points = new ArrayList<PVector>();
        mapPoints.put(m, points);
        contourPoints = new ArrayList<PVector>();
        mapContourPoints.put(m, contourPoints);
      }
      assert contourPoints != null : "points and contourPoints are not in sync";

      PVector pv = new PVector(i, j);
      points.add(pv);

      // Add it to contour if its neighbor is a boundary but not the edge of image
      if (i <= 0 || i >= imgSrc.width - 1 || j <= 0 || j >= imgSrc.height - 1 ||
          c != imgSrc.get(i - 1, j) || c != imgSrc.get(i + 1, j) ||
          c != imgSrc.get(i, j - 1) || c != imgSrc.get(i, j + 1))
      {
        contourPoints.add(pv);
      }      
    }
  }
    
  // Create all patches from the map
  for (Map.Entry<MunsellColor, ArrayList<PVector> > m : mapPoints.entrySet()) {
    ArrayList<PVector> points = m.getValue();
    ArrayList<PVector> contourPoints = mapContourPoints.get(m.getKey());
    ColorPatch p = new ColorPatch(patches.size(), imgSrc, points, contourPoints);
    patches.add(p);
  }
  
  if (patches.size() < 1)  // no valid patches are found
    return null;

  if (imgScaleTo != null) {
    float xScale = (float)imgScaleTo.width / imgSrc.width;
    float yScale = (float)imgScaleTo.height / imgSrc.height;
    
    for (ColorPatch p : patches) {
      p.scale(xScale, yScale);
    }
  }
  else
    imgScaleTo = imgSrc;
  
  return new Painting(imgScaleTo.width, imgScaleTo.height, patches);
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

// Draw a transition reference line to image
void drawLine(PImage img, float x1, float y1, float x2, float y2)
{ 
  // Calculate steps to take to plot
  float dx = x2 - x1;
  float dy = y2 - y1;
  float m = max(abs(dx), abs(dy));
  float x = x1, y = y1;
  for (int i = 0; i < m; i++) {
    color c = color(255 * i / m, 255, 0);
    img.set(round(x), round(y), c); 
    img.set(round(x+1), round(y), c); 
    img.set(round(x), round(y+1), c); 
    x += dx / m; 
    y += dy / m; 
  } 
}
