# The title of your game #

## Summary ##

**A paragraph-length pitch for your game.**

## Project Resources

[Web-playable version of your game.](https://itch.io/)  
[Trailor](https://youtube.com)  
[Press Kit](https://dopresskit.com/)  
[Proposal: make your own copy of the linked doc.](https://docs.google.com/document/d/1qwWCpMwKJGOLQ-rRJt8G8zisCa2XHFhv6zSWars0eWM/edit?usp=sharing)  

## Gameplay Explanation ##

**In this section, explain how the game should be played. Treat this as a manual within a game. Explaining the button mappings and the most optimal gameplay strategy is encouraged.**


**Add it here if you did work that should be factored into your grade but does not fit easily into the proscribed roles! Please include links to resources and descriptions of game-related material that does not fit into roles here.**

# External Code, Ideas, and Structure #

If your project contains code that: 1) your team did not write, and 2) does not fit cleanly into a role, please document it in this section. Please include the author of the code, where to find the code, and note which scripts, folders, or other files that comprise the external contribution. Additionally, include the license for the external code that permits you to use it. You do not need to include the license for code provided by the instruction team.

If you used tutorials or other intellectual guidance to create aspects of your project, include reference to that information as well.

# Team Member Contributions

This section be repeated once for each team member. Each team member should provide their name and GitHub user information.

The general structures is 
```
Team Member 1
  Main Role
    Documentation for main role.
  Sub-Role
    Documentation for Sub-Role
  Other contribtions
    Documentation for contributions to the project outside of the main and sub roles.

Team Member 2
  Main Role
    Documentation for main role.
  Sub-Role
    Documentation for Sub-Role
  Other contribtions
    Documentation for contributions to the project outside of the main and sub roles.
...
```

For each team member, you shoudl work of your role and sub-role in terms of the content of the course. Please look at the role sections below for specific instructions for each role.

Below is a template for you to highlight items of your work. These provide the evidence needed for your work to be evaluated. Try to have at least four such descriptions. They will be assessed on the quality of the underlying system and how they are linked to course content. 

*Short Description* - Long description of your work item that includes how it is relevant to topics discussed in class. [link to evidence in your repository](https://github.com/dr-jam/ECS189L/edit/project-description/ProjectDocumentTemplate.md)

Here is an example:  
*Procedural Terrain* - The game's background consists of procedurally generated terrain produced with Perlin noise. The game can modify this terrain at run-time via a call to its script methods. The intent is to allow the player to modify the terrain. This system is based on the component design pattern and the procedural content generation portions of the course. [The PCG terrain generation script](https://github.com/dr-jam/CameraControlExercise/blob/513b927e87fc686fe627bf7d4ff6ff841cf34e9f/Obscura/Assets/Scripts/TerrainGenerator.cs#L6).

You should replay any **bold text** with your relevant information. Liberally use the template when necessary and appropriate.

Add addition contributions int he Other Contributions section.
# Long Phanguyen
## Sub-Roles ##
## Other Contributions ##
# Atticus Wong
## Main Roles ##
Game Logic/Player Logic

1. Tile effects - I wrote the logic for the effects that colors have on players and game objects. There are 6 different colors: Red, Blue, Yellow, Green, Orange, and Purple. The tiles have 7 different custom data layer properties that outline what effect they give, and those properties determine their use cases. Also worked with Sandeep on hazard logic, specifically for spikes. Originally, spikes were created as a separate scene, which made it difficult to level design. I migrated spike logic to be based on tiles, which included migrating hazard logic to take effect on specific tiles via another custom data layer. This eases the processes of level designing.
2. Player movement - I wrote the core logic for the player movement. The player has a directional melee attack and a dash. Took movement inpsiration from hollow knight, with a little bit of added momentum to specific movements like the dash to keep player feel in line with puzzle design.
3. Melee attacks + player/tile interactions - The player has access to paint the world via an inventory and canvas/selected paints. With their melee attack, they can apply different paints onto specific paintable tiles to give themselves various effects and change the environment around them. the _physics_process checks which tile the player is currently standing on. 
4. Pushboxes, pressure plates, and doors - players can interact with moveable pushbox objects that can be used to reach greater heights and open doors. Pressure plates are only used to open doors, and each pressure plate references a door via an exported `linked_door` variable that's easily accessible via the godot editor.
## Sub-Roles ##
Game Feel
1. animations
## Other Contributions ##
# Sandeep
## Sub-Roles ##
## Other Contributions ##
# Jason Xie
## Sub-Roles ##
## Other Contributions ##
# Adrean Cajigas
## Sub-Roles ##
## Other Contributions ##
# Alex Ogata
## Sub-Roles ##
## Other Contributions ##
