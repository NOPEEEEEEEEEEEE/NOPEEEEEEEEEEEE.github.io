---
title: "PEPI Engine Renderer "
summary: "DX12/DXR renderer built specifically for RTS games "
categories: ["Project"]
tags: ["project"]
#externalUrl: ""
#showSummary: true
date: 2024-09-04
draft: false
---

## PEPI Renderer


![alt text](../PepiRenderer/FinalLook.png)

### Ray-Traced Shadows

I made use of DXR to trace shadow rays, allowing for soft shadows.

![alt text](../PepiRenderer/Shadows.png)

![alt text](../PepiRenderer/Shadows.gif)


### Bloom

I made use of compute shaders to create the bloom effect for colors with emissive values.

![alt text](../PepiRenderer/Bloom.png)

### Blended Skeletal Animations

The renderer allows smoothly blending between multiple skeletal animations

![alt text](../PepiRenderer/anims.gif)




### UI System Porting

The UI system was initially implemented in OpenGL(by another programmer in our team). I ported this system to DX12, keeping all its functionality intact.

![alt text](../PepiRenderer/UI_ed.png)

### Mesh Instancing

The renderer makes use of instanced rendering, allowing to renderer all the identical meshes in one single draw call.

![alt text](../PepiRenderer/Particles.gif)

### Compatibility with Editor Tools

The renderer can be used to render in real time all the changes made by the editor, such as editing lights, modifying meshes and materials and the terrain editor.

![alt text](../PepiRenderer/Lights.gif)

![alt text](../PepiRenderer/terrain.gif)

### Indexed Materials

This allows instanced rendering while still being able to have different materials on identical meshes.

![alt text](../PepiRenderer/IndexedMats.gif)





### Mip-Mapping

Made use of compute shaders to generate mip maps for all the textures.

![alt text](../PepiRenderer/Mips.png)

![alt text](../PepiRenderer/NoMips.png)




### Steam-Deck Support

For the first 8 weeks of the project, the engine could be run on a steamdeck. We eventually abandoned it, as the project requirements did not ask for multiple platform support of the engine anymore.

![alt text](../PepiRenderer/SteamDeck.gif)






