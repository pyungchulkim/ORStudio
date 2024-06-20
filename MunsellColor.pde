//
// Munsell Color System (the 1943 Munsell Renotations) organizes human color perception 
// in three orthogonal axes: hue, value (lightness) and chroma.
// Hues covers 360 degrees, but they are divided into 10 hue code areas.
// Each hue area also ranges from 0 to 10 (0 would be the same as 10 of previous hue).
// Values are ranges from 0 (darkest) to 10 (lightest). However, I scale it up to 20
// so that the lightness has more discriminative power in my project.
// Chromas are from 0 (pure gray) to pure color and each hue has different
// max chroma. Although in theory, there is no max value in chroma, in reality
// of pigments, 10 seems to be saturated and 20 seems to be affordable max.
// A Munsell color is denoted as [hue number][hue code][value]/[chroma]. 
// For instance, 5.0R8/10 represents a color of hue code is R (red), 
// hue number within the hue code is 5.0 (center), value is 8 and chroma is 10.
//
// Although only a few thousands of selected colors are available in published
// color patches and in the mapping table by Paul Centore covers, the Munsell
// color system is actually in a continous space and produces unlimited colors.
// I keep this continuous Munsell color and apply various mathematical calculation
// on top of. It is only when I need to display a Munsell color to the screen 
// that I use the mapping table, which is quantized.
//
// The Munsell Color System can be visualized in a 3D cylinder,
// where the height represents value, the circular angle represents hue, 
// and the radial distance from the center represents chroma. 
// In reality, maximum chroma of a hue decreases as it becomes white or black.
// This makes the system take roughly a shape of sphere.
// The unit distance of hue, value or chroma axis is carefully created so that
// there is equal amount of perceptual difference. This makes any interpolation
// between the two colors to be perceived as mixture of the two colors.
// For instance, the same value/chroma, but opposite hue colors are interpolated
// into the same value, but 0 chroma (gray) color as they are mixed in equal amount.
//
// Based upon the Munsell Color System as a sphere, I define and use the following 
// terminologies throughout my art project:
//
// * Color Coordinate: I use traditional 3D axes to simply calculation of
// interpolations and such. For this, a Color Coordinate <x, y, z> for 
// a color <hue, value, chroma> in Munsell renotations as follows:
//   x = chroma * cos(hue_radian)
//   y = chroma * sin(hue_radian)
//   z = value
// where hue_radian is the radian amount converted from hue.
// Note that x, y are [0, max chroma] and z is [0, max value]. 
// Theoretically, there is no limit in Munsell chroma, 
// but in my practice, it is limited to 20.
//
// * Color Gap: The perceptial difference between the two colors. It is
// calculated as the Euclidean distance between the two color coordinates.
// E.g., Color Gap between 0R4/0 and 0R5/10 is distance between
// <0,0,4> and <10,0,5>, which is sqrt(10^2+0+1).
// The largest color gap is 80, which is the gap between highest chroma of the two
// opposite hues.
//
// * Color Gradient: Given the two colors with a certain physical distance,
// Color gradient represents the speed of changes from one to another over the
// distance. It is calculated as Color Gap / distance.
//
// * Color Mixture: Two colors are mixed and create a new color.
// When the equal amount of the two colors are mixed, Munsell system indicates that
// the new color is positioned (interpolated) at the center of the line between the
// two colors coordinates in the sphere. When the color amount is different,
// the same interpolation process repeats with the color coordinates of left over and
// the center found at the previous step until no more color is left to mix.
// In theory, this would be never ending when the portion of one color amount out of
// the total amount is repetend (e.g., mixing 2 amount of one color and 1 amount of
// another color). Mathematically, this process yields to the color coordinates as follows:
//
// Suppose color coordinates of two input colors C1 = (x1,y1,z1), C2 = (x2,y2,z2).
// Suppose the amounts of C1 and C2 are a1, a2, respectively.
// Then, the color coordinate of the new (mixed) color C3 = (x3,y3,z3), where
//   a2 * (x2-x3) = a1 * (x3-x1).
// Therefore, x3 = (a1*x1 + a2*x2) / (a1+a2).
// The same process applies to y3, z3.


// The 10 hue codes covering 360 degrees.
// The hue number within a hue code ranges up to 10.0
final String hueCodes[] = { "R", "YR", "Y", "GY", "G", "BG", "B", "PB", "P", "RP"};
final int hueCodesMax = hueCodes.length;
final float hueNumberMax = 10.0;
final float hueDegreePerCode = 360 / hueCodesMax;
final int hueSectorsPerCode = 4;
final float hueDegreePerSector = hueDegreePerCode / hueSectorsPerCode;

final MunsellColor munsellBlack = new MunsellColor(0, 0, 0);

// Class for an individual Munsell color
class MunsellColor
{
  public String hueCode;  // hue code such as "R", "YR", and so on.
  public float hueNumber; // hue number within the hueCode. [0, 10]
  public float hueDegree; // hue as degree in the hue circle. [0, 360]
  public float value;  // value. [0-20]
  public float chroma;  // chroma. [0-40]. unlimited in theory, though.
  public PVector coord;  // coordinate in the sphere - populated on-demand for performance

  // default constructor
  public MunsellColor() {}
  
  // Constructor from hue code, hue number, value and chroma
  public MunsellColor(String hc, float hn, float v, float c) 
  {
    // Get hue code index
    int hi;
    for (hi = 0; hi < hueCodes.length; hi++) {
      if (hc.equals(hueCodes[hi]))
        break;
    }
    assert hi < hueCodesMax : "Invalid hueCode";
    assert hn >= 0 && hn <= hueNumberMax : "Invalid hueNumber"; 

    hueCode = hc;
    hueNumber = hn;
    hueDegree = hi * hueDegreePerCode + hn * (hueDegreePerCode / hueNumberMax);
    value = v;
    chroma = c;
    coord = null;
  }
  
  // Copy constructor
  public MunsellColor(MunsellColor mc)
  {
    this.hueCode = mc.hueCode;
    this.hueNumber = mc.hueNumber;
    this.hueDegree = mc.hueDegree;
    this.value = mc.value;
    this.chroma = mc.chroma;
    this.coord = null;
  }

  // Constructor from coordinates
  public MunsellColor(float x, float y, float z) 
  {
    this(getMunsellHueCode(x, y), getMunsellHueNumber(x, y), z, sqrt(x * x + y * y));
  }
  
  // Constructor from coordinates
  public MunsellColor(PVector pv) 
  {
    this(pv.x, pv.y, pv.z);
  }
  
  // Copy to
  public void copyTo(MunsellColor mc)
  {
    mc.hueCode = hueCode;
    mc.hueNumber = hueNumber;
    mc.hueDegree = hueDegree;
    mc.value = value;
    mc.chroma = chroma;
    mc.coord = null;
  }

  // Serialize to save
  public void Serialize(ObjectOutputStream oos) throws IOException
  {
    oos.writeObject(hueCode);
    oos.writeFloat(hueNumber);
    oos.writeFloat(hueDegree);
    oos.writeFloat(value);
    oos.writeFloat(chroma);
  }
  
  // Deserialize to load
  public void Deserialize(ObjectInputStream ois) throws IOException, ClassNotFoundException
  {
    hueCode = (String)ois.readObject();
    hueNumber = ois.readFloat();
    hueDegree = ois.readFloat();
    value = ois.readFloat();
    chroma = ois.readFloat();
  }
  
  // Compare if it is the same color
  boolean isEqual(MunsellColor mc)
  {
    return getString().equals(mc.getString());
  }
  
  // See if it is a pure gray color
  boolean isGray()
  {
    return chroma == 0;
  }
  
  // String representation of Munsell color.
  public String getString() 
  {
    return String.format("%.1f", hueNumber) + hueCode + " " + 
           String.format("%.1f", value) + "/" + 
           String.format("%.1f", chroma);
  }
  
  public PVector getCoordinate()
  {
    if (coord == null) {
      coord = new PVector(chroma * cos(radians(hueDegree)), 
                          chroma * sin(radians(hueDegree)), value);
    }
    return coord;
  }

  // Calculate Color Gap from another color. Gap is [0, 2 * max chroma]
  public float getGap(MunsellColor mc)
  {
    return getCoordinate().dist(mc.getCoordinate());
  }
  
  // Calculate Color Mixture from another color with specified amount ratio
  public MunsellColor getMixture(MunsellColor mc, float ratio)
  {
    PVector c1 = getCoordinate();
    PVector c2 = mc.getCoordinate();
    PVector c3 = c1.copy().add(PVector.mult(c2, ratio)).div(1 + ratio);
    return new MunsellColor(c3);
  }
}

// Get hue code at the current x, y location of hue circle
String getMunsellHueCode(float x, float y) 
{
  // Obtain the angle in degree
  float a = degrees(atan2(y, x));
  if (a < 0) a = 360 + a;  // [0, 360)

  // Obtain hue code
  int hi = min(hueCodesMax -1, (int)(a / hueDegreePerCode));
  return hueCodes[hi];
}

// Get hue number at the current x, y location of hue circle
float getMunsellHueNumber(float x, float y) 
{
  // Obtain the angle in degree
  float a = degrees(atan2(y, x));
  if (a < 0) a = 360 + a;  // [0, 360)

  // Obtain hue number
  float hn = a % hueDegreePerCode;  // [0, hueDegreePerCode)
  hn = hn / hueDegreePerCode * hueNumberMax;  // [0, hueNumberMax)
  return hn;
}

// Draw Munsell Value/Chroma spectrum at <x, y> with w x h for the selected hue.
// I skip the colors that the mapping table (mToRGB) does not have an RGB entry for
void drawMunsellValueChroma(String hueCode, float hueNumber, float x, float y, float w, float h) 
{
  float cellW = w / 11;  // cell width for 11 chromas
  float cellH = h / 11;  // cell height for 11 values
  stroke(colorBG);

  for (int v = 0; v < 11; v++) {
    for (int c = 0; c < 11; c++) {
      MunsellColor mc = new MunsellColor(hueCode, hueNumber, v * 2, c * 2);
      color pc = colorBG;
      if (colorTable.isMunsellKeyInMap(mc)) {
        pc = colorTable.munsellToRGB(mc);
      }
      fill(pc);
      rect(x + c * cellW, y + (10 - v) * cellH, cellW, cellH);
    }
  }
}

// Draw Munsell Value/Chroma spectrum at <x, y> with w x h and
// highlight the color cell
void drawMunsellValueChroma(MunsellColor mc, float x, float y, float w, float h) 
{
  drawMunsellValueChroma(mc.hueCode, mc.hueNumber, x, y, w, h);

  float cellW = w / 11;  // cell width for 11 chromas
  float cellH = h / 11;  // cell height for 11 values
  stroke(colorEdge); noFill();
  rect(x + (mc.chroma / 2) * cellW, y + (10 - (mc.value / 2)) * cellH, cellW, cellH);
}

// Draw Munsell Hue as a circle at <x, y> with radius r.
void drawMunsellHueCircle(float x, float y, float r) 
{  
  // Quantize the hue circle for display:
  // Each hue code has 4 sectors with hue code 2.5, 5.0, 7.5, 10.

  // Values of highest chromatic color for each hue.
  // These numbers are chosen from the conversion table: mToRGB.
  final float values[] = {
    /* R  */ 10,10,10,10,
    /* YR */ 12,12,14,14,
    /* Y  */ 14,16,16,16,
    /* GY */ 14,14,14,14,
    /* G  */ 12,12,12,12,
    /* BG */ 12,12,12,12,
    /* B  */ 12,12,12,12,
    /* PB */ 10,10, 8, 8,
    /* P  */  8, 8, 8, 8,
    /* RP */ 10,10,10,10
  };

  stroke(colorBG);
  beginShape(TRIANGLE_FAN);
  vertex(x, y);  // start from the center
  float angle = hueDegreePerSector / 2;
  PVector p = null;
  for (int i = 0; i < hueCodes.length; i++) {
    for (int j = 0; j < hueSectorsPerCode; j++) {
      float hn = (j + 1) * 2.5;
      float v = values[i * hueSectorsPerCode + j];
      MunsellColor mc = new MunsellColor(hueCodes[i], hn, v, 
                colorTable.getMaxChroma(hn, hueCodes[i], v));
      p = PVector.fromAngle(radians(angle)).mult(r);
      vertex(x + p.x, y + p.y);
      fill(colorTable.munsellToRGB(mc));
      angle += hueDegreePerSector;
    }
  }
  p = PVector.fromAngle(radians(angle)).mult(r);
  vertex(x + p.x, y + p.y);  // the last closing vertex
  endShape();
}

// Generate colors that are within variation (radius) of the center in terms of
// hue and chroma. Only the value nearest to 10 for each hue/chroma is generated.
ArrayList<MunsellColor> generateColorsByPoint(MunsellColor center, float variation)
{
  ArrayList<MunsellColor> mcs = new ArrayList<MunsellColor>();
  PVector pCenter = new PVector(center.getCoordinate().x, center.getCoordinate().y);

  // Find colors within the range with the same value
  for (int h = 0; h < 360; h += hueDegreePerSector) {
    for (int c = 20; c >= 2; c -= 2) { // from high to low chroma
      PVector p = PVector.fromAngle(radians(h)).mult(c);
      float d = p.dist(pCenter);
      if (d > variation)
        continue;

      // Find a value of the hue/chroma near center to display distinctively
      MunsellColor mcFound = null;
      int[] vd = {0, 2, -2, 4, -4, 6, -6, 8, -8};
      for (int i = 0; i < vd.length; i++) {
        MunsellColor mc = new MunsellColor(p.x, p.y, 10 + vd[i]);
        if (colorTable.isMunsellKeyInMap(mc)) {
          mcFound = mc;
          break;
        }
      }
      if (mcFound != null) {
        mcs.add(mcFound);
      }
    }
  }
  return mcs;
}

// Generate colors that are within variation (radious) of the line from mc1 to mc2
// in terms of hue and chroma. Only the value nearest to 10 for each hue/chroma is generated.
ArrayList<MunsellColor> generateColorsByLine(MunsellColor mc1, MunsellColor mc2, float variation)
{
  ArrayList<MunsellColor> mcs = new ArrayList<MunsellColor>();
  
  PVector p2 = new PVector(mc1.getCoordinate().x, mc1.getCoordinate().y);
  PVector p3 = new PVector(mc2.getCoordinate().x, mc2.getCoordinate().y);
  
  // Find out starting hue and direction so the colors are generated
  // in the order from mc1 to mc2.
  float ad = mc2.hueDegree - mc1.hueDegree;
  if (ad < 0) ad += 360;
  int dir = (ad < 180) ? 1 : -1;
  float back = -dir * hueDegreePerCode * 2;
  for (int h = 0; h < 360 && h > -360; h += dir * hueDegreePerSector) {
    for (int c = 20; c >= 2; c -= 2) { // from high to low chroma
      PVector p1 = PVector.fromAngle(mc1.hueDegree + back + h).mult(c);

      // Skip if this color is outside the line range
      if (PVector.angleBetween(PVector.sub(p1, p2), PVector.sub(p3, p2)) > PI/2 ||
          PVector.angleBetween(PVector.sub(p1, p3), PVector.sub(p2, p3)) > PI/2)
        continue;

      // Skip if this color is too far from the line
      if (distanceFromPointToLine(p1, p2, p3) > variation)
        continue;
        
      // Find a value of the hue/chroma near center to display distinctively
      MunsellColor mcFound = null;
      int[] vd = {0, 2, -2, 4, -4, 6, -6, 8, -8};
      for (int i = 0; i < vd.length; i++) {
        MunsellColor mc = new MunsellColor(p1.x, p1.y, 10 + vd[i]);
        if (colorTable.isMunsellKeyInMap(mc)) {
          mcFound = mc;
          break;
        }
      }
      if (mcFound != null) {
        mcs.add(mcFound);
      }
    }
  }
  return mcs;
}

// Calculate distance from a point P1 to a line connecting P2, P3
float distanceFromPointToLine(PVector p1, PVector p2, PVector p3)
{
  float b = p2.dist(p3);
  float s = abs((p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x));
  return (b == 0) ? Float.MAX_VALUE : s / b;
}
