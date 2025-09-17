// Conversion between Munsell Color and sRGB.
// It is based on the article by Paul Centore at
// https://www.munsellcolourscienceforpainters.com/ConversionsBetweenMunsellAndsRGBsystems.pdf.
//
// Note that I use Munsell Color system as a contiguous space rather than quantized
// as published in the paper. However, I rely on the mapping table (mToRGB)
// whenever I need to display a Munsell color and the mapping entry is quantized.
// 
// There are several modifications that I made either directly 
// to the original mapping table, or at loading time as conversion.
//   (1) I doubled the Value (lightness) scale at loading time
//       because I think Value is more discriminative than the original 
//       Munsell value scale.
//   (2) I modified the original table so that it uses hue number within
//       [0, 10) rather than (0, 10]. This was done by replacing 10.0-<hueCode>
//       as 0.0-<the next hueCode>.
//   (3) I also added 0.0R-value-0 for neutral values (N-value).
//   (4) At loading time, I limit the range of chroma for each hue/value 
//       combination to the colors that I could generate from affordable oil colors.
//
public class ColorTable 
{
	private HashMap<String, Color> mToRGB = new HashMap<>();
  private HashMap<Color, MunsellColor> rgbToM = new HashMap<>();

  // Max chroma for each hue/value combination.
  // The limitation table started from Paul Centore's book,
  // Controlling Colour with the Munsell System, where its limitation is
  // based upon his gamut (i.e., printer inks).
  public int getMaxChroma(String hc, float hn, float v)
  {
    MunsellColor mc = new MunsellColor(hc, hn, 10, 2);
    return getMaxChroma(mc.hueDegree, v);
  }
  public int getMaxChroma(float hd, float v)
  {
    final int maxChromaTable[][] = {
                 /* 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 <-- Munsell values: 0-10 */
      /* 0.0R  */ { 0, 4, 8,10,16,18,14, 8, 4, 0, 0},
      /* 2.5R  */ { 0, 4, 8,10,16,16,12,10, 4, 0, 0},
      /* 5.0R  */ { 0, 2, 8,10,14,14,12, 8, 4, 0, 0},
      /* 7.5R  */ { 0, 2, 6,12,16,12,12, 8, 4, 0, 0},
      
      /* 0.0YR */ { 0, 2, 6,10,12,14,12, 8, 4, 0, 0},
      /* 2.5YR */ { 0, 2, 4, 8,10,12,16, 8, 4, 0, 0},
      /* 5.0YR */ { 0, 2, 4, 6, 8,12,14,10, 6, 0, 0},
      /* 7.5YR */ { 0, 0, 2, 6, 8,10,12,16, 4, 0, 0},

      /* 0.0Y  */ { 0, 0, 2, 6, 8,10,12,14, 6, 0, 0},
      /* 2.5Y  */ { 0, 0, 2, 4, 6,10,10,14,10, 2, 0},
      /* 5.0Y  */ { 0, 0, 2, 4, 6, 8,10,14,16, 2, 0},
      /* 7.5Y  */ { 0, 0, 2, 4, 6, 8,10,12,14, 6, 0},

      /* 0.0GY */ { 0, 2, 2, 4, 6, 8,10,12,14,14, 0},
      /* 2.5GY */ { 0, 2, 4, 4, 6, 8,10,12,12, 4, 0},
      /* 5.0GY */ { 0, 2, 4, 6, 8, 8,12,12,12, 4, 0},
      /* 7.5GY */ { 0, 2, 4, 6, 8,10,14,12, 8, 2, 0},

      /* 0.0G  */ { 0, 2, 6, 8,10,14,14,12, 6, 0, 0},
      /* 2.5G  */ { 0, 4, 8,12,16,16,14,10, 4, 0, 0},
      /* 5.0G  */ { 0, 4,10,14,16,14,14,10, 4, 0, 0},
      /* 7.5G  */ { 0, 4, 8,14,14,14,12,10, 4, 0, 0},

      /* 0.0BG */ { 0, 2,10,12,16,14,14,10, 4, 0, 0},
      /* 2.5BG */ { 0, 4, 8,14,14,14,12, 8, 4, 0, 0},
      /* 5.0BG */ { 0, 2, 8,10,14,12,12, 8, 4, 0, 0},
      /* 7.5BG */ { 0, 2, 8,12,12,14,12, 8, 4, 0, 0},

      /* 0.0B  */ { 0, 4, 8,10,10,14,10,10, 4, 0, 0},
      /* 2.5B  */ { 0, 4, 6, 8,10,14,12,10, 4, 2, 0},
      /* 5.0B  */ { 0, 4, 8, 8,12,12,14,10, 4, 2, 0},
      /* 7.5B  */ { 0, 4, 6,10,12,16,14,10, 6, 2, 0},

      /* 0.0PB */ { 0, 4, 8,12,14,16,12, 8, 4, 0, 0},
      /* 2.5PB */ { 0, 6,10,14,18,16,12, 8, 4, 0, 0},
      /* 5.0PB */ { 0, 8,12,16,16,14,12, 8, 4, 0, 0},
      /* 7.5PB */ { 0,14,18,18,14,12,10, 6, 4, 0, 0},

      /* 0.0PB */ { 0,12,18,18,14,12,10, 6, 4, 0, 0},
      /* 2.5P  */ { 0,12,18,18,14,14,10, 8, 4, 0, 0},
      /* 5.0P  */ { 0,10,16,18,16,16,10, 8, 4, 0, 0},
      /* 7.5P  */ { 0, 6,14,16,18,16,12, 8, 4, 2, 0},

      /* 0.0RP */ { 0, 6,14,16,18,18,14,12, 6, 2, 0},
      /* 2.5RP */ { 0, 6,12,16,18,18,18,10, 4, 2, 0},
      /* 5.0RP */ { 0, 4,10,14,18,20,16,10, 6, 2, 0},
      /* 7.5RP */ { 0, 4,10,12,18,18,14, 8, 4, 0, 0},
    };
    
    assert hd >= 0 && hd < 360 : "Invalid hueDegree";
    int hi = int(hd / hueDegreePerSector);
    int vi = int(v / 2);
    
    int maxChroma = 0;
    if (hi >= 0 && hi < 40 && vi < 11)
      maxChroma = maxChromaTable[hi][vi];
    return maxChroma;
  }
  public int getMaxChroma(float hd)
  {
    int maxChroma = 0;
    for (int v = 0; v <= 20; v++) {
      maxChroma = max(maxChroma, getMaxChroma(hd, v));
    }
    return maxChroma;
  }
  public int getMinValue(float hd, float c)
  {
    int minValue = 0;
    while (minValue < 20 && getMaxChroma(hd, minValue) < c)
      minValue += 2;
    return minValue;
  }
  public int getMaxValue(float hd, float c)
  {
    int maxValue = 20;
    while (maxValue > 0 && getMaxChroma(hd, maxValue) < c)
      maxValue -= 2;
    return maxValue;
  }

  // Load the conversion tables from CSV files to hash maps
  @SuppressWarnings("resource")
	public void loadTable()	
  {
    try {
      BufferedReader fileMToRGB = new BufferedReader(new FileReader(dataPath("Munsell2RGB.csv")));
      BufferedReader fileRGBToM = new BufferedReader(new FileReader(dataPath("RGB2Munsell.csv")));
  
      // Parse MunsellToRGB table
  		fileMToRGB.readLine();  // Skip the first (header) line
  		for (String line = ""; (line = fileMToRGB.readLine()) != null; ) {
  
  			String[] data = line.split(","); // split strings in the CSV file
  
        // Load <hueKey, Color> to mToRGB map
        Scanner sc = new Scanner(data[0]);
        sc.findInLine("(\\d+\\.\\d)(.*)-(\\d+)-(\\d+)");
        MatchResult rs = sc.match();
        float hueNumber = Float.parseFloat(rs.group(1));
        String hueCode = rs.group(2);
        float value = Integer.parseInt(rs.group(3)) * 2;
        float chroma = Integer.parseInt(rs.group(4));
        if (chroma > getMaxChroma(hueCode, hueNumber, value)) 
          continue;
        String hueKey = String.format("%.1f", hueNumber) + hueCode + 
                        "-" + (int)value + "-" + (int)chroma;
        Color c = new Color(Integer.parseInt(data[1]), Integer.parseInt(data[2]), Integer.parseInt(data[3]));
        mToRGB.put(hueKey, c);
        
        // Add reverse map as I sometimes use the RGB value of a Munsell color
        // within PImage for the sake of certain calculation performance. These
        // RGB need to be directly mapped to the original Munsell color whenever needed.
        // This reverse lookup makes it possible.
        MunsellColor mc = new MunsellColor(hueCode, hueNumber, value, chroma);
        rgbToM.put(c, mc);
      }
  
      // Parse RGBToMunsell table
      fileRGBToM.readLine();  // Skip the first (header) line
      for (String line = ""; (line = fileRGBToM.readLine()) != null; ) {
    
  			String[] data = line.split(",");
  
        Color c = new Color(Integer.parseInt(data[0]), Integer.parseInt(data[1]), Integer.parseInt(data[2]));
        String hueCode = data[3];
        float hueNumber = Float.parseFloat(data[4]);
  			float value = Float.parseFloat(data[5]) * 2;
        float chroma = Float.parseFloat(data[6]);
  			MunsellColor mc = new MunsellColor(hueCode, hueNumber, value, chroma);
   			if (!rgbToM.containsKey(c))  // do not overwrite a reverse lookup if exists
          rgbToM.put(c, mc);
  		}  

  		fileMToRGB.close();
  		fileRGBToM.close();
    } catch (Exception ignore) { }
	}

  // Does the color exist in the Munsell to RGB mapping table?
  public Boolean isMunsellKeyInMap(MunsellColor mc) 
  {
    return mToRGB.get(quantizeMunsellKey(mc)) != null;
  }
  
  // Find RGB color that matches the Munsell color
  public color munsellToRGB(MunsellColor mc) 
  {
    Color rgb = munsellToRGBInternal(mc);
    return color(rgb.getRed(), rgb.getGreen(), rgb.getBlue());
  }

  // Internal function to find RGB Java Color that matches the Munsell color.
  // This function is mainly used for display a Munsell color at an RGB screen.
	private Color munsellToRGBInternal(MunsellColor mc) 
  {
    // Not all combinations of H/V/C exist in the table.
    // We try to find the nearest one in the quantized Munsell sphere
    // within sqrt(15) distance from the original color.
    Color rgb = mToRGB.get(quantizeMunsellKey(mc));
    if (rgb != null)
      return rgb;
      
    PVector coord = mc.getCoordinate();
    float incr = max(0.1, mc.chroma / 40);  // take smaller step toward the center
    for (float lb = -Float.MAX_VALUE, ub = 0; ub < 20; lb = ub, ub += incr) {
      for (float x = -ub; x <= ub; x += incr) {
        for (float y = -ub; y <= ub; y += incr) {
          for (float z = -ub; z <= ub; z += incr) {
            float d = sqrt(x * x + y * y + z * z);
            if (d > lb && d <= ub) {
              PVector np = coord.copy().add(x, y, z);
              rgb = mToRGB.get(quantizeMunsellKey(new MunsellColor(np)));
              if (rgb != null)
                return rgb;
            }
          }
        }
      }
    }
    
    if (debug)
      println("Munsell Color Not Found:", mc.hueNumber, mc.hueCode, mc.value, mc.chroma);

    return null;
  }

  // Find a Munsell color that matches the color  
  public MunsellColor rgbToMunsell(color c) 
  {
    return rgbToMunsellInternal(new Color((int)red(c), (int)green(c), (int)blue(c)));
  }
  
  // Internal function to a Munsell color that matches the Java Color  
	private MunsellColor rgbToMunsellInternal(Color rgb) 
  {
    // Try exact entry first
    MunsellColor mc = rgbToM.get(rgb);
    if (mc != null)
      return mc;
      
    // RGB table does not cover all possible RGB values.
    // The entry values increases by 17 rather than continuously.
    // When the rgb entry is not found, we try the nearest one
    // within sqrt(15) distance for all rgb directions.
    final int interval = 17;
    
    int red = interval * round((float)rgb.getRed() / interval);
    int green = interval * round((float)rgb.getGreen() / interval);
    int blue = interval * round((float)rgb.getBlue() / interval);

    for (int s = 0; s < 15; s++) {
      float lb = (s == 0) ? -Float.MAX_VALUE : sqrt(s - 1);
      float ub = sqrt(s);
      int m = ceil(ub);
      for (int i = -m; i <= m; i++) {
        for (int j = -m; j <= m; j++) {
          for (int k = -m; k <= m; k++) {
            float d = sqrt(i * i + j * j + k * k);
            if (d > lb && d <= ub) {
              int r = red + i * interval;
              int g = green + j * interval;
              int b = blue + k * interval;
              if (r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255)
                continue;
        
              mc = rgbToM.get(new Color(r, g, b));
              if (mc != null) {
                return mc;
              }
            }
          }
        }
      }
    }
    
    // Not found so far
    if (rgb.getBlue() > 187) { // Remedy for missing entries for high blue
      return rgbToMunsellInternal(new Color(rgb.getRed(), rgb.getGreen(), 187));
    }    

    if (debug) {
      println("RGB Not Found:", rgb.getRed(), rgb.getGreen(), rgb.getBlue());
    }

		return null;
	}
}

// Quantize the Munsell color key so that it can be used as a key
// entry for the Munsell to RGB mapping table. The mapping key has the format
// of [hue number][hue code]-[value]-[chroma], where hue number has one digit for
// fractional part, while value and chroma are a whole integer.
String quantizeMunsellKey(MunsellColor mc) 
{
  int v = round(mc.value / 2) * 2;
  int c = 2 * round(mc.chroma / 2);  // nearest even number

  // I use 0.0R-V-C format for pure grey, rather than Nv in the mapping table.
  if (c == 0)
    return "0.0R-" + v + "-0";

  String hc = mc.hueCode;
  float hn = 2.5 * round(mc.hueNumber / 2.5);
  if (hn > 7.5) {
    // hueNumber as key needs to be represented as the nearest multiple
    // of 2.5 from 0 to 7.5. A hueNumber quantized to greater than 7.5 
    // better be represented as 0.0 of next hue.
    int hi;
    for (hi = 0; hi < hueCodes.length; hi++) {
      if (mc.hueCode.equals(hueCodes[hi]))
        break;
    }
    assert hi < hueCodes.length : "Invalid hueCode";
    hi = (hi == hueCodes.length - 1) ? 0 : hi + 1;
    hc = hueCodes[hi];
    hn = 0.0;
  }

  return String.format("%.1f", hn) + hc + "-" + v + "-" + c;
}
