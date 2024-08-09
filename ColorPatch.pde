// Constants - some are fuzzy, picked based upon by my experimentation
final int minPatchSize = 10;  // min # of pixels excluding contour to form a patch
final int contourColorThreshold = 60;  // RGB diff to identify contour line

// Constants for color transition types
final int transDefault = 0;
final int transFixed = 1;
final int transComplementary = 2;
final int transHueVariant = 3;
final int transChromaVariant = 4;
final int transValueVariant = 5;
final int transAnalogous = 6;

// flag to show contour lines
boolean bShowContour = false;

// Class for an individual Color Patch
class ColorPatch
{
  public int id;  // ID of the patch: serial number starting from 0
  public ArrayList<PVector> points; // coordinates of all the points
  public ArrayList<PVector> contourPoints;  // coordinates of contour
  public float xMin, xMax, yMin, yMax;  // dimension of the contour in rectangle
  public float masterGray;  // master gray level. 0 if not specified
  public float masterHue;  // master hue degree. negative if not specified
  public float masterTension;  // master tension. 0 if not specified
  public String masterTransition;  // master transition spec
  public MunsellColor mColor; // painted Munsell color of the patch - always one from the quantized map (mToRGB)
  public color rgbColor; // RGB color of mColor for display
  public float gGap;  // Color Gap in terms of gray level against the centroid
  public float cGap;  // Color Gap in terms of color against the centroid

  // transient - populated on-demand for performance. no need to serialize
  public PVector coord;  // Color Coordinate
  public boolean transParsed;  // flag if transition parameters have been parsed.
  public int transParam1;  // 1st transition parameter
  public int transParam2;  // 2nd transition parameter
  public int transParam3;  // 3rd transition parameter
  
  // default constructor
  public ColorPatch() {}
  
  // Constructor to build a patch from pixels
  public ColorPatch(int id, PImage img, ArrayList<PVector> pts, ArrayList<PVector> cpts)
  {
    this.id = id;
    points = pts;
    contourPoints = cpts;

    // Set the dimension
    xMin = Integer.MAX_VALUE;
    xMax = Integer.MIN_VALUE;
    yMin = Integer.MAX_VALUE;
    yMax = Integer.MIN_VALUE;
    for (PVector p : cpts) {
      xMin = min(xMin, p.x);
      xMax = max(xMax, p.x);
      yMin = min(yMin, p.y);
      yMax = max(yMax, p.y);
    }
    
    // Initialize master color/tension
    masterGray = 0;
    masterHue = -1;
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
    masterTension = p.masterTension;
    masterTransition = String.valueOf(p.masterTransition);
    mColor = new MunsellColor(p.mColor);
    rgbColor = p.rgbColor;
    gGap = p.gGap; 
    cGap = p.cGap;
    transParsed = false;
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
  
  // Set master hue from a Munsell color. Return true if changed
  public boolean setMasterHue(MunsellColor mc)
  {
    float masterHueNew = mc.isGray() ? -1 : mc.hueDegree;
    boolean bChanged = false;
    if (masterHue != masterHueNew) {
      masterHue = masterHueNew;
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

  // Parse master transition string into parameters.
  // The following are possible formats for transition string:
  //  "" (empty string) - default (unspecified). arbitrary transition.
  //  "F/V/C" - Fixed color with specified value and chroma in the sphere.
  //  "C/ref[/value]" - Complementary. Transition to opposite ref in the sphere
  //                    with optional value
  //  "H/ref/delta" - Move hue by delta with the same value/chroma from ref.
  //  "M/ref/delta" - Move chroma by delta with the same hue/value from ref.
  //  "V/ref/delta" - Move value by delta with the same hue/chroma from ref.
  //  "A/ref/delta" - Move by delta from ref in any direction in the sphere.
  public void parseTransParams()
  {
    if (transParsed)
      return;  // done already

    transParam1 = transDefault;
    transParam2 = transParam3 = 0;
    
    try {
      // get the 1st param - transition type
      String[] data = masterTransition.split("/");
      switch (data[0]) {
        default:
        case "":  transParam1 = transDefault; break;
        case "F": transParam1 = transFixed; break;
        case "C": transParam1 = transComplementary; break;
        case "H": transParam1 = transHueVariant; break;
        case "M": transParam1 = transChromaVariant; break;
        case "V": transParam1 = transValueVariant; break;
        case "A": transParam1 = transAnalogous; break;
      }    
      // get the remaing parameters
      if (transParam1 != transDefault) {
        transParam2 = Integer.parseInt(data[1]);
        if (transParam1 == transComplementary && data.length < 3)
          transParam3 = -1;  // take default for complementary
        else
          transParam3 = Integer.parseInt(data[2]);
      }
    } catch (Exception e) {
      transParam1 = transDefault;
      transParam2 = transParam3 = 0;
    }
    
    transParsed = true;
  }
  
  // Get the size of patch area
  public float getSize()
  {
    return points.size();
  }
  // Get the length of patch contour
  public float getLength()
  {
    return contourPoints.size();
  }
  
  // Scale all the pixel locations within the patch
  public void scale(float xScale, float yScale)
  {
    for (PVector p : points) {
      p.x *= xScale;
      p.y *= yScale;
    }
    for (PVector p : contourPoints) {
      p.x *= xScale;
      p.y *= yScale;
    }
    xMin *= xScale;
    xMax *= xScale;
    yMin *= xScale;
    yMax *= xScale;
  }
  
  // Create string for the patch info
  public String getString()
  {
    return  "Patch ID: " + id +
            "\nArea: " + String.format("%,d", (int)getSize()) +
                         String.format(" (%,d)", (int)getLength()) +
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
  public void draw(PImage img, int kind)
  {
    switch (kind) {
      case areaViewColors: // Draw local color of the patches
        drawPoints(img, rgbColor);
        break;
      case areaViewMGray: // Draw master gray-level of the patches
        drawPoints(img, colorTable.munsellToRGB(new MunsellColor(0, 0, masterGray)));
        break;
      case areaViewMHue: // Draw master hue of the patches
        // use value=12, chroma=10 to cover all hues
        float v = 12;
        float ch = (masterHue < 0) ? 0 : 10;
        float x = ch * cos(radians(masterHue));
        float y = ch * sin(radians(masterHue));
        drawPoints(img, colorTable.munsellToRGB(new MunsellColor(x, y, v)));
        break;
      case areaViewTension: // Draw tension of the local color
      case areaViewMTension: // Draw master tension
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
      case areaViewMTransition: // Draw master transition - handled at painting level
      default:
        break;
    }
  }
  
  // Draw the color patch to the image with given color
  public void drawPoints(PImage img, color c)
  {
    // Draw area inside
    for (PVector p : points) {
          img.set((int)p.x, (int)p.y, c);
    }
    // Draw contour
    if (bShowContour) {
      for (PVector p : contourPoints) {
            img.set((int)p.x, (int)p.y, colorEdge);
      }
    }
  }
}
