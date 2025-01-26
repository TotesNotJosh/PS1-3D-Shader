# PS1-3D-Shader
A Unity shader meant to emulate PSX effects.

The shader has options for transparency alpha clipping, vertex snapping, affine texture mapping, and fog using fixed-point math.

Note: This is a work in progress so updates will be frequent, but every commit will be usable. I am also using Unity 2022.3.12f1 3D (Built-In Render Pipeline).

## Affine Texture Warp
![Image](https://github.com/user-attachments/assets/c93ac010-edf2-494d-8d4b-11e9f0326dcb)

![Image](https://github.com/user-attachments/assets/1d5b59a5-ef0b-479d-b165-2cfd13c86f98)
<br>The shader removes the depth correction for textures causing a warp, this can be mitigated by increasing the triangle count.

## Lighting
![Image](https://github.com/user-attachments/assets/7f32914e-317f-4f66-9165-f1f86001b544)
![Image](https://github.com/user-attachments/assets/0b96f602-fa02-45ec-811a-c328103a7f0b)
![Image](https://github.com/user-attachments/assets/c83ec91a-408a-4e9f-8655-6059bd601e43)
<br>There are three types of lighting, Unlit, Gouraud, and Vertex. Gouraud is recommended for characters and Vertex is recommended for envrionment. Top to Bottom is Unlit, Gouraud, and Vertex.

## Vertex Snapping
![Image](https://github.com/user-attachments/assets/d0b6c4ed-f14e-4136-8a0e-4d36905cca48)
<br>Vertices snap to a grid. This grid is set by the vertex resolution * 32 so is splits up the world space into anywhere from 32³ to 256³ points for a given vertex to snap to. Setting this to 0 will disable vertex snapping.

## Dithering
![Image](https://github.com/user-attachments/assets/dbb55251-ed90-4a4e-8d53-dc59adc8c1da)
![Image](https://github.com/user-attachments/assets/bc577157-f4d7-4f92-be60-e6f02cf185e4)
<br>Dithering will dither the textures. The matrix for this was reverse engineered by analysing images from captures from original PSX hardware modded to remove dithering and comparing the differences between when that mod was on versus off. It isn't perfect but it is close.

## Fog
![Image](https://github.com/user-attachments/assets/72b20b7b-6180-4368-9125-919023f13cdb)
![Image](https://github.com/user-attachments/assets/d1d1891a-4fb8-478a-87ca-4b43717f35b4)
<br>Integer Fog Steps vs Fixed-Point Fog. Int fog creates steps of fog, at 1 there is a hard step of 100% fog at the fog end. 2 there is a step of 50% halfway between start and end. 3 there is a 33%, 66% and 100% and so on for each step. Beyond 4 steps it isn't very noticeable. Fixed-point is more like the actual PSX but int fog has its uses.

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
