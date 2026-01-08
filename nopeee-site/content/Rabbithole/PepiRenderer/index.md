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

A renderer developed in 16 weeks (on top of a hybrid ray tracing renderer, which took another 16 weeks) for the PEPI engine, which was then used to create Owlet, a small  RTS game.

![alt text](../pepirenderer/FinalLook.png)

### Ray-Traced Shadows

I made use of my hybrid ray tracing pipeline to trace shadow rays, allowing for soft shadows.

![alt text](../pepirenderer/Shadows.png)

![alt text](../pepirenderer/Shadows.gif)


### Bloom

I made use of compute shaders, doing one horizontal and one vertical pass, creating the bloom effect for colors with emissive values.

![alt text](../pepirenderer/Bloom.png)

### Blended Skeletal Animations

The renderer allows smoothly blending between multiple skeletal animations

![alt text](../pepirenderer/anims.gif)




### UI System Porting

The UI system was initially implemented in OpenGL(by another programmer in our team). I ported this complex system to DX12, keeping all its functionality intact.

![alt text](../pepirenderer/UI_ed.png)

### Mesh Instancing

The renderer makes use of instanced rendering, allowing to renderer all the identical meshes in one single draw call. Great for particle systems, but also great for RTS games that have a bunch of identical meshes.

![alt text](../pepirenderer/Particles.gif)

### Compatibility with Editor Tools

The renderer can be used to render in real time all the changes made by the editor, such as editing lights, modifying meshes and materials and the terrain editor.

![alt text](../pepirenderer/Lights.gif)

![alt text](../pepirenderer/terrain.gif)

### Indexed Materials

This allows instanced rendering while still being able to have different materials on instanced meshes.

![alt text](../pepirenderer/IndexedMats.gif)





### Mip-Mapping

Made use of compute shaders to generate mip maps for all the textures.



### Steam-Deck Support

For the first 8 weeks of the project, the engine could run on a steamdeck. We eventually abandoned it, as the project requirements did not ask for multiple platform support of the engine anymore.

![alt text](../pepirenderer/SteamDeck.gif)






