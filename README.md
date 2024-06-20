# ORStudio
<PRE>
// Ordered Random Studio (ORStudio) is a program that I developed for my 
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
// For now, the following example scenario to use, and the source code 
// (comments as well) should serve the purpose:
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
// - Select "M-TENSION" button and see the master specification for tension,
//   which is set from the loaded image by default. Blue indicates lowest tension
//   while red the highest. You can change M-Tension value at the slider bar of
//   the patch info display.
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
//   - "SAVE IMG" is to save the current viewing image into a PNG file.
//   - "STORE" is to store the current state of the current painting (master and painted colors).
//   - "RESTORE" is to restore the last stored painting.
//   - While viewing the master (M-GRAY, M-HUE, M-TENSION), the following key
//     can be used to edit the master specification:
//      - 'p' or 'P': master picks up the specs from the current painting;
//      - 'c' or 'C': master gets reset;
//      - '+' or '-': scale up or down the master specs (gray or tension only)
//      - '>' or '<': shift up or down the master specs (gray or tension only)
//      - 'r' or 'R': replace a hue using the last two colors in the color palette
//      - 'control-z': under the last change
//   - "THEME" is to quickly preview all colors in the set of color chords
//
// by Pyungchul Kim, 2024
// http://orderedrandom.com
//
</PRE>
