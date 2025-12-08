---
title: "My contribution on Galactic Goo "
summary: " "
categories: ["Project"]
tags: ["project"]
#externalUrl: ""
#showSummary: true
date: 2023-09-04
draft: false
---

## Galactic Goo

Many of my contributions to Galactic Goo directly impact the gameplay and the aesthetics of the game. Below is a brief description of my work.

![alt text](../GalacticGooWork/Purple.gif)

## Camera

The game was heavily inspired by Mercury Meltdown. We used it as an example for the camera and player movement. 

The example below showcases a comparison between Mercury Meltdown and our previous camera movement, which did not match the vision.

![alt text](../GalacticGooWork/Rotation_Problem.gif)

I eventually managed to replicate the correct camera rotation, by making the camera rotate around the camera arm axis and not around its own. 

![alt text](../GalacticGooWork/Camera.gif)

I implemented the movement by applying a gravitational force with the desired direction on the player actor, which is using a sphere for colision.

![alt text](../GalacticGooWork/Gravity.gif)


## Visual Effects

### Slime Simulation

Once the project theme was decided, I took the initiative to experiment with Niagara Fluids. 

![alt text](../GalacticGooWork/Slime_1.gif)

I have created multiple iterations, with different behaviours, making it easier to decide on the desired look.

![alt text](../GalacticGooWork/Slime_2_2.gif)




### Simulation customization

The game gives the player the option to change the smile color. I made sure that the simulation color is accessible and linked it to the UI. 

![alt text](../GalacticGooWork/Color_Selection.gif)
![alt text](../GalacticGooWork/ColourChange.gif)
 
### Menu Animations

As the project finish deadline was approaching, I took on some aesthetic taks, like animating the elements of the main menu, giving it more life.

![alt text](../GalacticGooWork/Menu.gif)



### Smoke

The final rocket animation needed some smoke, so I used Niagara do add that.

![alt text](../GalacticGooWork/Rocket.gif)


## Game Mechanics

The game has multiple mechanics that required some visual feedback. 

### Fans

Throughout the levels, fans can be found, which push the slime in one direction. I used a force module in Niagara to apply some light push to the particles in the required direction, making it much more visually satisfying. 

![alt text](../GalacticGooWork/Fans1.gif)

### Losing Mass

As the slime travels around, it leaves trails behind, leading to it losing its mass. This is visually conveyed by shrinking the size of the slime. Likewise, when the slime regains its mass, it regains its size as well. 

This is done by having a sphere spawner that continously creates new particles, while having a smaller sphere that kills the particles at the center. The rate at which those 2 perform the operations deteremines the size of the slime, and I had to carefully determine which ratios would produce the best results.

![alt text](../GalacticGooWork/MassLoss.gif)


### Splitting Mechanic

The splitting mechanic allows the player to leave smaller slime blobs behind, leading to some mass loss. Those smaller blobs have the particle spawn/kill ratios differently tweaked, ensuring that they are always visible, with a consistent behavior and a minimal performance impact.

![alt text](../GalacticGooWork/Splitting2.gif)





