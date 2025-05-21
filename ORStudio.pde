// OrderedRandom Studio (ORStudio)
//
// OrderedRandom Studio (ORStudio) is a program that I developed for my 
// experimentation on color harmony. My typical painting process is that 
// I first focus on narration and rhythm using lines and shapes in drawing. 
// Then, I bring the drawing into ORStudio to experiment various color sensation
// over the drawing. After the color study with ORStudio, I make the final 
// archival painting, typically using oil on canvas.
// 
// ORStudio only focuses on color harmony. Lines, shapes, texture, and rhythms
// in them should have been done prior to bringing it to ORStudio.
// Once a drawing is brought to ORStudio, I model it as collection of color
// patches. As far as ORStudio is concerned, "painting" means applying colors
// to the color patches. ORStudio is for experimentaion on color harmony 
// and never meant to produce a final painting. ORStudio is just to save 
// time and materials on the experimentation which would have costed too much, 
// had it to be done with actual paints and canvases.
//
// Note that ORStudio is built upon my own art process. Though some concepts in
// ORStudio may be common to artists, many are very unique to my own process and 
// others might find them not applicable to their process.
// ORStudio generates thousands of "paintings" (i.e., applying colors into patches)
// within a few seconds. The generation process is guided by several criteria.
// Color experimentation with ORStudio is mainly about designing such criteria.
// The design is a repetitive process until the artist finds a satisfied set of
// criteria. The criteria consist of the following four components:
//
// (1) Master specification: The master specification is more about overall design
//     of the painting in terms of color experience, without having any specific color
//     in mind yet. Master specification includes design of tension, gray level and hue.
//     Tension is the most important part of color experience. Unity in variety,
//     or order in randomness is the ultimate experience to pursue in color design,
//     and tension design is the single most effective tool to achieve it. Gray level
//     and hue may be included in the master specification if needed. For instance,
//     gray level specification could be used to keep the narration that the source
//     drawing might have. It is a similar approach that old masters had, which is
//     color glazing over chiaroscuro drawing. Hue can also be specified if color choices
//     need to be limited to a specific hue. For instance, patches for sky could be
//     limited to blue.
//
// (2) Color chords: There are thousands of studies on color harmony. Yet, there does
//     not seem to be one that many artists agree with and share, like in music.
//     However, I personally believe in two principles when it comes to our aesthetic
//     experiences of color combination. The first principle is simplicity. 
//     Our brain prefers a simpler way to recognize anything. It gets positive 
//     aesthetic experience when it finds a path to simplify. This is how harmony in
//     musical chords have been established; one note sets a particular path in
//     our brain and the following note meets the expectation of the path by
//     simple proportion of the previous frequency. Similarly, one color creates
//     a particular color expectation and our brain get pleased when it sees another
//     color that meets the expectation by simple transition. Simplicity is coming
//     from the fact that our brain relentlessly pursues an economic way of processing
//     information (i.e., doing more with less efforts). The second principle is 
//     that a color creates a particular fatigue in our eyes. The fatigue
//     created by one color seeks for another color that can neutralize the first color
//     in terms of both hue and brightness. This tendency is very unique to our visual
//     perception. It greatly impacts our experiences on color interaction, which have
//     been demonstrated in numerous patintings by Josef Albers.
//     In ORStudio, a color chord consists of either one or two colors. 
//     A one-colored chord generates colors that are analogous to each other and 
//     simply recognized by our brain without too much transition. A two-colored
//     chord generates colors that transition from one color to another color,
//     typically creating an expectation followed by meeting the expectation.
//
// (3) Centroid: The tension in master specification is relative to the centroid.
//     The typical centroid would be the neutral gray. However, the centroid could be
//     shifted to elsewhere as an artistic choice. Shifting the centroid out of
//     neutral gray will create an ambient color mode.
//
// (4) Complexity measurement: The same master specification with the same centroid and
//     the same color chords can generate a wide variety of color combinations. 
//     All combinations yield similar experiences in terms of tensions, narration
//     and harmonic color transitions. However, one may look busier than others.
//     This is because they differ in complexity. ORStudio uses entropy to measure
//     the complexity of a color combination in a painting. In ORStudio, artists can
//     set a range of complexity so that color combinations for the paintings are 
//     limited within the range.
//
// ORStudio does not have a manual and I do not intend to create one until necessary.
// For now, the source code (comments as well) as well as the following
// example usage scenario should serve the purpose:
//
// - Prepare an image (e.g., PNG) of a drawing to work with. I typically start
//   with my own charcoal drawing. But, for the sake of demonstration, pick any
//   reference photo that has colors in it already. Use Procreate (or any digital 
//   painting tool) to mark the contour line in color that is not used in the 
//   photo already. For instance, either pure red, green, blue, black, 
//   or white would work.
//   Save it to PNG format.
// - Start ORStudio
// - Select "LOAD" button and load the prepared PNG file.
// - Select the contour color by clicking a contour line from the loaded image or
//   by choosing one from the populated palette. 
//   Make sure the right contour color displayed in the selected color rectangle.
//   Select "BUILD C" button to build patches. The image area will change to
//   show patches; each patch has a single color. Also, color plots and patches 
//   summary statistics will be displayed. Rotate up/down, right/left the color plots
//   to see colors being used in the patches. Also, get familiarized with
//   the painting statistics. Clicking any patch in the image area will display
//   the patch info as well.
// - Select "M-GRAY" button and see the master specification for gray level,
//   which is copied from the loaded image by default. You can change it a different
//   gray level by right-clicking the patch. The new gray level is picked up from the
//   current selected color (big rectangle).
// - Select "M-HUE" button and see the master specification for hue,
//   which is set from the loaded image by default. You can change it a different
//   hue by right-clicking the patch. The new hue is picked up from the
//   current selected color (big rectangle).
// - Select "M-TENSION" button and see the master specification for tension. 
//   Blue indicates lowest tension while red the highest. 
//   You can change M-Tension value at the slider bar of the patch info display.
// - Select red from color wheel. Right-click the left-cell of
//   the first chords. The color chord will show red being picked and 
//   several colors within short variance of red will be displayed at the 
//   chord colors spectrum. Try changing the variance slider from default 4 to 10
//   and notice more variants in the spectrum.
// - Select green from color wheel. Right-click the right-cell of the first chord. 
//   Several colors from red to green will be displayed at the chord colors spectrum.
//   Try changing the variance slider and notice color changes in the spectrum.
// - Set the variance slider for red-green chord to maximum (25). This will effectively
//   make the chord to include all colors.
// - Notice "Paintings", "Centroid", "Hue Var." at the control bar.
//   You can change them, but no need for the demonstration.
// - Select "COLORS" button above the image, and select "PAINT" button. Notice that
//   paintings are generated with the criteria selected. It actually generates
//   100 paintings by default and show the first painting for each iteration.
// - Select "PAUSE" button to pause the continuous painting. And press "PREV" or
//   "NEXT" to browse other paintings out of the 100 paintings.
// - They are all within the same guidance criteria (master tension, gray, hue, 
//   centroid, complexity).
// - Select "RESUME" to resume the painting process. While new paintings are generated,
//   adjust "Complexity" slider left or right and notice the range (variety) of colors
//   being painted.
// - Press "PAUSE".
// - Select "SAVE" and provide a name for an ORStudio file to save the current studio.
// - Exit ORStudio by entering the escape key.
// - Start ORStudio
// - Select "OPEN" button and choose the ORStudio file saved in the previous step.
// - You should be able to continue the experimentation from the saved studio session.
// - Try other buttons and keys to try:
//   - "BUILD S" is to build patches based on solid colors. Unlike "BUILD C", a solid
//     with a distinct color will form a patch, rather than based upon contours.
//   - "BUILD SC" is to build patches based on solid colors except the area with
//     the selected color. Then, the selected color area will be broken to patches
//     using contour as boundary.
//   - "SAVE IMG" is to save the current viewing image into a PNG file.
//   - "SAVE PLT" is to save color palette of the current painting as an image file.
//   - "STORE" is to store the current state of the current painting (master and painted colors).
//   - "RESTORE" is to restore the last stored painting.
//   - "THEME" is to quickly preview all colors in the set of color chords
//   - While viewing the source image or the master (M-GRAY, M-HUE, M-TENSION), 
//     the following key can be used to edit the master specification:
//      - 'p' or 'P': master picks up the specs from the current painting;
//      - 'c' or 'C': master gets reset;
//      - '+' or '-': scale up or down the master specs (gray or tension only)
//      - '>' or '<': shift up or down the master specs (gray or tension only)
//      - 'r' or 'R': replace a hue using the last two colors in the color palette
//      - 'control-z': under the last change
//     Note that these may not reflect recent changes. A good place to see key
//     and mouse mappings is doAction() and keyPressed() in the code.
//
// by Pyungchul Kim, 2024
// http://orderedrandom.com
//

import java.util.*;
import java.util.regex.*;
import java.awt.Color;
import java.io.*;
import controlP5.*;

final int numChords = 4;    // number of chords to work with

// Set coordinates and dimensions of all graphics objects.
// Although I use fullScreen(), I do not use displayWidth/displayHeight here
// because they get set later AFTER global variable initalization.
final int screenWidth = 1920;
final int screenHeight = 1080;
final int margin = 20;

// Common for buttons
final int btnWidth = 100;
final int btnHeight = 30;

// Buttons (commands) for Master menu
final int btnMasterX = margin;
final int btnMasterY = margin;

// Location and size of color system - Value Chroma chart
final int vcX = btnMasterX + btnWidth + 30;
final int vcY = btnMasterY;
final int vcWidth = 400;
final int vcHeight = 220;

// Location and size of color system - Hue circle, its center, radius
final int hRadius = 100;
final int hX = vcX + hRadius;
final int hY = vcY + vcHeight + 20 + hRadius;

// Color selected
final int cX = hX + hRadius + 40;
final int cY = hY - hRadius + 5;
final int cWidth = 140;
final int cHeight = 140;

// Color points plot box
final int plotX = vcX + vcWidth + 20;
final int plotY = btnMasterY;
final int plotSize = 300;

// Patch info box
final int infoX = vcX + vcWidth + 20;
final int infoY = plotY + plotSize + 70;
final int infoWidth = plotSize;
final int infoHeight = 100;

// Color chord controls and colors
final int chordX = btnMasterX;
final int chordY = hY + hRadius + 150;
final int chordCellWidth = 50;
final int chordCellHeight = 30;
final int chordColorX = chordX + chordCellWidth * 4 + 40;
final int chordColorY = chordY;
final int chordColorWidth = 610;
final int chordColorHeight = chordCellHeight;

// Color palette
final int cpX = chordColorX;
final int cpY = chordColorY - chordColorHeight - 10;
final int cpWidth = chordColorWidth;
final int cpHeight = chordColorHeight;

// Control parameters
final int ctrlX = btnMasterX;
final int ctrlY = chordY + (chordCellHeight + 10) * numChords + 30;
final int ctrlWidth = 500;
final int ctrlHeight = 20;

// Analysis statistics box
final int statX = ctrlX + ctrlWidth + 70;
final int statY = ctrlY - 10;
final int statWidth = 300;
final int statHeight = 165;

// Buttons for View menu
final int btnViewX = plotX + plotSize + 50;
final int btnViewY = margin;

// Location and size of img workspace
final int imgX = btnViewX;
final int imgY = btnViewY + btnHeight + 10;
final int imgWidthMax = screenWidth - imgX - margin;
final int imgHeightMax = screenHeight - imgY - margin;

// Message box
final int msgX = btnMasterX;
final int msgY = screenHeight - 50 - margin;
final int msgWidth = imgX - 20 - msgX;
final int msgHeight = 30;

// Mouse-pressed location which directs what to do
final int areaValueChroma = 0;
final int areaHue = 1;
final int areaSelectedColor = 2;
final int areaPalette = 3;
final int areaPlot = 4;

// Studio menu
final int areaLoad = 10;
final int areaBuildC = 11;
final int areaBuildS = 12;
final int areaBuildSC = 13;
final int areaOpen = 14;
final int areaSave = 15;
final int areaSaveImg = 16;
final int areaSavePlt = 17;
final int areaStore = 18;
final int areaRestore = 19;

// Theme/Painting menu
final int areaTheme = 30;
final int areaPaint = 31;
final int areaPause = 33;
final int areaResume = 34;
final int areaReset = 35;
final int areaPrev = 36;
final int areaNext = 37;

// Patches view menu
final int areaViewColors = 40;
final int areaViewTension = 41;
final int areaViewMGray = 42;
final int areaViewMHue = 43;
final int areaViewMTension = 44;
final int areaViewMTransition = 45;

final int areaChord = 50;
final int areaChordColor = 51;

final int areaImage = 100;

// Predefined colors
final color colorBG = color(0,0,0);  // background color
final color colorEdge = color(255,255,255);  // edge color
final color colorText = color(255,255,255);  // text color

// Global variables
ControlP5 cp5 = null;  // Control P5 for buttons, sliders, etc
String pathName = null;  // file name from the dialog
PImage imgInput = null;  // input image to generate patches
PImage imgWork = null;  // image at work and used for display at screen
color colorSelected = color(220,63,78);  // selected color. 5.0R-10-14 by default
color[] colorPalette = { color(255), color(0), color(255,0,0), color(0,255,0), color(0,0,255), 
                         color(255,255,0), color(255,0,255), color(0,255,255), colorBG, colorBG }; // color palette
ColorTable colorTable = new ColorTable();  // RGB/Munsell conversion table
PFont fontText = null; // text font througout
float degreeRotateX = 90;  // degree to rotate X-axis of the color points plot
float degreeRotateZ = 0;  // degree to rotate Z-axis of the color points plot
int prevMouseX = -1;  // previous mouseX to handle dragging
int prevMouseY = -1;  // previous mouseY to handle dragging
Chord[] chords = null;  // color chords
ArrayList<MunsellColor> colors = null;  // all colors from all chords
Painter painter = null;  // the painter based upon genetic algorithm
int viewMode = areaViewColors; // indicate what is showing at the image area
ArrayList<Painting> paintings = null;  // the current painting collection
Painting storedPainting = null; // the stored painting to restore to later
int currPaintingIdx = -1;  // current painting index
int currPatchIdx = -1;  // current patch being viewed and edited
int undoPaintingIdx = -1;  // index of the painting saved for undo
Stack<Painting> undoPaintings = null;  // paintings save for undo
int maxUndoPaintings = 200;  // max # of undo operations
int simplifyThreshold = 0; // current threshold for simplification 
int simplifyThresholdIncr = 1;  // threshold increment for simplification
boolean bPause = false;  // painting paused
boolean bDrag = false;  // mouse being dragged
boolean bShift = false;  // shift-key is pressed
boolean debug = true;  // for debugging

// Adjustable control parameters for analysis and new paintings generation
int ctrlNumPaintings = 10;  // # of paintings in a collection
MunsellColor ctrlCentroid = null;  // centroid color for painting
float ctrlHueVariance = 20;  // hue range from master hue
float ctrlTensionScale = 1.0;  // scale to adjust master tension
float[] ctrlComplexity = {2, 2.5};  // complexity target

void setup() 
{
  // Use the entire screen
  fullScreen();
  background(colorBG);
  
  // Initialize global variables
  fontText = createFont("Arial", 18);
  colorTable.loadTable();
  cp5 = new ControlP5(this);
  cp5.setFont(fontText);
  
  ctrlCentroid = new MunsellColor(0, 0, 10);
  chords = new Chord[numChords];
  assert chords.length < 10 : "Max number of Chords is hard-coded up to 10.";
  for (int i = 0; i < chords.length; i++) {
    chords[i] = new Chord();
  }
  paintings = new ArrayList<Painting>();
  colors = new ArrayList<MunsellColor>();
  undoPaintings = new Stack<Painting>();
  
  // draw all static graphic assets here and
  // let draw() take care of all dynamic contents
  drawButtons();  // buttons
  drawMunsellValueChroma(colorTable.rgbToMunsell(colorSelected), vcX, vcY, vcWidth, vcHeight);  // value-chroma spectrum
  drawMunsellHueCircle(hX, hY, hRadius, null);  // hue circle
  drawSelectedColor();  // current color selected
  drawColorPalette();  // color palette
}

// Process the mouse event (commands)
void doAction(int area)
{
  drawTextBox("", msgX, msgY, msgWidth, msgHeight);  // erase the previous status msg
  
  // Any button to use image area will pause painting
  if (area == areaLoad    || area == areaBuildC  || 
      area == areaBuildS  || area == areaBuildSC ||
      area == areaOpen    || area == areaSave    ||
      area == areaSaveImg || area == areaSavePlt ||
      area == areaStore   || area == areaRestore ||
      area == areaTheme)
  {
    bPause = true;
  }
  
  switch (area) {
    case areaLoad:  // Load an image file
      if (mouseButton == LEFT) {
        // Get the input image file name from dialog
        pathName = null;
        selectInput("Select an image to load:", "pathNameSelected", new File("./"));
        while (pathName == null) delay(200); // Wait until a Input dialog is done
        if (pathName.equals(""))  // Dialog is cancelled - do nothing
          break;
          
        // Load the input image and copy/scale it to the work space
        cursor(WAIT);
        imgInput = loadImage(pathName);
        
        // Scale image to the screen area for workspace, while
        // keeping original image unchanged for building patches without loss
        imgWork = imgInput.copy();
        if (imgWork.width > imgWidthMax)
          imgWork.resize(imgWidthMax, 0);
        if (imgWork.height > imgHeightMax)
          imgWork.resize(0, imgHeightMax);
        cursor(ARROW);
        drawImage();
        
        // Reset everything built upon previous image
        painter = null;
        paintings.clear();
        currPaintingIdx = -1;
        resetUndoPainting();
        storedPainting = null;
        currPatchIdx = -1;
        simplifyThreshold = 0;
      }
      break;
      
    case areaBuildC:  // Build the color patches
    case areaBuildS:
    case areaBuildSC:
      if (mouseButton == LEFT && imgInput != null && imgWork != null) {
        // Build color patches from original image to avoid any loss in contour pixels.
        cursor(WAIT);
        Painting p;
        if (area == areaBuildC)
          p = buildPatchesFromContour(imgInput, 0, colorSelected, imgWork);
        else if (area == areaBuildS)
          p = buildPatchesFromSolid(imgInput, 0, imgWork);
        else
          p = buildPatchesFromSolidContour(imgInput, colorSelected, imgWork);
        cursor(ARROW);
        imgInput = null;  // do not build it from again
       
        // Copy gray level and hue of the current painting to its master specification
        p.update(areaViewMGray, 'p', null, null);
        p.update(areaViewMHue, 'p', null, null);

        imgWork = createImage(imgWork.width, imgWork.height, RGB);  // start a fresh draw
        
        painter = null;
        paintings.clear();
        paintings.add(p);
        currPaintingIdx = 0;
        storedPainting = new Painting(p);  // set this one as stored as well
        currPatchIdx = -1;
        resetUndoPainting();
        viewMode = areaViewColors;
        drawTextBox("A painting with " + p.patches.size() + " color patches has been built.", msgX, msgY, msgWidth, msgHeight);
      }
      break;

    case areaOpen:  // Open a studio file
      if (mouseButton == LEFT) {
        // Get the studio file name from dialog
        pathName = null;
        selectInput("Select an ORStudio file to load:", "pathNameSelected", new File("./*.ors"));
        while (pathName == null) delay(200); // Wait until a Input dialog is done
        if (pathName.equals(""))  // Dialog is cancelled - do nothing
          break;
        cursor(WAIT);
        Painting p = deserializeStudio(pathName);
        cursor(ARROW);
        imgWork = createImage(p.imgWidth, p.imgHeight, RGB);  // start a fresh draw
        painter = null;
        paintings.clear();
        paintings.add(p);
        currPaintingIdx = 0;
        storedPainting = new Painting(p);  // set this one as stored as well
        currPatchIdx = -1;
        simplifyThreshold = 0;
        resetUndoPainting();
        viewMode = areaViewColors;
        String fileName = pathName.substring(pathName.lastIndexOf("\\") + 1);
        drawTextBox("The studio has been loaded from " + fileName, msgX, msgY, msgWidth, msgHeight);
      }
      break;
    case areaSave:  // Save the current studio into a file
      if (mouseButton == LEFT && currPaintingIdx >= 0) {
        // Get the studio file name from dialog
        pathName = null;
        selectOutput("Enter the ORStudio file name to save:", "pathNameSelected", new File("./*.ors"));
        while (pathName == null) delay(200); // Wait until a Input dialog is done
        if (pathName.equals(""))  // Dialog is cancelled - do nothing
          break;
        cursor(WAIT);
        serializeStudio(pathName);
        cursor(ARROW);
        String fileName = pathName.substring(pathName.lastIndexOf("\\") + 1);
        drawTextBox("The studio has been saved at " + fileName, msgX, msgY, msgWidth, msgHeight);
      }
      break;
      
    case areaSaveImg: // Save the current image at work as a PNG file
      if (mouseButton == LEFT && imgWork != null) {
        // Get the image file name from dialog
        pathName = null;
        selectOutput("Enter a file name to save the image:", "pathNameSelected", new File("./*.png"));
        while (pathName == null) delay(200); // Wait until a Input dialog is done
        if (pathName.equals(""))  // Dialog is cancelled - do nothing
          break;
        imgWork.save(pathName);
        String fileName = pathName.substring(pathName.lastIndexOf("\\") + 1);
        drawTextBox("The image has been saved at " + fileName, msgX, msgY, msgWidth, msgHeight);
      }
      break;

    case areaSavePlt: // Save the color palette of the current painting as a JPG file
      if (mouseButton == LEFT && currPaintingIdx >= 0) {
        // Get the image file name from dialog
        pathName = null;
        selectOutput("Enter a file name to save the palette of the painting:", "pathNameSelected", new File("./*.png"));
        while (pathName == null) delay(200); // Wait until a Input dialog is done
        if (pathName.equals(""))  // Dialog is cancelled - do nothing
          break;
        paintings.get(currPaintingIdx).savePalette(pathName);
        String fileName = pathName.substring(pathName.lastIndexOf("\\") + 1);
        drawTextBox("The palette has been saved at " + fileName, msgX, msgY, msgWidth, msgHeight);
      }
      break;

    case areaStore:  // Store the current painting for restore later
      if (mouseButton == LEFT && currPaintingIdx >= 0) {
        storedPainting = new Painting(paintings.get(currPaintingIdx));
        drawTextBox("The painting has been stored.", msgX, msgY, msgWidth, msgHeight);
      }
      break;
    case areaRestore: // Restore the patches to the last store or the original
      if (mouseButton == LEFT && currPaintingIdx >= 0 && storedPainting != null) {
        paintings.set(currPaintingIdx, new Painting(storedPainting));
        resetUndoPainting();
        viewMode = areaViewColors;
        drawTextBox("The painting is restored to the last store.", msgX, msgY, msgWidth, msgHeight);
      }
      break;

    case areaValueChroma:  // Select color at the value-chroma spectrum
    case areaHue:  // Select color at the hue circle.
    case areaSelectedColor:  // Select the selected color (highlight)
      if (mouseButton == LEFT) {
        // Synchronize the three areas with the selected color
        updateSelectedColor();
      }
      break;
      
    case areaPlot:  // Select a color by click or animate colors plot by dragging
      if (mouseButton == LEFT && currPaintingIdx >= 0) {
        if (prevMouseX < 0 || prevMouseY < 0)  {
          updateSelectedColor();
        }
        else {  // Adjust the rotation angle to the new mouse dragging.
          degreeRotateX += 180.0 * (mouseY - prevMouseY) / plotSize;
          degreeRotateZ += 180.0 * (mouseX - prevMouseX) / plotSize;
        }
      }
      if (mouseButton == RIGHT) {  // reset to original rotation
        degreeRotateX = 0;
        degreeRotateZ = 0;
      }
      break;

    case areaTheme:  // Show the color theme using the grid of colors in the chords
      if (mouseButton == LEFT) {
        viewMode = -1;
        drawTheme();
      }
      break;
    case areaPalette:  // Select or replace the color at the selected palette
      if (mouseButton == LEFT) {
        updateSelectedColor();
      }
      if (mouseButton == RIGHT) {
        // Replace the palette patch with the selected color
        updateColorPalette(mouseX - cpX);
        drawColorPalette();
      }
      break;
    case areaChord:  // Select or update the color at the selected chord.
      if (mouseButton == LEFT) {
        updateSelectedColor();
      }
      if (mouseButton == RIGHT) {
        // Replace the chord cell with the selected color
        updateChord(mouseX - chordX, mouseY - chordY);
      }
      break;
    case areaChordColor:  // Select the color from the selected chord
      if (mouseButton == LEFT) {
        updateSelectedColor();
      }
      break;
      
    case areaPaint:  // Paint collections from the current painting with current chords
      if (mouseButton == LEFT && currPaintingIdx >= 0) {
        // Current painting becomes the master for all new paintings in the collection
        Painting p = paintings.get(currPaintingIdx);
        painter = new Painter(p, chords, ctrlNumPaintings, ctrlCentroid, 
                              ctrlHueVariance, ctrlTensionScale, ctrlComplexity);
        paintings.clear();
        paintings.add(p);
        currPaintingIdx = 0;
        resetUndoPainting();
        painter.initialize();
        drawTextBox("Painting has started.", msgX, msgY, msgWidth, msgHeight);
        bPause = false;
      }
      break;
    case areaPause:  // Pause the painting
      if (mouseButton == LEFT && painter != null && !bPause) {
        bPause = true;
        drawTextBox("Painting paused.", msgX, msgY, msgWidth, msgHeight);
      }
      break;
    case areaResume:  // Resume the painting
      if (mouseButton == LEFT && painter != null && bPause) {
        bPause = false;
        drawTextBox("Painting resumed.", msgX, msgY, msgWidth, msgHeight);
      }
      break;
    case areaReset:  // Reset the painting process - destroy all but master
      if (mouseButton == LEFT && paintings.size() > 1) {
        Painting p = paintings.get(0);
        paintings.clear();
        paintings.add(p);
        currPaintingIdx = 0;
        resetUndoPainting();
        bPause = true;
        drawTextBox("Painting has been reset. All generated paintings have been destroyed", msgX, msgY, msgWidth, msgHeight);
      }
      break;
    case areaPrev:  // Show previous painting from the collection
    case areaNext:  // Show next painting from the collection
      if (mouseButton == LEFT && paintings.size() > 0) {
        currPaintingIdx += (area == areaNext) ? 1 : -1;
        if (currPaintingIdx < 0)
          currPaintingIdx = paintings.size() - 1;
        if (currPaintingIdx >= paintings.size())
          currPaintingIdx = 0;
      }
      break;
      
    case areaViewColors:  // Draw painted colors of the patches
    case areaViewTension:  // Draw tension map of the patches
    case areaViewMGray:  // Draw master gray
    case areaViewMHue:  // Draw master hue
    case areaViewMTension:  // Draw master tension
    case areaViewMTransition:  // Draw master transition
      if (mouseButton == LEFT && currPaintingIdx >= 0) {
        viewMode = area;
        drawTextBox("", msgX, msgY, msgWidth, msgHeight);
      }
      break;
      
    case areaImage:  // View info or edit color of a patch
      int pi = -1;
      if (mouseButton == LEFT && imgWork != null) {
        updateSelectedColor();
        if (currPaintingIdx >= 0)
          pi = paintings.get(currPaintingIdx).findPatchIdx(mouseX - imgX, mouseY - imgY);
      }
      if (mouseButton == RIGHT && imgWork != null && currPaintingIdx >= 0) {
        pushUndoPainting();

        boolean bChanged = false;
        // change the patch according to the selected color or the current patch
        Painting cp = paintings.get(currPaintingIdx);
        pi = cp.findPatchIdx(mouseX - imgX, mouseY - imgY);
        if (pi >= 0) {
          ColorPatch p = cp.patches.get(pi);
          ColorPatch pp = (currPatchIdx >= 0) ? cp.patches.get(currPatchIdx) : null;
          MunsellColor mc = colorTable.rgbToMunsell(colorSelected);
          switch (viewMode) {
            case areaViewColors: 
              bChanged = p.setColor(mc);
              if (bChanged)
                cp.updateStatistics();
              break;
            case areaViewMGray: 
              bChanged = p.setMasterGray(mc); 
              break;
            case areaViewMHue: 
              bChanged = p.setMasterHue(mc); 
              break;
            case areaViewMTension: 
              if (pp != null) 
                bChanged = p.setMasterTension(pp.masterTension); 
              break;
            case areaViewMTransition: 
              if (pp != null) {
                // no drag or shift-drag: replace it
                // dragging: replace it only if the mouse is in black area
                if (!bDrag || bShift || get(mouseX, mouseY) == color(0))
                  bChanged = p.setMasterTransition(pp.masterTransition);
              }
              break;
            default: break;
          }
        }
        if (!bChanged)
          popUndoPainting();  // throw away the last push as nothing has changed
      }
      if (!bDrag && pi >= 0)
        currPatchIdx = pi;
      break;

    default:
      break;
  }
}

// Simplify the image with flood fill algorithm with the threshold.
// The flooding starts from the pixels with highest Munsell distance from
// the ambient color (i.e., the centroid).
void simplify(PImage imgSrc, int threshold) 
{
  color cVisited = color(128);  // use gray to mark visited while traversal
  color cDone = color(255);  // use white to mark done after an area is done
  PImage imgMark = createImage(imgSrc.width, imgSrc.height, RGB);  // to mark done or visited

  // Calculate the centroid color
  float rt = 0;
  float gt = 0;
  float bt = 0;
  for (int i = 0; i < imgSrc.width; i++) {
    for (int j = 0; j < imgSrc.height; j++) {
      color c = imgSrc.get(i, j);
      rt += red(c);
      gt += green(c);
      bt += blue(c);
    }
  }
  int nPixels = imgSrc.width * imgSrc.height;
  MunsellColor mcCentroid = colorTable.rgbToMunsell(color(rt / nPixels, gt / nPixels, bt / nPixels));
  
  // Sort pixels in the descenting order of the Munsell distance to the centroid.
  // Use PVector with x for pixel index, y for the Munsell distance.
  PVector[] orderedPixels = new PVector[nPixels];
  for (int i = 0; i < imgSrc.width; i++) {
    for (int j = 0; j < imgSrc.height; j++) {
      int idx = i * imgSrc.height + j;
      MunsellColor mc = colorTable.rgbToMunsell(imgSrc.get(i, j));
      orderedPixels[idx] = new PVector(idx, mcCentroid.getGap(mc));
    }
  }
  Arrays.sort(orderedPixels, Comparator.comparing((PVector p) -> -p.y));

  color s;  // alias to a pixel in imgSrc
  color m;  // alias to a pixel in imgMark
  for (PVector opv : orderedPixels) {

    // Obtain the pixel coord from the index (x in vector)
    int ox = (int)(opv.x / imgSrc.height);
    int oy = (int)(opv.x % imgSrc.height);
    
    m = imgMark.get(ox, oy);
    if (m == cDone)
      continue;  // done in previous patch

    s = imgSrc.get(ox, oy);
    
    // Identify a new area using floodfill algorithm.
    ArrayList<PVector> points = new ArrayList<PVector>();
    MunsellColor mcCenter = colorTable.rgbToMunsell(s);
    Stack<PVector> ps = new Stack<PVector>();
    ps.push(new PVector(ox, oy));      
    while (!ps.empty()) {
      PVector pv = ps.pop();
      int px = (int)pv.x;
      int py = (int)pv.y;
      
      m = imgMark.get(px, py);
      if (m == cVisited || m == cDone)
        continue;  // Already visited this pixel.

      s = imgSrc.get(px, py);
      if (colorTable.rgbToMunsell(s).getGap(mcCenter) >= threshold)
        continue;  // Outside boundary
        
      // Has reached a new pixel; update average color and mark it visited
      points.add(pv);
      imgMark.set(px, py, cVisited);

      // Explore neighbors
      if (px > 0)
          ps.push(new PVector(px - 1, py));
      if (px < imgSrc.width - 1)
          ps.push(new PVector(px + 1, py));
      if (py > 0)
          ps.push(new PVector(px, py - 1));
      if (py < imgSrc.height - 1)
          ps.push(new PVector(px, py + 1));     
    }
    // Done the area: mark done and paint them with the average color
    rt = 0;
    gt = 0;
    bt = 0;
    for (PVector p : points) {
      color c = imgSrc.get((int)p.x, (int)p.y);
      rt += red(c);
      gt += green(c);
      bt += blue(c);
    }
    color cAvg = color(rt / points.size(), gt / points.size(), bt / points.size());
    for (PVector p : points) {
      imgMark.set((int)p.x, (int)p.y, cDone);
      imgSrc.set((int)p.x, (int)p.y, cAvg);
    }
  }
}

// Keyboard event handlers
void keyPressed() 
{
  // No keyboard event handling when Textfield is active
  Textfield tf = (Textfield)cp5.getController("ctrlMTransition");
  if (tf != null && tf.isActive())
    return;
  
  bShift = (key == CODED && keyCode == SHIFT);

  if (currPaintingIdx < 0) {  // no painting is done yet; but image src is there
    cursor(WAIT);
    if (imgInput != null && imgWork != null) {
      // change the src input image directly
      if (key == 'f' || key == 'F') {  // flood fill the image by one step.
        simplifyThreshold += simplifyThresholdIncr;
        simplify(imgInput, simplifyThreshold);
      }
      else if (key == 'b' || key == 'B') {  // blur the image by one step.
        imgInput.resize(imgInput.width / 2, 0);
        imgInput.resize(imgInput.width * 2, 0);
      }
      else if (key == 'g' || key == 'G') {  // convert it to gray.
        imgInput.filter(GRAY);
      }
      else if (key >= '2' && key <= '9') {  // posterize - reduce color channel to the value of key 
        imgInput.filter(POSTERIZE, key - '0');
      }
      else if (key == 'r' || key == 'R') {  // replace a color by another.
        // last two colors in the color palette are used to replace colors
        color cFrom = colorPalette[colorPalette.length - 2];
        color cTo = colorPalette[colorPalette.length - 1];
        for (int x = 0; x < imgInput.width; x++) {
          for (int y = 0; y < imgInput.height; y++) {
            if (imgInput.get(x, y) == cFrom)
              imgInput.set(x, y, cTo);
          }
        }
     }
      
      // re-create imgWork and display
      imgWork = imgInput.copy();
      if (imgWork.width > imgWidthMax)
        imgWork.resize(imgWidthMax, 0);
      if (imgWork.height > imgHeightMax)
        imgWork.resize(0, imgHeightMax);
      drawImage();
    }
    cursor(ARROW);
    return;
  }

  if (key == 'o' || key == 'O')
    bShowContour = !bShowContour;
  else if (key == 'l' || key == 'L')
    bShowReferenceLine = !bShowReferenceLine;
  else if (key == 26) {  // ctrl-Z: undo the last edit of the painting if still at the same painting
    Painting up = popUndoPainting();
    if (up != null) {
      paintings.set(currPaintingIdx, up);
      drawTextBox("Update is undone.", msgX, msgY, msgWidth, msgHeight);
    }
    else
      drawTextBox("Nothing to undo.", msgX, msgY, msgWidth, msgHeight);
  }
  else if (key > 0 && key < 128) {  // pass it to the current painting to update
    pushUndoPainting();
    
    // last two colors in the color palette are used in master edit mode
    MunsellColor mc1 = colorTable.rgbToMunsell(colorPalette[colorPalette.length - 2]);
    MunsellColor mc2 = colorTable.rgbToMunsell(colorPalette[colorPalette.length - 1]);
    paintings.get(currPaintingIdx).update(viewMode, key, mc1, mc2);
    drawTextBox("", msgX, msgY, msgWidth, msgHeight);
  }
  else if (key == CODED && keyCode == LEFT) {
    mouseButton = LEFT;
    doAction(areaPrev);
  }
  else if (key == CODED && keyCode == RIGHT) {
    mouseButton = LEFT;
    doAction(areaNext);
  }
}

// Mouse event handlers - mouse pressed
void mousePressed() 
{
  doAction(getMouseArea());
}

// Mouse dragging
void mouseDragged()
{
  bDrag = true;
  doAction(getMouseArea());
  prevMouseX = mouseX;
  prevMouseY = mouseY;
}

// Mouse released from dragging or click
void mouseReleased()
{
  bDrag = false;
  prevMouseX = prevMouseY = -1;
}

// Obtain the area where mouse is pressed
int getMouseArea() 
{
  int area = -1;
  
  if (isMouseWithin(vcX, vcY, vcWidth, vcHeight))
    area = areaValueChroma;
  if (isMouseWithin(hX, hY, hRadius))
    area = areaHue;
  if (isMouseWithin(cX, cY, cWidth, cHeight))
    area = areaSelectedColor;  
  if (isMouseWithin(cpX, cpY, cpWidth, cpHeight))
    area = areaPalette;
  if (isMouseWithin(chordX, chordY, chordCellWidth * 2, (chordCellHeight + 10) * numChords))
    area = areaChord;
  if (isMouseWithin(chordColorX, chordColorY, chordColorWidth, (chordColorHeight + 10) * numChords))
    area = areaChordColor;
  if (isMouseWithin(plotX, plotY, plotSize, plotSize))
    area = areaPlot;
  if (imgWork != null && isMouseWithin(imgX, imgY, imgWork.width, imgWork.height))
    area = areaImage;

  return(area);
}

// See if the mouse is within a box
boolean isMouseWithin(int x, int y, int w, int h)
{
  return mouseX >= x && mouseX < x + w && mouseY >= y && mouseY < y + h;
}

// See if the mouse is within a circle
boolean isMouseWithin(int x, int y, int r)
{
  int xd = mouseX - x;
  int yd = mouseY - y;
  return sqrt(xd * xd + yd * yd) < r;
}

// Callback for file name dialog
void pathNameSelected(File selection) 
{
  pathName = (selection == null) ? "" : selection.getAbsolutePath();
}

// The default draw() - display the current state of everything that changes
void draw() 
{
  if (painter != null && !bPause) {
    int pIdx = painter.paintOne();
    String msg = "Painting No. " + (pIdx + 1) + " is done.";
    drawTextBox(msg, msgX, msgY, msgWidth, msgHeight);
    if (pIdx != 0)
      return;  // let it continue to paint until it loops back to the first one
    Painting p = paintings.get(0);
    paintings.clear();
    paintings.add(p);
    paintings.addAll(painter.paintings);
    currPaintingIdx = 1;
  }
  
  if (currPaintingIdx < 0) {
    // clear the plot area
    fill(colorBG); noStroke(); rect(plotX, plotY, plotSize + 40, plotSize + 40);
    // erase the current painting stats
    drawTextBox("", statX, statY, statWidth, statHeight);
  }
  else {
    Painting currPainting = paintings.get(currPaintingIdx);

    // Draw the current painting
    if (viewMode != -1) {
      currPainting.draw(imgWork, viewMode);
      drawImage();
    }
    
    // display the current painting stats
    String str = "Painting No. " + currPaintingIdx + "\n";
    str += currPainting.getStatString();
    drawTextBox(str, statX, statY, statWidth, statHeight);
    
    // Refresh color points plot
    currPainting.plotColors(plotX, plotY, plotSize, degreeRotateX, degreeRotateZ);
    drawTextBox("Rotation X: " + (int)degreeRotateX + ", Z: " + (int)degreeRotateZ,
                plotX, plotY+plotSize+5, plotSize, 30);
  }
  
  drawPatchInfo();  // the current patch info
  drawChords();  // color chords and colors
  drawControls();  // controls 

  delay(100);
}

// Update and display the selected color by the color at the mouse location
void updateSelectedColor()
{
  colorSelected = get(mouseX, mouseY);
  drawSelectedColor();
  MunsellColor mc = colorTable.rgbToMunsell(colorSelected);
  drawMunsellValueChroma(mc, vcX, vcY, vcWidth, vcHeight);
  drawMunsellHueCircle(hX, hY, hRadius, mc);
}

// Draw currently selected color
void drawSelectedColor() 
{
  noStroke();
  fill(colorSelected);
  rect(cX, cY, cWidth, cHeight);

  String str = colorTable.rgbToMunsell(colorSelected).getString() +
               "\n(" + (int)red(colorSelected) +
               "," + (int)green(colorSelected) +
               "," + (int)blue(colorSelected) + ")";

  drawTextBox(str, cX, cY + cHeight, cWidth, 60);
}

void drawPatchInfo()
{
  if (currPatchIdx < 0) {
    // erase the patch info
    drawTextBox("", infoX, infoY, infoWidth, infoHeight + 50);
    if (cp5.getController("ctrlMTension") != null) {
      cp5.getController("ctrlMTension").remove();
      cp5.getController("ctrlMTransition").remove();
    }
  }
  else if (currPaintingIdx >= 0) {
    ColorPatch p = paintings.get(currPaintingIdx).patches.get(currPatchIdx);
    
    // display the current patch info
    drawTextBox(p.getStatString(), infoX, infoY, infoWidth, infoHeight);
    if (cp5.getController("ctrlMTension") == null) {
      int x = infoX;
      int y = infoY + infoHeight;
      drawTextBox("M-Tension:", x, y, 100, 20);
      cp5.addSlider("ctrlMTension").setValue(p.masterTension).setRange(0,40)
        .setLabel("").setPosition(x + 100, y).setSize(infoWidth - 100, 20);
      y += 25;
      drawTextBox("M-Transit:", x, y, 100, 20);
      cp5.addTextfield("ctrlMTransition").setPosition(x + 100, y)
        .setSize(infoWidth - 100, 20).setFont(fontText).setAutoClear(false)
        .setLabel("").setValue(p.masterTransition);
    }
    else {
      cp5.getController("ctrlMTension").setValue(p.masterTension);
      Textfield tf = (Textfield)cp5.getController("ctrlMTransition");
      if (tf != null && !tf.isActive())
        tf.setValue(p.masterTransition);
    }
  }
}
// Callback for tension changes - NOTE that P5 Slider controll calls back at every setValue()
// even if it sets initial value by draw(). I have to avoid push paintings from this useless callbacks.
void ctrlMTension(float v) {
  if (currPaintingIdx >= 0 && currPatchIdx >= 0) {
    ColorPatch p = paintings.get(currPaintingIdx).patches.get(currPatchIdx);
    if (p.masterTension != v) {
      pushUndoPainting();
      p.setMasterTension(v);
    }
  }
}
// Callback for transition controls
public void ctrlMTransition(String str) {
  if (currPaintingIdx >= 0 && currPatchIdx >= 0) {
    pushUndoPainting();
    if (str.length() > 0 && str.charAt(str.length() - 1) == '!') {
      // Special case - '!' at the end indicates replace all matching transition to new one
      String strOld = paintings.get(currPaintingIdx).patches.get(currPatchIdx).masterTransition;
      String strNew = str.substring(0, str.length() - 1);
      paintings.get(currPaintingIdx).replaceMasterTransition(strOld, strNew);
    }
    else
      paintings.get(currPaintingIdx).patches.get(currPatchIdx).setMasterTransition(str);
  }
}

// Draw all buttons
void drawButtons()
{
  // Buttons for Master patches
  cp5.addButton("btnLoad").setLabel("LOAD").setValue(areaLoad)
     .setPosition(btnMasterX, btnMasterY + (btnHeight + 10) * 0).setSize(btnWidth, btnHeight);
  cp5.addButton("btnBuildC").setLabel("BUILD C").setValue(areaBuildC)
     .setPosition(btnMasterX, btnMasterY + (btnHeight + 10) * 1).setSize(btnWidth, btnHeight);
  cp5.addButton("btnBuildS").setLabel("BUILD S").setValue(areaBuildS)
     .setPosition(btnMasterX, btnMasterY + (btnHeight + 10) * 2).setSize(btnWidth, btnHeight);
  cp5.addButton("btnBuildSC").setLabel("BUILD SC").setValue(areaBuildSC)
     .setPosition(btnMasterX, btnMasterY + (btnHeight + 10) * 3).setSize(btnWidth, btnHeight);
  cp5.addButton("btnOpen").setLabel("OPEN").setValue(areaOpen)
     .setPosition(btnMasterX, btnMasterY + (btnHeight + 10) * 4).setSize(btnWidth, btnHeight);
  cp5.addButton("btnSave").setLabel("SAVE").setValue(areaSave)
     .setPosition(btnMasterX, btnMasterY + (btnHeight + 10) * 5).setSize(btnWidth, btnHeight);
  cp5.addButton("btnSaveImg").setLabel("SAVE IMG").setValue(areaSaveImg)
     .setPosition(btnMasterX, btnMasterY + (btnHeight + 10) * 6).setSize(btnWidth, btnHeight);
  cp5.addButton("btnSavePlt").setLabel("SAVE PLT").setValue(areaSavePlt)
     .setPosition(btnMasterX, btnMasterY + (btnHeight + 10) * 7).setSize(btnWidth, btnHeight);
  cp5.addButton("btnStore").setLabel("STORE").setValue(areaStore)
     .setPosition(btnMasterX, btnMasterY + (btnHeight + 10) * 8).setSize(btnWidth, btnHeight);
  cp5.addButton("btnRestore").setLabel("RESTORE").setValue(areaRestore)
     .setPosition(btnMasterX, btnMasterY + (btnHeight + 10) * 9).setSize(btnWidth, btnHeight);
  
  // Buttons for chords theme
  cp5.addButton("btnTheme").setLabel("THEME").setValue(areaTheme)
     .setPosition(btnMasterX, cpY).setSize(btnWidth, btnHeight);
     
  // Buttons for painting operations
  cp5.addButton("btnPaint").setLabel("PAINT").setValue(areaPaint)
     .setPosition(btnMasterX + (btnWidth + 10) * 0, ctrlY + 160).setSize(btnWidth, btnHeight);
  cp5.addButton("btnPause").setLabel("PAUSE").setValue(areaPause)
     .setPosition(btnMasterX + (btnWidth + 10) * 1, ctrlY + 160).setSize(btnWidth, btnHeight);
  cp5.addButton("btnResume").setLabel("RESUME").setValue(areaResume)
     .setPosition(btnMasterX + (btnWidth + 10) * 2, ctrlY + 160).setSize(btnWidth, btnHeight);
  cp5.addButton("btnReset").setLabel("RESET").setValue(areaReset)
     .setPosition(btnMasterX + (btnWidth + 10) * 3, ctrlY + 160).setSize(btnWidth, btnHeight);
  cp5.addButton("btnPrev").setLabel("PREV").setValue(areaPrev)
     .setPosition(btnMasterX + (btnWidth + 10) * 4, ctrlY + 160).setSize(btnWidth, btnHeight);
  cp5.addButton("btnNext").setLabel("NEXT").setValue(areaNext)
     .setPosition(btnMasterX + (btnWidth + 10) * 5, ctrlY + 160).setSize(btnWidth, btnHeight);

  // Buttons for View patches
  cp5.addButton("btnViewColors").setLabel("COLORS").setValue(areaViewColors)
     .setPosition(btnViewX + (btnWidth + 20) * 0, btnViewY).setSize(btnWidth, btnHeight);
  cp5.addButton("btnViewTension").setLabel("TENSION").setValue(areaViewTension)
     .setPosition(btnViewX + (btnWidth + 20) * 1, btnViewY).setSize(btnWidth, btnHeight);
  cp5.addButton("btnViewMGray").setLabel("M-GRAY").setValue(areaViewMGray)
     .setPosition(btnViewX + (btnWidth + 20) * 2, btnViewY).setSize(btnWidth, btnHeight);
  cp5.addButton("btnViewMHue").setLabel("M-HUE-C").setValue(areaViewMHue)
     .setPosition(btnViewX + (btnWidth + 20) * 3, btnViewY).setSize(btnWidth, btnHeight);
  cp5.addButton("btnViewMTension").setLabel("M-TENSION").setValue(areaViewMTension)
     .setPosition(btnViewX + (btnWidth + 20) * 4, btnViewY).setSize(btnWidth, btnHeight);
  cp5.addButton("btnViewMTransition").setLabel("M-TRANSIT").setValue(areaViewMTransition)
     .setPosition(btnViewX + (btnWidth + 20) * 5, btnViewY).setSize(btnWidth, btnHeight);
}

// Process button events
void btnLoad(int area) { doAction(area); }
void btnBuildC(int area) { doAction(area); }
void btnBuildS(int area) { doAction(area); }
void btnBuildSC(int area) { doAction(area); }
void btnOpen(int area) { doAction(area); }
void btnSave(int area) { doAction(area); }
void btnSaveImg(int area) { doAction(area); }
void btnSavePlt(int area) { doAction(area); }
void btnStore(int area) { doAction(area); }
void btnRestore(int area) { doAction(area); }
void btnTheme(int area) { doAction(area); }
void btnPaint(int area) { doAction(area); }
void btnPause(int area) { doAction(area); }
void btnResume(int area) { doAction(area); }
void btnReset(int area) { doAction(area); }
void btnPrev(int area) { doAction(area); }
void btnNext(int area) { doAction(area); }
void btnViewColors(int area) { doAction(area); }
void btnViewTension(int area) { doAction(area); }
void btnViewMGray(int area) { doAction(area); }
void btnViewMHue(int area) { doAction(area); }
void btnViewMTension(int area) { doAction(area); }
void btnViewMTransition(int area) { doAction(area); }

// Replace the color palette at x location with the colorSelected
void updateColorPalette(int x) 
{
  float cellW = cpWidth / colorPalette.length;
  int pi = min(colorPalette.length - 1, (int)(x / cellW));
  colorPalette[pi] = colorSelected;
}

// Draw the current color palette
void drawColorPalette() 
{
  int cellW = cpWidth / colorPalette.length;
  
  stroke(colorEdge);
  for (int i = 0; i < colorPalette.length; i++) {
    fill(colorPalette[i]);
    rect(cpX + i * cellW, cpY, cellW, cpHeight);
  }
}

// Update the Chord cell with the selected color
void updateChord(int x, int y)
{
  int chordIndex = y / (chordCellHeight + 10);
  int mci = x / chordCellWidth;
  MunsellColor mc = colorTable.rgbToMunsell(colorSelected);
  if (mci == 0)
    chords[chordIndex].mc1 = mc;
  else
    chords[chordIndex].mc2 = mc;

  // Generate new chord colors
  chords[chordIndex].generateColors();
}

void drawChords() 
{
  // Draw chords controls
  stroke(colorEdge);
  for (int i = 0; i < chords.length; i++) {
    int x = chordX;
    int y = chordY + (chordCellHeight + 10) * i;
    fill(colorTable.munsellToRGB(chords[i].mc1));
    rect(x, y, chordCellWidth, chordCellHeight);
    x += chordCellWidth;
    fill(colorTable.munsellToRGB(chords[i].mc2));
    rect(x, y, chordCellWidth, chordCellHeight);
    if (cp5.getController("varChord"+i) == null) {
      x += chordCellWidth + 20;
      cp5.addSlider("varChord"+i).setValue(4).setRange(0, 25)
            .setLabel("").setPosition(x, y).setSize(chordCellWidth * 2, chordCellHeight);
    }
    else {
      cp5.getController("varChord"+i).setValue(chords[i].variation);
    }
  }

  // Display the chord colors
  for (int i = 0; i < chords.length; i++) {
    float x = chordColorX;
    float y = chordColorY + (chordColorHeight + 10) * i;
  
    // Erase previous draw
    fill(colorBG); stroke(colorEdge);
    rect(x, y, chordColorWidth, chordColorHeight);
  
    ArrayList<MunsellColor> mcs = chords[i].colors;
    if (mcs != null && mcs.size() > 0) {
      float cellW = (float)chordColorWidth / mcs.size();
      for (MunsellColor mc : mcs) {
        fill(colorTable.munsellToRGB(mc)); noStroke();
        rect(x, y, cellW, chordColorHeight);
        x += cellW;
      }
    }
  }
}

// Chords sliders callback functions - 10 hard-coded max
void varChord0(int v) { chords[0].variation = v; chords[0].generateColors(); }
void varChord1(int v) { chords[1].variation = v; chords[1].generateColors(); }
void varChord2(int v) { chords[2].variation = v; chords[2].generateColors(); }
void varChord3(int v) { chords[3].variation = v; chords[3].generateColors(); }
void varChord4(int v) { chords[4].variation = v; chords[4].generateColors(); }
void varChord5(int v) { chords[5].variation = v; chords[5].generateColors(); }
void varChord6(int v) { chords[6].variation = v; chords[6].generateColors(); }
void varChord7(int v) { chords[7].variation = v; chords[7].generateColors(); }
void varChord8(int v) { chords[8].variation = v; chords[8].generateColors(); }
void varChord9(int v) { chords[9].variation = v; chords[9].generateColors(); }

// Display the colors as grid (color theme) in the image area
void drawTheme()
{
  // Obtain the paint-ready colors from the current chords specification.
  ArrayList<MunsellColor> colors = getColorsFromAllChords(chords);
  if (colors.size() < 1)
    return;
  
  int rows = 30;
  int cols = 30;
  int cellSize = 30;
  fill(colorBG); noStroke();
  rect(imgX, imgY, imgWidthMax, imgHeightMax);
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      MunsellColor mc = colors.get((int)random(colors.size()));
      fill(colorTable.munsellToRGB(mc));
      rect(imgX + c * cellSize, imgY + r * cellSize, cellSize, cellSize);
    }
  }
}

// Generate paint-ready colors from all chords
ArrayList<MunsellColor> getColorsFromAllChords(Chord[] chords)
{
   ArrayList<MunsellColor> colors = new ArrayList<MunsellColor>();
   
  // Collect all color chords into one big palette and use them to paint.
  for (int i = 0; i < chords.length; i++) {
    if (chords[i].colors != null) {
      colors.addAll(chords[i].colors);
    }
  }
  // Colors in chord has one instance for each hue-chroma. This will cause
  // lower chroma colors to be selected way more than higher chroma colors.
  // To avoid this, multiply colors in proportion to its chroma.
  for (int i = 0, m = colors.size(); i < m; i++) {
    for (int j = 1; j < colors.get(i).chroma / 2; j++)
      colors.add(colors.get(i));
  }
  // Populate with all possible gray-level for the colors
  for (int i = 0, m = colors.size(); i < m; i++) {
    for (int v = 2; v < 20; v += 2) {
      MunsellColor mc = new MunsellColor(colors.get(i));
      mc.value = v;
      if (colorTable.isMunsellKeyInMap(mc))
        colors.add(mc);
    }
  }
  
  return colors;
}

// Draw all controls
void drawControls() 
{
  if (cp5.getController("ctrlNumPaintings") == null) {
    // Create all controls
    int x = ctrlX;
    int y = ctrlY;
    int labelW = 110;
    int ctrlW = ctrlWidth - labelW;
    
    drawTextBox("Paintings", x, y, labelW, ctrlHeight);
    cp5.addSlider("ctrlNumPaintings").setValue(ctrlNumPaintings).setRange(1, 500)
          .setLabel("").setPosition(x + labelW, y).setSize(ctrlW, ctrlHeight);
      
    y += ctrlHeight + 10;
    drawTextBox("Centroid", x, y, labelW, ctrlHeight);
    color c = colorTable.munsellToRGB(ctrlCentroid);
    CColor cc = new CColor(c, c, c, c, c);
    cp5.addBang("ctrlCentroid").setColor(cc)
          .setLabel("").setPosition(x + labelW, y).setSize(ctrlW, ctrlHeight);
  
    y += ctrlHeight + 10;
    drawTextBox("Hue Var.", x, y, labelW, ctrlHeight);
    cp5.addSlider("ctrlHueVariance").setValue(ctrlHueVariance).setRange(1, 90)
          .setLabel("").setPosition(x + labelW, y).setSize(ctrlW, ctrlHeight);
      
    y += ctrlHeight + 10;
    drawTextBox("Tens. Scale.", x, y, labelW, ctrlHeight);
    cp5.addSlider("ctrlTensionScale").setValue(ctrlTensionScale).setRange(0.1, 2.0)
          .setLabel("").setPosition(x + labelW, y).setSize(ctrlW, ctrlHeight);
      
    y += ctrlHeight + 10;
    drawTextBox("Complexity", x, y, labelW, ctrlHeight);
    cp5.addRange("ctrlComplexity").setBroadcast(false).setLabel("")
               .setPosition(x + labelW, y).setSize(ctrlW, ctrlHeight).setHandleSize(10)
               .setRange(0, 6).setRangeValues(ctrlComplexity[0], ctrlComplexity[1]).setBroadcast(true);
  }
  else {
    // Update control values
    cp5.getController("ctrlNumPaintings").setValue(ctrlNumPaintings);
    color c = colorTable.munsellToRGB(ctrlCentroid);
    CColor cc = new CColor(c, c, c, c, c);
    cp5.getController("ctrlCentroid").setColor(cc);
    cp5.getController("ctrlHueVariance").setValue(ctrlHueVariance);
    cp5.getController("ctrlTensionScale").setValue(ctrlTensionScale);
    ((Range)cp5.getController("ctrlComplexity")).setRangeValues(ctrlComplexity[0], ctrlComplexity[1]);
  }
}

// Control sliders callback functions
void ctrlNumPaintings(int v) { ctrlNumPaintings = v; }
void ctrlCentroid() {
  if (mouseButton == LEFT) {
    updateSelectedColor();
  }
  if (mouseButton == RIGHT) {
    color c = colorSelected;
    ctrlCentroid = new MunsellColor(colorTable.rgbToMunsell(c));
    CColor cc = new CColor(c, c, c, c, c);
    cp5.getController("ctrlCentroid").setColor(cc);
  }
}
void ctrlHueVariance(int v) { ctrlHueVariance = v; }
void ctrlTensionScale(float v) { ctrlTensionScale = v; }
void ctrlComplexity(ControlEvent v) {
  ctrlComplexity[0] = (float)(v.getController().getArrayValue(0));
  ctrlComplexity[1] = (float)(v.getController().getArrayValue(1));
}

// Draw text box
void drawTextBox(String text, int x, int y, int w, int h)
{
  noStroke(); fill(colorBG);
  rect(x, y, w, h);

  textFont(fontText); textAlign(LEFT, CENTER); fill(colorText); 
  text(text, x, y + h / 2);
}

// Refresh the current working image
void drawImage() 
{
  // Draw the bounding box
  fill(colorBG); noStroke();
  rect(imgX, imgY, imgWidthMax, imgHeightMax);
  image(imgWork, imgX, imgY);
}

// Serialize (save) the studio to a file
// A studio consists of (1) the current painting that contains
// all master spec and the current painted colors, and
// (2) color chords and (3) the painting parameters
void serializeStudio(String path)
{
  try {
    FileOutputStream fos = new FileOutputStream(path);
    BufferedOutputStream bos = new BufferedOutputStream(fos);
    ObjectOutputStream oos = new ObjectOutputStream(bos);
    
    paintings.get(currPaintingIdx).Serialize(oos);
    for (Chord ch : chords) {
      ch.Serialize(oos);
    }
    oos.writeInt(ctrlNumPaintings);
    ctrlCentroid.Serialize(oos);
    oos.writeFloat(ctrlHueVariance);
    oos.writeFloat(ctrlTensionScale);
    oos.writeFloat(ctrlComplexity[0]);
    oos.writeFloat(ctrlComplexity[1]);
    
    oos.close();
    bos.close();
    fos.close();
  }  catch (IOException e) {e.printStackTrace(); }
}

// Deserialize (load) the studio from a file
Painting deserializeStudio(String path)
{
  Painting p = null;
  try {
    FileInputStream fis = new FileInputStream(path);
    BufferedInputStream bis = new BufferedInputStream(fis);
    ObjectInputStream ois = new ObjectInputStream(bis);

    p = new Painting(); p.Deserialize(ois);
    for (Chord ch : chords) {
      ch.Deserialize(ois);
      ch.generateColors();
    }
    ctrlNumPaintings = ois.readInt();
    ctrlCentroid.Deserialize(ois);
    ctrlHueVariance = ois.readFloat();
    ctrlTensionScale = ois.readFloat();
    ctrlComplexity[0] = ois.readFloat();
    ctrlComplexity[1] = ois.readFloat();

    ois.close();
    bis.close();
    fis.close();
  }  catch (ClassNotFoundException | IOException e) { e.printStackTrace(); }

  return p;
}

// Handling the undo stack: push, pop, reset
void pushUndoPainting() {
  if (currPaintingIdx != undoPaintingIdx) {
    undoPaintings.clear();
    undoPaintingIdx = currPaintingIdx;
  }
  if (undoPaintings.size() >= maxUndoPaintings)
    undoPaintings.remove(0);
    
  undoPaintings.push(new Painting(paintings.get(currPaintingIdx)));
}
Painting popUndoPainting() {
  Painting p = null;
  if (undoPaintingIdx == currPaintingIdx) {
    if (!undoPaintings.empty()) {
      p = undoPaintings.pop();
    }
  }
  return p;
}
void resetUndoPainting() {
  undoPaintings.clear();
  undoPaintingIdx = -1;
}

// Class for Chord control
public class Chord 
{
  public MunsellColor mc1;  // P1
  public MunsellColor mc2;  // P2. P1 moves toward P2, forming a line
  public float variation;  // color variation along with the movement
  public ArrayList<MunsellColor> colors;  // generated colors
  
  // Default constructor
  public Chord() 
  {
    mc1 = mc2 = munsellBlack;
    variation = 4;
    colors = null;
  }
  
  // Serialize to save
  public void Serialize(ObjectOutputStream oos) throws IOException
  {
    mc1.Serialize(oos);
    mc2.Serialize(oos);
    oos.writeFloat(variation);
  }
  
  // Deserialize to load
  public void Deserialize(ObjectInputStream ois) throws IOException, ClassNotFoundException
  {
    mc1 = new MunsellColor(); mc1.Deserialize(ois);
    mc2 = new MunsellColor(); mc2.Deserialize(ois);
    variation = ois.readFloat();
  }
  
  // Gnerate colors for the defined color chord. Each chord is defined as
  // one or two colors (i.e., two points, P1, P2 in the color sphere)
  // and a variation value. If only one color is specificed, I generate colors
  // from P1 within the range of variation; If two colors are specified,
  // I generate colors along the line from P1 to P2 within the range of variation.
  void generateColors()
  {
    // Find out the mode. 0:none, 1:point, 1:line
    int mode = 0;
    if (!mc1.isEqual(munsellBlack)) {
      mode++;
      if (!mc2.isEqual(munsellBlack)) {
        mode++;
      }
    }
    if (mode == 0)
      colors = null;
    else if (mode == 1)
      colors = generateColorsByPoint(mc1, variation);
    else if (mode == 2)
      colors = generateColorsByLine(mc1, mc2, variation);
  }
}
