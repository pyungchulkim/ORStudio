// Constants - some are fuzzy, picked based upon by my experimentation
final int contourColorThreshold = 60;  // RGB diff to identify contour line

// flag to show contour lines
boolean bShowContour = true;

// Class for an individual Color Patch
class ColorPatch
{
  public int id;  // ID of the patch: serial number starting from 0
  public ArrayList<PVector> points; // coordinates of all the points
  public ArrayList<PVector> contourPoints;  // coordinates of contour
  public float xMin, xMax, yMin, yMax;  // dimension of the contour in rectangle
  public float masterGray;  // master gray level. 0 if not specified
  public float masterHue;  // master hue degree. negative if not specified
  public float masterChroma;  // master chroma - always used together with masterHue
  public float masterTension;  // master tension. 0 if not specified
  public String masterTransition;  // master transition spec
  public MunsellColor mColor; // painted Munsell color of the patch - always one from the quantized map (mToRGB)
  public color rgbColor; // RGB color of mColor for display
  public float gGap;  // Color Gap in terms of gray level against the centroid
  public float cGap;  // Color Gap in terms of color against the centroid

  // transient - populated on-demand for performance. no need to serialize
  public PVector coord;  // Color Coordinate
  public boolean transParsed;  // flag if transition parameters have been parsed.
  public int transRefIdx;  // transition reference patch index
  public ArrayList<int[]> transRules;  // transition rules. [0]: type, [1]: delta
  public int textureType; // texture info used in the cache
  public int textureAxis;
  public int textureGap;
  public int textureBG;
  public color[] texture; // texture representation of the patch
  
  // default constructor
  public ColorPatch() {}
  
  // Constructor to build a patch from pixels
  public ColorPatch(int id, PImage img, ArrayList<PVector> pts, ArrayList<PVector> cpts)
  {
    this.id = id;
    points = pts;
    contourPoints = cpts;
    
    // Sort contour points in the order of proximity so it forms
    // continous lines as possible, although it may have
    // split or disjoint lines
    for (int i = 0; i < contourPoints.size(); i++) {
      PVector last = contourPoints.get(i);  // last sorted
      float minDist = Float.MAX_VALUE;
      int minIdx = -1;
      for (int j = i + 1; j < contourPoints.size(); j++) {
        PVector v = contourPoints.get(j);
        // optimization: stop search if this is already a neighbor
        if (abs(last.x - v.x) <= 1.0 && abs(last.y - v.y) <= 1.0) {
          minIdx = j;
          break;
        }
        float dist = last.dist(v);
        if (dist < minDist) {
          minIdx = j;
          minDist = dist;
        }
      }
      if (minIdx >= 0) {  // nearest to last is found; put it at last+1
        PVector t1 = contourPoints.get(i + 1);
        PVector t2 = contourPoints.get(minIdx);
        PVector tmp = new PVector(t1.x, t1.y);
        t1.x = t2.x; t1.y = t2.y;
        t2.x = tmp.x; t2.y = tmp.y;
      }
    }
    
    // Set the dimension
    xMin = Integer.MAX_VALUE;
    xMax = Integer.MIN_VALUE;
    yMin = Integer.MAX_VALUE;
    yMax = Integer.MIN_VALUE;
    for (PVector p : points) {
      xMin = min(xMin, p.x);
      xMax = max(xMax, p.x);
      yMin = min(yMin, p.y);
      yMax = max(yMax, p.y);
    }
    
    // Initialize master color/tension
    masterGray = 0;
    masterHue = -1;
    masterChroma = -1;
    masterTension = 0;
    masterTransition = "";

    // Calculate average color
    float rSum = 0;
    float gSum = 0;
    float bSum = 0;
    float incr = max(1, points.size() / 100);  // use only 100 points at max
    int np = 0;
    for (float i = 0; i < points.size(); i += incr) {
      PVector p = points.get((int)i);
      color c = img.get((int)p.x, (int)p.y);
      rSum += red(c);
      gSum += green(c);
      bSum += blue(c);
      np++;
    }
    setColor(colorTable.rgbToMunsell(color(rSum / np, gSum / np, bSum / np)));
    
    // Make sure the value of the color is within [2, 18] for painting purpose.
    // Value outside this range won't be honored when selecting a color in painting.
    if (mColor.value < 2 || mColor.value > 18) {
      mColor.value = min(18, mColor.value);
      mColor.value = max(2, mColor.value);
      setColor(mColor);
    }

    gGap = cGap = 0; // set by updateGap() later
    transParsed = false;
  }
  
  // Copy constructor for a shallow copy to experiment all while keeping the shape and location
  public ColorPatch(ColorPatch p)
  {
    id = p.id;
    points = p.points;  // shallow copy
    contourPoints = p.contourPoints;
    xMin = p.xMin; xMax = p.xMax; yMin = p.yMin; yMax = p.yMax;
    masterGray = p.masterGray;
    masterHue = p.masterHue;
    masterChroma = p.masterChroma;
    masterTension = p.masterTension;
    masterTransition = String.valueOf(p.masterTransition);
    mColor = new MunsellColor(p.mColor);
    rgbColor = p.rgbColor;
    gGap = p.gGap; 
    cGap = p.cGap;
    transParsed = false;
    textureType = p.textureType;
    textureAxis = p.textureAxis;
    textureGap = p.textureGap;
    textureBG = p.textureBG;
    texture = p.texture;
  }
  
  // Add another patch into this one.
  // Keep all the color and master info unchanged, but
  // just to add the area of another patch.
  // NOTE: the contourPoints will be simply added even if
  // added contour lines may be no longer contour after added.
  public void add(ColorPatch p)
  {
    assert mColor.isEqual(p.mColor) : "Cannot add a patch of different color into another.";

    points.addAll(p.points);
    contourPoints.addAll(p.contourPoints);

    // Adjust the dimension
    xMin = min(xMin, p.xMin);
    xMax = max(xMax, p.xMax);
    yMin = min(yMin, p.yMin);
    yMax = max(yMax, p.yMax);   
  }
  
  // Serialize to save
  public void Serialize(ObjectOutputStream oos) throws IOException
  {
    oos.writeInt(id);
    oos.writeObject(points);
    oos.writeObject(contourPoints);
    oos.writeFloat(xMin); oos.writeFloat(xMax); oos.writeFloat(yMin); oos.writeFloat(yMax);
    oos.writeFloat(masterGray);
    oos.writeFloat(masterHue);
    oos.writeFloat(masterChroma);
    oos.writeFloat(masterTension);
    oos.writeObject(masterTransition);
    mColor.Serialize(oos);
    oos.writeInt(rgbColor);
    oos.writeFloat(gGap);
    oos.writeFloat(cGap);
  }
  
  // Deserialize to load
  public void Deserialize(ObjectInputStream ois) throws IOException, ClassNotFoundException
  {
    id = ois.readInt();
    points = (ArrayList<PVector>)ois.readObject();
    contourPoints = (ArrayList<PVector>)ois.readObject();
    xMin = ois.readFloat(); xMax = ois.readFloat(); yMin = ois.readFloat(); yMax = ois.readFloat();
    masterGray = ois.readFloat();
    masterHue = ois.readFloat();
    masterChroma = ois.readFloat();
    masterTension = ois.readFloat();
    masterTransition = (String)ois.readObject();
    mColor = new MunsellColor(); mColor.Deserialize(ois);
    rgbColor = ois.readInt();
    gGap = ois.readFloat();
    cGap = ois.readFloat();
    transParsed = false;
  }
  
  // Set the color from a Munsell color. Return if changed.
  public boolean setColor(MunsellColor mc)
  {
    // set RGB from the quantized mapping table to make sure 
    // the RGB is always the one driven from the mapping table.
    color rgbColorNew = colorTable.munsellToRGB(mc);
    // Now, we set quantized Munsell color for the RGB
    MunsellColor mColorNew = new MunsellColor(colorTable.rgbToMunsell(rgbColorNew));
    boolean bChanged = false;
    if (rgbColor != rgbColorNew || !mColor.isEqual(mColorNew)) {
      rgbColor = rgbColorNew;
      mColor = mColorNew;
      texture = null; // invalidate texture cache
      bChanged = true;
    }
    return bChanged;
  }
  
  // Set master gray from a Munsell color. Return true if changed
  public boolean setMasterGray(MunsellColor mc)
  {
    boolean bChanged = false;
    if (masterGray != mc.value) {
      masterGray = mc.value;
      bChanged = true;
    }
    return bChanged;
  }
  
  // Set master hue and chroma from a Munsell color. Return true if changed
  public boolean setMasterHue(MunsellColor mc)
  {
    float masterHueNew = mc.isGray() ? -1 : mc.hueDegree;
    float masterChromaNew = mc.isGray() ? -1 : mc.chroma;
    boolean bChanged = false;
    if (masterHue != masterHueNew || masterChroma != masterChromaNew) {
      masterHue = masterHueNew;
      masterChroma = masterChromaNew;
      bChanged = true;
    }
    return bChanged;
  }
  
  // Set master tension. Return true if changed
  public boolean setMasterTension(float t)
  {
    boolean bChanged = false;
    if (masterTension != t) {
      masterTension = t;
      bChanged = true;
    }
    return bChanged;
  }
  
  // Set master transition. Return true if changed
  public boolean setMasterTransition(String str)
  {
    String masterTransitionNew = trim(String.valueOf(str)).toUpperCase();
    boolean bChanged = false;
    if (!masterTransition.equals(masterTransitionNew)) {
      masterTransition = masterTransitionNew;
      bChanged = true;
    }
    return bChanged;
  }

  // Parse master transition string into rules.
  // A non-empty transition string has the following format:
  // "<ref>{/rule}", where 'ref' indicates referenced patch index, and
  // each rule 'rule', seperated by '/', indicates movement of hue/chroma
  // relative to the hue/chroma of reference, as follows:
  //  "H<delta>" - Move hue by delta. Delta is a directional unit of 40 hue sectors.
  //  "C<delta>" - Move chroma by delta.
  //  "V<delta>" - Move value by delta.
  //  "A<delta>" - Move by delta distance in any direction. This rule can appear
  //               at the end; no rule can be added after this.
  //  "O"        - Move to the opposite crossing the center of color sphere.
  public void parseTransParams()
  {
    if (transParsed)
      return;  // done already

    transRefIdx = -1;
    transRules = new ArrayList<int[]> ();
    if (masterTransition.isEmpty())
      return;
      
    String[] data = masterTransition.split("/");
    int i = 0;
    try {
      transRefIdx = Integer.parseInt(data[i++]);  // reference index
      while (i < data.length) {
        int[] r = new int[2];
        r[0] = data[i].charAt(0);
        if (r[0] != 'H' && r[0] != 'C' && r[0] != 'V' && r[0] != 'A' && r[0] != 'O')
          break; // invalid rule
        if (r[0] != 'O')
          r[1] = Integer.parseInt(data[i].substring(1));
        transRules.add(r);
        i++;
        if (r[0] == 'A')
          break;  // no rules can be added after 'A'
      }
    } catch (Exception e) { }
    
    if (i < data.length) {  // prematured break
      transRefIdx = -1;
      transRules = new ArrayList<int[]> ();
    }
    
    transParsed = true;
  }
  
  // Get the size of patch area
  public float getAreaSize()
  {
    return points.size();
  }
  
  // Scale all the pixel locations within the patch
  public void scale(float xScale, float yScale)
  {
    // Scale the points. This effectively scale contour as well
    // because contour points are just references to regular area points.
    for (PVector p : points) {
      p.x *= xScale;
      p.y *= yScale;
    }

    xMin *= xScale;
    xMax *= xScale;
    yMin *= xScale;
    yMax *= xScale;
  }
  
  // Create string for the patch statistics
  public String getStatString()
  {
    return  "Patch ID: " + id +
            "\nArea: " + String.format("%,d", (int)getAreaSize()) +
            "\nGray Gap: " + String.format("%.1f", gGap) +
            "\nColor Gap: " + String.format("%.1f", cGap);
  }

  // See if the patch contains the point
  boolean contains(int x, int y)
  {
    if (x < xMin || x > xMax || y < yMin || y > yMax)
      return false;
    for (PVector p : points) {
      if ((int)p.x == x && (int)p.y == y)
        return true;
    }
    return false;
  }
   
  // Draw the color patch to the image with local color
  public void draw(PImage img, int kind, Painting owner)
  {
    switch (kind) {
      case areaViewColors: // Draw local color of the patches
        drawPoints(img, rgbColor);
        break;
      case areaViewMGray: // Draw master gray-level of the patches
        drawPoints(img, colorTable.munsellToRGB(new MunsellColor(0, 0, masterGray)));
        break;
      case areaViewMHue: // Draw master hue & chroma of the patches
      {
        float ch = (masterHue < 0) ? 0 : masterChroma;
        float x = ch * cos(radians(masterHue));
        float y = ch * sin(radians(masterHue));
        int[] vd = {0, -2, +2, -4, +4, -6, +6};
        for (int i = 0; i < vd.length; i++) {  // pick a value near 12 for the hue/chroma
          MunsellColor mc = new MunsellColor(x, y, 12 + vd[i]);
          if (colorTable.isMunsellKeyInMap(mc)) {
            drawPoints(img, colorTable.munsellToRGB(mc));
            break;
          }
        }
        break;
      }
      case areaViewTension: // Draw tension of the local color
      case areaViewMTension: // Draw master tension
      {
        // Color tension value ranges from [0, 80] within Munsell sphere.
        // However, practically, most of tension values are within 40 (the radius).
        // I convert it to 180 degree ranges, then use r,g,b as if it is temperature,
        // red being highest tension, blue being lowest tension.
        float t = (kind == areaViewTension) ? cGap : masterTension;
        t = max(0, 180 * (1 - t / 40));
        float r = (t < 90) ? 255 * cos(radians(t)) : 0;
        float g = 255 * sin(radians(t));
        float b = (t >= 90) ? 255 * -cos(radians(t)) : 0;
        drawPoints(img, color(r, g, b));
        break;
      }
      case areaViewTexture: // Draw the color of the patches in texture drawing
      {
        if (texture == null ||
            textureType != ctrlTextureType || textureAxis != ctrlTextureAxis ||
            textureGap != ctrlTextureGap || textureBG != ctrlTextureBG) 
        {  // the cache doesn't exist or is no longer valid; re-create the texture
        
          // Identify background, foreground color and the density to make mColor
          MunsellColor mcBackground = null;
          MunsellColor mcForeground = null;
          float  density = 0;
          
          switch (ctrlTextureAxis) {
            case txtAxisHue:  // hue
            {
              // Find the unit vector that is perpendicular to the current color (mColor)
              float ux = cos(radians(mColor.hueDegree)), uy = sin(radians(mColor.hueDegree));
              PVector left = new PVector(-uy, ux);
              PVector right = new PVector(uy, -ux);
              // Generate ordered pair of left/right gap so that
              // max gap is preferred and the mid-point is preferred within the same gap
              ArrayList<PVector> tries = new ArrayList<PVector>();
              for (int g = ctrlTextureGap; g > 0; g--) {
                for (int h = g / 2; h >= 0; h--) {
                  tries.add(new PVector(h, g - h));
                  tries.add(new PVector(g - h, h));
                }
              }
              // Find a valid pair in the Munsell sphere.
              int bg = 0, fg = 0;
              PVector cp = mColor.getCoordinate();
              for (PVector t : tries) {
                PVector lp = PVector.mult(left, t.x).add(cp);
                PVector rp = PVector.mult(right, t.y).add(cp);                
                if (colorTable.isMunsellKeyInMap(new MunsellColor(lp)) &&
                    colorTable.isMunsellKeyInMap(new MunsellColor(rp))) 
                {
                  bg = (int)t.x;
                  fg = (int)t.y;
                  break;
                }
              }
              if (bg + fg > 0)
                density = (float)bg / (bg + fg);
              if (ctrlTextureBG == txtBGHigh) {
                mcBackground = new MunsellColor(PVector.mult(left, bg).add(cp));
                mcForeground = new MunsellColor(PVector.mult(right, fg).add(cp));
              }
              else {
                mcBackground = new MunsellColor(PVector.mult(right, fg).add(cp));
                mcForeground = new MunsellColor(PVector.mult(left, bg).add(cp));
                density = 1.0 - density;
              }
              break;
            }
            case txtAxisValue: // value
            case txtAxisChroma: // chroma
            default:
            {
              int lb, ub;  // lower/upper bound of the range of H/V/C being considered
              int bg, fg;  // foreground/background of the range of H/V/C being considered
              int ctr;
              int gap = 0;
              if (ctrlTextureAxis == txtAxisChroma) {
                ub = colorTable.getMaxChroma(mColor.hueDegree, mColor.value);
                lb = 0;
                ctr = round(mColor.chroma);
              }
              else {
                ub = colorTable.getMaxValue(mColor.hueDegree, mColor.chroma);
                lb = colorTable.getMinValue(mColor.hueDegree, mColor.chroma);
                ctr = round(mColor.value);
              }
              bg = fg = ctr;
              gap = 0;
              while (gap < ctrlTextureGap && (bg < ub || fg > lb) ) {  // adjust bg/fg by the gap amount
                if (bg < ub) { bg++; gap++; }
                if (fg > lb && gap < ctrlTextureGap) { fg--; gap++; }
              }
              if (bg > fg)
                density = (float)(bg - ctr) / (bg - fg);
              if (ctrlTextureBG == txtBGLow) { // flip bg/fg and density so it uses the lower H/V/C as background
                int t = bg; bg = fg; fg = t;
                density = 1.0 - density;
              }
              mcBackground = new MunsellColor(mColor);
              mcForeground = new MunsellColor(mColor);
              if (ctrlTextureAxis == txtAxisChroma) {
                mcBackground.chroma = bg;
                mcForeground.chroma = fg;
              }
              else {
                mcBackground.value = bg;
                mcForeground.value = fg;
              }
              break;
            }
          }
          PGraphics buffer = drawTexture(owner, id, mcBackground, mcForeground, density);
          texture = new color[points.size()];
          for (int i = 0; i < points.size(); i++) {
            PVector p = points.get(i);
            texture[i] = buffer.get((int)(p.x - xMin), (int)(p.y - yMin));
          }
          textureType = ctrlTextureType;
          textureAxis = ctrlTextureAxis;
          textureGap = ctrlTextureGap;
          textureBG = ctrlTextureBG;
        }
        drawPoints(img, colorNone);
        break;
      }
      case areaViewMTransition: // Draw master transition - handled at painting level
      default:
        break;
    }
  }
  
  // Draw the color patch to the image with given color
  public void drawPoints(PImage img, color c)
  {
    boolean bTexture = (c == colorNone);
    // Draw area inside
    if (bTexture && texture != null) {  // use texture
      for (int i = 0; i < points.size(); i++) {
        PVector p = points.get(i);
        img.set((int)p.x, (int)p.y, texture[i]);
      }
    }
    else {
      for (PVector p : points) {
        img.set((int)p.x, (int)p.y, c);
      }
    }
    // Draw contour
    if (bShowContour) {
      for (PVector p : contourPoints) {
            img.set((int)p.x, (int)p.y, (bTexture) ? colorBG : colorEdge);
      }
    }
  }
}
