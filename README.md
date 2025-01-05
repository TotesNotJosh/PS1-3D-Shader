# PS1-3D-Shader
A Unity shader meant to emulate PSX effects.

The shader has options for transparency alpha clipping, vertex snapping, affine texture mapping, and fog using fixed-point math.

## Affine Texture Warp
![Affine Warp](https://github.com/user-attachments/assets/49291be8-9ffc-4f39-a734-43d00190ff15)
<br>The shader removes the depth correction for textures causing a warp, this can be mitigated by increasing the triangle count.

## Vertex Lighting
![Vertex Lit Int Fog](https://github.com/user-attachments/assets/defc9b0e-283a-4957-b263-04b5f2950802)
<br>Lighting snaps to vertices, this only works with point-lights with low importance, other types of lights do not have an effect on the lighting in a scene using this shader.

## Unlit
![Unlit Int Fog](https://github.com/user-attachments/assets/e8659ebc-f155-4a16-bb9a-0fb621f65950)
<br>Fog is set to int mode with 4 steps, starting at 5 units the fog is 0% climbing in steps until it is at 100% at 25 units. Polygons are culled inside of the fog.

## Vertex Snapping
![Vertex Snapping](https://github.com/user-attachments/assets/ecaf3f92-5cbc-4fee-a9c0-9611652cf374)
<br>Vertices snap to a grid set by adjusting the snapping resolution. This number is multiplied by 32 as it works with the fixed-point math inside of the shader. A value of 1 would break the screen evenly up into 32 x 32 points, a value of 8 would be 256 x 256 points.

## Image Processing Transparency
![half_redHD](https://github.com/user-attachments/assets/339995b5-3fec-4adf-80c4-6df29370d005) ![half_redSD](https://github.com/user-attachments/assets/372cefa5-84cc-4ac9-aa93-87cda2e3663c) ![half_redSD](https://github.com/user-attachments/assets/50d724ea-0383-48af-adae-f96873ccf3ea)
<br>The image processing script will scale an image down to 256 x 256 pixels, reduce the colour-depth to 32, set RGB values of (0, 0, 0) to (0, 0, 8) and then dither pure black based on the alpha channels of the images. This is inline with how the PSX worked with images, RGB (0,0,0) was the transparency colour and partial transparency was dealt with by dithering the colours creating a mesh of transparency.
<br> The image on the left is a solid red with an alpha of 128, the middle is what the converter converts it to, which is roughly 50% RGB(0, 0, 0) and 50%(255, 0, 0), the right is what it would look like with the RGB(0, 0, 0) clipped by the shader. This effect is more noticeable in GitHub's lightmode, if you are using darkmode(I am) zoom out you will see the first and third pictures look identical around 50% zoom.

# Installation
1. Create a new folder called Editor in your Assets folder.
2. Copy the PS1 Shader GUI.cs file into this folder.
3. Copy the .shader files anywhere in your asset folder hierarchy.
4. Select your materials you want to add the shader to and in the drop down select PS1 3D > Unlit or Vertex Lit

# License
Shield: [![CC BY 4.0][cc-by-shield]][cc-by]

This work is licensed under a
[Creative Commons Attribution 4.0 International License][cc-by].

[![CC BY 4.0][cc-by-image]][cc-by]

[cc-by]: http://creativecommons.org/licenses/by/4.0/
[cc-by-image]: https://i.creativecommons.org/l/by/4.0/88x31.png
[cc-by-shield]: https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg
