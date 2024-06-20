// Constants - some are fuzzy, picked based upon by my experimentation
final int minPatchSize = 30;  // min # of pixels to form a patch
final int contourColorThreshold = 60;  // RGB diff to identify contour line

// Class for an individual Color Patch
class ColorPatch
{
  public int id;  // ID of the patch: serial number starting from 0
  public ArrayList<PVector> points; // coordinates of all the points
  public float xMin, xMax, yMin, yMax;  // dimension of the contour in rectangle
  public float masterGray;  // master gray level. 0 if not specified
  public float masterHue;  // master hue degree. negative if not specified
  public float masterTension;  // master tension. 0 if not specified
  public MunsellColor mColor; // painted Munsell color of the patch - always one from the quantized map (mToRGB)
  public color rgbColor; // RGB color of mColor for display
  public float gGap;  // Color Gap in terms of gray level against the centroid
  public float cGap;  // Color Gap in terms of color against the centroid
  public PVector coord;  // Color Coordinate
  
  // default constructor
  public ColorPatch() {}
  
  // Constructor to build a patch from pixels
  public ColorPatch(int id, PImage img, ArrayList<PVector> pts)
  {
    this.id = id;
    points = pts;
    assert points.size() > 0 : "Empty color patch: <" + points.size() + ">";

    // Set the dimension
    xMin = Integer.MAX_VALUE;
    xMax = Integer.MIN_VALUE;
    yMin = Integer.MAX_VALUE;
    yMax = Integer.MIN_VALUE;
    for (PVector p : pts) {
      xMin = min(xMin, p.x);
      xMax = max(xMax, p.x);
      yMin = min(yMin, p.y);
      yMax = max(yMax, p.y);
    }
    
    // Initialize master color/tension
    masterGray = 0;
    masterHue = -1;
    masterTension = 0;

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
    setColor(color(rSum / np, gSum / np, bSum / np));
    
    // Make sure the value of the color is within [2, 18] for painting purpose.
    // Value outside this range won't be honored when selecting a color in painting.
    if (mColor.value < 2 || mColor.value > 18) {
      mColor.value = min(18, mColor.value);
      mColor.value = max(2, mColor.value);
      setColor(mColor);
    }

    gGap = cGap = 0; // set by updateGap() later
    coord = null; // use as coordinate workspace later in analysis
  }
  
  // Copy constructor for a shallow copy to experiment all while keeping the shape and location
  public ColorPatch(ColorPatch p)
  {
    id = p.id;
    points = p.points;  // shallow copy
    xMin = p.xMin; xMax = p.xMax; yMin = p.yMin; yMax = p.yMax;
    masterGray = p.masterGray;
    masterHue = p.masterHue;
    masterTension = p.masterTension;
    mColor = new MunsellColor(p.mColor);
    rgbColor = p.rgbColor;
    gGap = p.gGap; 
    cGap = p.cGap;
    coord = null;  // no need to copy as it is used as workspace as needed
  }
  
  // Serialize to save
  public void Serialize(ObjectOutputStream oos) throws IOException
  {
    oos.writeInt(id);
    oos.writeObject(points);
    oos.writeFloat(xMin); oos.writeFloat(xMax); oos.writeFloat(yMin); oos.writeFloat(yMax);
    oos.writeFloat(masterGray);
    oos.writeFloat(masterHue);
    oos.writeFloat(masterTension);
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
    xMin = ois.readFloat(); xMax = ois.readFloat(); yMin = ois.readFloat(); yMax = ois.readFloat();
    masterGray = ois.readFloat();
    masterHue = ois.readFloat();
    masterTension = ois.readFloat();
    mColor = new MunsellColor(); mColor.Deserialize(ois);
    rgbColor = ois.readInt();
    gGap = ois.readFloat();
    cGap = ois.readFloat();
  }
  
  // Set the color from an RGB color
  public void setColor(color c)
  {
    setColor(colorTable.rgbToMunsell(c));
  }
  // Set the color from a Munsell color
  public void setColor(MunsellColor mc)
  {
    // set RGB from the quantized mapping table to make sure 
    // the RGB is always the one driven from the mapping table.
    rgbColor = colorTable.munsellToRGB(mc);
    // Now, we set quantized Munsell color for the RGB
    mColor = new MunsellColor(colorTable.rgbToMunsell(rgbColor));
  }
  
  // Set master gray from an RGB color
  public void setMasterGray(color c)
  {
    masterGray = colorTable.rgbToMunsell(c).value;
  }
  // Set master hue from an RGB color
  public void setMasterHue(color c)
  {
    MunsellColor mc = colorTable.rgbToMunsell(c);
    masterHue = mc.isGray() ? -1 : mc.hueDegree;
  }
  
  // Get patch area
  public float getArea()
  {
    return points.size();
  }
  
  // Scale all the pixel locations within the patch
  public void scale(float xScale, float yScale)
  {
    for (PVector p : points) {
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
            "\nArea: " + String.format("%,d", (int)getArea()) +
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
        float ch = (masterHue < 0) ? 0 : 12;
        float x = ch * cos(radians(masterHue));
        float y = ch * sin(radians(masterHue));
        drawPoints(img, colorTable.munsellToRGB(new MunsellColor(x, y, 10)));
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
  }
}
