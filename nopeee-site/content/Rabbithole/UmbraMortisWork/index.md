---
title: "My contribution to Umbra Mortis"
summary: "Multiplayer zombie FPS made in UE5"
categories: ["Project"]
tags: ["project"]
#externalUrl: ""
#showSummary: true
date: 2025-07-06
draft: false
---


## Umbra Mortis

Throughout this project I learned a bunch of new things, such as developing multiplayer games adn using networking concepts, using the Scene View Extension to add custom shader passes, or using Niagara. 

### Visual Effects

Since our team lacked a VFX artist, I took upon this role, applying my shader experience to using Niagara. I would regularly receive feedback from the Visual Artists in our team, ensuring that the effects are cohesive with the rest of the game. 

#### Ammo Box 
![alt text](../UmbraMortisWork/AmmoBox.gif)

#### Bell Aura 
![alt text](../UmbraMortisWork/Bell.gif)

#### Disease Visualization

![alt text](../UmbraMortisWork/HealthDebuf.gif)

#### Key Pickup

![alt text](../UmbraMortisWork/KeyPickup.gif)

#### Bell AOE Visualization

![alt text](../UmbraMortisWork/Morale.gif)

#### Dissolving Effect

![alt text](../UmbraMortisWork/PlayerDissolve.gif)
![alt text](../UmbraMortisWork/DifColorsAfter.gif)

#### Canals Water

The water is reactive to the environment, creating waves around objects that have contact with it.


![alt text](../UmbraMortisWork/WaterWaves.gif)

![alt text](../UmbraMortisWork/WaterWaves2.gif)

#### THE STINKY FISH (my proudest achievement so far)

![alt text](../UmbraMortisWork/StinkyFish.gif)

### Gameplay

#### Lobby Practice Targets


![alt text](../UmbraMortisWork/Targets.gif)

#### Headshot Hitmarkers

Working on this lead to discovery that the shooting was not reliable and accurate for all the players in a session, which we eventually fixed.

![alt text](../UmbraMortisWork/HitMarkHeadshots.gif)

#### Teammate Outline Post Process

![alt text](../UmbraMortisWork/MatchingColors.gif)

#### Downed Post Process

![alt text](../UmbraMortisWork/DownedPost1.gif)


### Networking

The networking aspect of the game did make the development a little bit more difficult. Even for the visual elements of the game, some required replication of different parameters.



### Research 

In the early stages of the project, when the vision was not yet clear, I decided to experiment with the Scene View Extension class in Unreal Engine 5. This allows injecting custom shader passes at different stages of the rendering pipeline. This allowed me to create some effects that we did not end up using in the game, but are worth showing. 

I made use of a depth stencil buffer to create a ghosting effect and a scanning effect.

![alt text](../UmbraMortisWork/RKub.gif)

![alt text](../UmbraMortisWork/PingScan.gif)

The research I did with those has lead me to start working on this project: 

{{< article link="/projects/ue5colortools/" showSummary=true compactSummary=true >}}
