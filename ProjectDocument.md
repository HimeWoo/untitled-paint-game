# The title of your game #

## Summary ##

**A paragraph-length pitch for your game.**

## Project Resources

[Web-playable version of your game.](https://jx24.itch.io/untitled-paint-game)
[Trailor](https://youtube.com)
[Press Kit](https://dopresskit.com/)
[Proposal](https://docs.google.com/document/d/19xoqTyzlg7cBafAxgOEeZynd305ouQaau-FxPLQ7cZo/edit?usp=sharing)

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

1. Tile effects - I wrote the logic for the [effects that colors have on players and game objects](https://github.com/HimeWoo/untitled-paint-game/blob/main/untitled-paint-game/scripts/paintable.gd). There are 6 different colors: Red, Blue, Yellow, Green, Orange, and Purple. The tiles have 7 different custom data layer properties that outline what effect they give, and those properties determine their use cases. Also worked with Sandeep on hazard logic, specifically for [spikes](https://github.com/HimeWoo/untitled-paint-game/blob/3b529450887376ad92005a401f9b101cc918af89/untitled-paint-game/scripts/player.gd#L744C1-L757) and player interactions. Originally, [spikes and the spike logic were created as a separate scene](https://github.com/HimeWoo/untitled-paint-game/blob/3b529450887376ad92005a401f9b101cc918af89/untitled-paint-game/scripts/player.gd#L698-L724), which made it difficult to level design. I migrated spike logic to be based on tiles, which included migrating hazard logic to take effect on specific tiles via another custom data layer. This eases the processes of level designing.
2. Player movement - I wrote the core logic for the player movement. The player has a [directional melee attack](https://github.com/HimeWoo/untitled-paint-game/blob/3b529450887376ad92005a401f9b101cc918af89/untitled-paint-game/scripts/player.gd#L686-L692) and a dash. Took movement inpsiration from hollow knight, with a little bit of added momentum to specific movements like the dash to keep player feel in line with puzzle design.
3. Melee attacks + player/tile interactions - The player has access to paint the world via an inventory and canvas/selected paints. With their melee attack, they can [apply different paints onto specific paintable tiles](https://github.com/HimeWoo/untitled-paint-game/blob/main/untitled-paint-game/scripts/melee_attack.gd) to give themselves various effects and change the environment around them. the _physics_process [checks which tile the player is currently standing on](https://github.com/HimeWoo/untitled-paint-game/blob/3b529450887376ad92005a401f9b101cc918af89/untitled-paint-game/scripts/paintable.gd#L33-L42) and applies the effect accordingly
4. [Pushboxes](https://github.com/HimeWoo/untitled-paint-game/blob/main/untitled-paint-game/scripts/pushbox.gd), [pressure plates](https://github.com/HimeWoo/untitled-paint-game/blob/main/untitled-paint-game/scripts/pressure_pad.gd), and [doors](https://github.com/HimeWoo/untitled-paint-game/blob/main/untitled-paint-game/scripts/door.gd) - players can interact with moveable pushbox objects that can be used to reach greater heights and open doors. Pressure plates are only used to open doors, and each pressure plate references a door via an exported `linked_door` variable that's easily accessible via the godot editor.
## Sub-Roles ##
1. Animations - I implemented a bunch of the assets created by jason for QOL improvements, specifically animations for the [player](https://github.com/HimeWoo/untitled-paint-game/blob/3b529450887376ad92005a401f9b101cc918af89/untitled-paint-game/scenes/player.tscn#L237-L240) and enemies ([ground](https://github.com/HimeWoo/untitled-paint-game/blob/3b529450887376ad92005a401f9b101cc918af89/untitled-paint-game/scenes/GroundEnemy.tscn#L48-L51) and [floating](https://github.com/HimeWoo/untitled-paint-game/blob/3b529450887376ad92005a401f9b101cc918af89/untitled-paint-game/scenes/FloatingEnemy.tscn#L48-L51) enemies)
2. World and level designing - I worked alongside Long to build some of the rooms for the metroidvania feel that we were going for. I built and design 6 of the rooms using the components built by this goated team (like camera transitions and tiles).
![Atticus level design](untitled-paint-game/assets/Atticus-level-design.png)
## Other Contributions ##
# Sandeep
## Sub-Roles ##
## Other Contributions ##
# Jason Xie
## Sub-Roles ##
## Other Contributions ##
# Adrean Cajigas

## Main Roles: Game Logic | Combat, Enemies, Systems, and Player Experience ##

**Role:** Game Logic (primary)  
**Key files:** `player.gd`, `enemy.gd`, `enemy_stats.gd`, `EnemyProjectile.gd`, `PlayerProjectile.gd`, `MeleeAttack.gd`, `Paintable.gd`, `PlatformPaintable.gd`, `HealthBar.gd`, `ui_signals.gd`, input map + physics/collision layer settings, related scenes (Player.tscn, enemy scenes, projectile scenes, UI scenes)

---

### Overview

My main responsibility was to design and implement the core game logic: how the player and enemies move, attack, take damage, and interact with the world. I also owned the knockback system, collision/physics behavior, paint interactions on tiles and platforms, and the health/respawn flow. The goal was to build systems that are:

- **Predictable for players**: clear feedback when they attack, take damage, or dash through enemies
- **Scalable for designers**: new enemies and encounters can be created by tweaking data, not rewriting code
- **Robust for future content**: edge cases around dashes, hazards, and painting are handled at the system level

---

### 1. Player Combat System

#### Ranged Combat & Projectile System

**Files:** `player.gd`, `PlayerProjectile.gd`, `Player.tscn`

I implemented the full-range combat pipeline:

- Added an exported `projectile_scene` and a `ProjectileSpawn` marker in `Player.tscn`, then wrote spawn mirroring logic in `player.gd` so projectiles always spawn on the correct side based on `facing_dir`.

- Implemented `_get_aim_dir()` to support directional aiming (left/right/up/down) while still defaulting to facing direction when no aim keys are pressed.

- Wrote `_shoot_projectile()` to:
  - Instantiate the projectile scene.
  - Place it at the mirrored `ProjectileSpawn` position.
  - Initialize its direction and speed via `proj.setup(...)`.
  - Enforce a configurable cooldown (`shoot_cooldown`) and a slower cadence while invincible (`invincible_shoot_cooldown_mult`).

- In `PlayerProjectile.gd`, I handled:
  - Forward movement based on the initial direction.
  - Collision callbacks that damage enemies but ignore the player and world triggers that should not block projectiles.
  - Despawning behavior when hitting the world, an enemy, or leaving the intended play space.

This work formed the basis of the ranged combat loop and is used by all scenes where the player can shoot.

#### Melee Combat & Hitbox Logic

**Files:** `player.gd`, `MeleeAttack.gd`

I implemented a data-driven melee system:

- In `player.gd`, I added:
  - `attack_scene`, `attack_cooldown`, and `melee_knockback_force` as exported values so we can tune feel without touching code.
  - `perform_slash()` which:
    - Computes an attack direction from look inputs (up/down) or facing direction.
    - Chooses the appropriate animation (`slash_side`, `slash_up`, `slash_down`).
    - Spawns a `MeleeAttack` Area2D offset slightly from the player.
    - Wires it with `attack_dir`, the terrain TileMap (`terrain_map`), and the selected paint color.
    - Enforces attack cooldown and prevents attacking while invincible or already mid-attack.

- In `MeleeAttack.gd`, I handled:
  - Collision filtering via physics layers/masks so melee only interacts with enemies, paintable platforms, and the tilemap—not the player.
  - A `hit_objects` array so each enemy or platform is only hit once per swing.
  - Knockback computation based on `_attack_dir`, giving consistent horizontal push and optional vertical component.
  - Integration with the paint system:
    - Painting tiles inside the hitbox.
    - Painting `PlatformPaintable` areas and consuming paint from the player only when something was actually painted.

This system supports directional melee, knockback, and paint application in a single unified action.

---

### 2. Modular Enemy Architecture

#### EnemyStats Resource & Enemy Factory Behavior

**Files:** `enemy_stats.gd`, `enemy.gd`, enemy scenes

To avoid hard-coding enemy behavior, I moved all configurable parameters into `EnemyStats` resources:

- **Core stats:** `max_hp`, movement speeds (`patrol`, `chase`), starting patrol direction, grounded vs floating behavior.
- **Behavior toggles:** `enable_patrol`, `enable_chase`, `enable_bob`, `enable_shooting`, `enable_contact_damage`, `is_grounded`, etc.
- **Combat stats:** contact damage amount, contact knockback force, projectile speed, fire cooldown, homing strength, etc.

In `enemy.gd`, I then wrote a single AI script that reads those stats and behaves accordingly:

- **Patrol baseline:** if `enable_patrol`, the enemy walks horizontally using `patrol_dir`.
- **Chase override:** if `enable_chase` and the player is in `detection_area`, the enemy moves directly toward the player at `chase_speed`.
- **Vertical floating/bobbing:** if `enable_bob`, the enemy oscillates sinusoidally around `base_y`.
- **Shooting behavior:**
  - Uses `fire_timer` and `can_fire` to throttle ranged attacks.
  - Spawns `projectile_scene` and initializes direction/homing using `EnemyProjectile.gd`.
- **Grounded vs floating:** grounded enemies zero out vertical movement (`is_grounded`) so they don't drift, while floating enemies are allowed to bob and slide.

This gives us a "factory" model: new enemy types (turrets, floating shooters, walkers, hybrids) are created by making new `.tres` resources and scenes, not by duplicating logic.

**Example Enemy Configurations:**

- **FloatingEnemy** (`FloatingEnemy.tres`): 
  - Chases player at 110 speed
  - Shoots projectiles
  - Bobs vertically
  - No contact damage

- **GroundEnemy** (`GroundEnemy.tres`):
  - 40 HP, patrols at 40 speed, chases at 100 speed
  - Contact damage: 10 HP with 600 knockback force
  - Grounded (no vertical drift)
  - No shooting

- **TurretEnemy** (`TurretEnemy.tres`):
  - 30 HP, stationary (no patrol/chase)
  - Shoots homing projectiles every 3 seconds
  - No contact damage

#### Enemy Knockback & Health Handling

**Files:** `enemy.gd`, `enemy_stats.gd`

I rewrote the enemy damage handling to be consistent and extensible:

- **`apply_damage(amount, knockback)`:**
  - Early-outs if `is_dying` to avoid double-death bugs.
  - Reduces `hp`, updates the health bar, and plays the damage SFX.
  - Applies knockback forces that can be tuned per enemy (from melee or projectiles).

- **A dedicated `_update_health_bar()`:**
  - Sets `max_value` and clamps `value`.
  - Changes bar color from green → yellow → red based on HP ratio.

- **`_die()`:**
  - Marks `is_dying`, disables collision (main body and contact area), and plays the death SFX.
  - Waits for the sound (and optionally an animation) to finish before calling `queue_free()`.

This gives clean, predictable enemy destruction and makes it easy to bolt on more behavior (loot, animations, effects) later.

---

### 3. Player-Enemy Interaction & Damage Rules

**Files:** `player.gd`, `enemy.gd`, `EnemyProjectile.gd`, `PlayerProjectile.gd`

I focused heavily on avoiding "cheap" hits and making damage rules consistent:

- **Contact damage:**
  - In `enemy.gd`, `_on_contact_body_entered` only damages bodies in the player group and uses a direction-based knockback.
  - In `player.gd`, `apply_contact_damage()` ignores contact while:
    - The player is dashing (`is_dashing`).
    - The post-dash grace timer (`post_dash_contact_timer`) is active.

- **Invincibility frames:**
  - `apply_damage()` early-outs while `is_invincible` is true.
  - Invincibility uses a timer and visual flashing (soft red color) with proper reset when the timer ends.

- **Hazard handling:**
  - `_check_hazard_contact_and_die()` uses both slide collisions and a radius overlap query to detect hazards/water/spikes.
  - Immediate death calls `_die()`, which then respawns or reloads appropriately.

- **Projectile collisions:**
  - **Player projectiles:**
    - Damage enemies but ignore the player, detection areas, and platforms that shouldn't eat shots.
  - **Enemy projectiles:**
    - Damage the player and despawn on world or player collision.
    - Despawn on world collision prevents infinite projectiles and improves performance.

These rules make combat feel fair: the player understands why they were hit and has clear tools (dash, invincibility, spacing) to avoid damage.

---

### 4. Knockback System Rewrite

**Files:** `player.gd`, `enemy.gd`, `MeleeAttack.gd`, projectile scripts

To get satisfying combat feedback, I rewrote knockback logic:

- Introduced exported knockback strengths (`melee_knockback_force`, `stats.contact_knockback_force`, projectile knockback) so each interaction can be tuned independently.

- **Melee:**
  - Computes knockback relative to `_attack_dir` (left/right/up/down).
  - Supports horizontal-only knockback by zeroing vertical components when desired.

- **Player damage:**
  - `apply_damage()` modifies `horizontal_momentum` and `velocity.y` to push the player away from the source of damage.

- **Enemy damage:**
  - `apply_damage()` receives knockback vectors from melee and projectiles and applies them to the enemy's velocity.
  - Knockback velocity decays over time using `knockback_decel` to prevent enemies from sliding forever.

The result is a reusable knockback pipeline shared across all damage sources, with parameters that can be tuned without refactoring code.

---

### 5. Collision & Masking System

**Files:** physics layer/mask settings, `player.gd`, `enemy.gd`, projectile scenes, `MeleeAttack.gd`, world scenes

To prevent unintended interactions, I helped define and enforce a clear collision-layer strategy:

- Defined named physics layers for:
  - **Layer 1:** World
  - **Layer 2:** Player
  - **Layer 3:** Enemy
  - **Layer 4:** PlayerProjectile
  - **Layer 5:** EnemyProjectile
  - **Additional layers:** Hazards, Platform/pushbox/paintable elements

- Ensured each node has:
  - Appropriate collision layer (what it "is").
  - Appropriate collision mask (what it collides with).

- Adjusted scripts so that:
  - Player projectiles only collide with enemies/world.
  - Enemy projectiles only collide with the player/world.
  - Detection areas (`DetectionArea`, contact damage areas, melee areas) only monitor the relevant bodies.
  - Paintable platforms are detected by the player's terrain queries but don't interfere with regular movement collisions.

This reduced a large class of bugs (projectiles hitting the wrong things, melee hitting player, detection areas blocking movement) and made future additions safer.

---


## Sub-Roles: Game Sound Design | Event-Driven Audio System ##
**Role:** Game Sound Design (secondary)  
**Key files:** `player.gd`, `enemy.gd`, SFX nodes in `Player.tscn` and enemy scenes

Although my main focus was game logic, I also implemented the core sound design architecture and all gameplay-triggered SFX.

---

### 1. Player Sound Hooks

I added an `SFX` child node to the player, with dedicated `AudioStreamPlayer2D` children for:

- Walk (`SFX/Walk`)
- Jump (`SFX/Jump`)
- Land (`SFX/Land`)
- Dash (`SFX/Dash`)
- Shoot (`SFX/Shoot`)
- Melee (`SFX/Melee`)
- Damage (`SFX/Damage`)
- Death (`SFX/Death`)
- Paint Pickup (`SFX/Pickup`)

Then I wired sound playback to precise gameplay events in `player.gd`:

- **Jump** – plays only on a successful jump (not on button spam).
- **Land** – `_update_landing_sfx()` compares previous and current grounded state and only plays when transitioning air → floor, with a downward-velocity threshold.
- **Walk** – `_update_walk_sfx()` starts/stops a looping walk sound based on movement speed and grounded state.
- **Dash** – `start_dash()` plays `sfx_dash` when dash begins.
- **Melee** – `perform_slash()` plays `sfx_melee` when the slash is triggered.
- **Shoot** – `_shoot_projectile()` plays `sfx_shoot` when a projectile is spawned.
- **Damage** – `apply_damage()` plays `sfx_damage` exactly when HP is reduced.
- **Death** – `_die()` plays `sfx_death` and ensures respawn/scene reload respects the audio.
- **Paint Pickup** – centralized in `play_paint_pickup_sfx()` and hooked into paint pickup events so every inventory paint pickup feels responsive.

---

### 2. Enemy Sound Hooks

For enemies, I added:

- `SFX/Damage`
- `SFX/Death`

And connected them in `enemy.gd`:

- `apply_damage()` plays the damage sound whenever HP is reduced and the enemy is still alive.
- `_die()` plays the death sound, disables collisions, and waits for the sound to finish before removing the enemy from the scene. This allows future pairing with a death animation.

---

### 3. Sound Design Goals

The sound system is:

- **Event-driven** – sounds are triggered from logical game events (jump success, damage application, death, painting) rather than from arbitrary animation frames.
- **Modular** – adding new SFX is as simple as dropping an `AudioStreamPlayer2D` in the SFX container and calling `.play()` at the right event.
- **Consistent across entities** – both the player and enemies use similar patterns (damage/death hooks), making future expansion straightforward.

---

## Other Contributions ##

### Physics & Collision Improvements

**Files:** `player.gd`, input/collision settings, projectile scenes

Key improvements I made for smoother feel and fewer frustrating edge cases:

- **Dash Breathing Room:**
  - Added `post_dash_contact_grace` and `post_dash_contact_timer`.
  - After a dash ends, the player has a short window where contact damage is ignored to avoid "frame-perfect" hits.

- **Horizontal movement model:**
  - Implemented `horizontal_momentum` plus separate acceleration/deceleration rates for ground vs air.
  - Added a `dash_decel` override during dash wind-down.

- **Projectile despawn logic:**
  - Ensured both player and enemy projectiles despawn cleanly on world collision or after hitting a target.

Together, these changes make movement feel responsive while keeping the physics system stable.

---

### 5. Health Bar UI, HP Logic, and Respawn

**Files:** `player.gd`, `HealthBar.gd`, UI scene (Interface → TopLeft → HealthBar)

I implemented a responsive player health UI and ensured it integrates correctly with the respawn system:

- **Health model:**
  - `max_hp` and `current_hp` defined in `player.gd`.
  - `current_hp` initialized to `max_hp` in `_ready()` and reset to full on respawn.

- **HealthBar UI:**
  - Created a `HealthBar` container in the top-left UI with:
    - A `ProgressBar` configured to show a full bar instead of a percentage label.
    - Dynamic color changes based on HP ratio.
  - The health bar subscribes to HP update signals via `UISignals`.
  - Updates `value`, `max_value` whenever HP changes.
  - Changes bar color dynamically:
    - Green at high HP.
    - Yellow at mid HP.
    - Red at low HP.

- **Respawn flow:**
  - `_die()` handles either checkpoint restoration or scene reload.
  - `_restore_checkpoint()` resets motion state, clears dash/attack flags, restores inventory/paint, teleports the player, and brings HP back to `max_hp`, then emits UI signals so the health bar and inventory display stay in sync.

This gives a clear, readable health display that always matches the underlying game state.

---

### Input Mapping & Accessibility

**Files:** `player.gd`, project input settings

I reworked the input mapping to support multiple layouts and controllers:

- Defined separate actions for:
  - **Movement:** `move_left`, `move_right` (mapped to A/D and arrow keys).
  - **Aiming:** `aim_left`, `aim_right`, `aim_up`, `aim_down`.
  - **Looking:** `look_up`, `look_down`.
  - **Combat:** `shoot`, `melee_attack`.
  - **Utility:** `dash`, queue controls for paint selection, etc.

- In `player.gd`, I read from these actions instead of hard-coding keys, which:
  - Allows controller bindings.
  - Supports players who prefer arrow keys vs WASD.
  - Makes it straightforward to add/remap inputs via the project settings.

This work makes the game more accessible and easier to maintain.

---

Collectively, my Game Logic and Sound Design work transformed the project from a set of disconnected prototypes into a cohesive combat and interaction system:

- **Combat** (melee + ranged) is directional, responsive, and tied to knockback and paint mechanics.
- **Enemies** are defined by data (`EnemyStats`) and can scale to new types without script duplication.
- **Player–enemy interactions** obey clear rules about damage, invincibility, and dashing.
- **The world** (tiles + platforms) participates in gameplay via paint modifiers and teleports, with bugs around repainting and purple tiles resolved.
- **Sound feedback** is tightly integrated with every major interaction, greatly improving feel and readability.
- **Input mapping, collision layers, and UI health display** all work together so the game is playable, clear, and extensible.

Overall, this was a really fun project, and I'd love to continue working on this game!

---

# Alex Ogata
## Main Roles ##
User Interface and Input

* Player Inventory - I implemented the player's [inventory system](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scripts/inventory.gd). The player has a starting total of four inventory slots that can carry any primary color of paint. The inventory system allows for easy access to the underlying data structure, while sending signals which update the inventory's interface. 
* Paint Selector - I implemented the player's [paint selector](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scripts/paint_selector.gd). The paint selector allows the player to choose existing colors from their inventory and add them to a "palette". The player can select different slots on their palette to imbue their attacks with different colors. The player can [mix colors together](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scripts/paint_color.gd#L15) and confirm the mixture to remove the component colors from the player's inventory .
* Items - I added [paint items](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scripts/world_item.gd) that can be placed in the world for the player to pick up. There exist paint items in the colors [red](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scenes/items/red_paint.tscn), [blue](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scenes/items/blue_paint.tscn), and [yellow](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scenes/items/yellow_paint.tscn) which the player can come into contact with which will remove it from the world and add the corresponding color to the player's inventory (if there is sufficient space). The assets were drawn by me.
* Heads-up Display - I implemented the [heads-up display](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scenes/ui/interface.tscn) for our game. The interace updates according to the player's inventory to give the user a [visual counter](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scripts/ui/counter.gd) of the different paint the player has picked up, in addition to [a counter for how much inventory space is left](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scripts/ui/empty_slot_counter.gd). The interface includes a display of the aformentioned paint selector and which slot is highlighted. I included a small hint for some less intuitive keybinds in the top right.
* Controls - I added the methods for the [player's controls](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scripts/player.gd#L386) that involved the inventory or paint selector. The player uses the I, O, and P keys to add red, blue, or yellow paint, respectively, to the paint selector, given that it exists in the player's inventory. The player can clear the selected slot using the R key, refunding paint that the player has not confirmed to mix. The player can use the ENTER key to confirm to mix paint. The player can use the Q and E keys to navigate the paint selector.

## Sub-Roles ##
Level Design

* Room Transitions - I added [room transitions](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scripts/room_transition.gd) that change various camera settings when moving to a different room. They are highly customizable and allow for adjustment of the camera's position, zoom, position smoothing, enterable directions, and more.
* Rooms with player tracking camera - I added [rooms that make the camera track the player](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scripts/player_camera_room.gd). While the player is in one of these rooms, the camera will attempt to follow the player while staying within its defined region. It is highly customizable, similar to the room transitions, in addition to having lockable X and Y values for the camera.
* Camera Zoom Lerping - I added [lerp](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scripts/camera.gd) when changing the camera's zoom. This is primarily designed for use with the room transitions.
* Level Decoration - I decorated parts of the [main level](https://github.com/HimeWoo/untitled-paint-game/blob/0d1677e4e02a2768189f30b4da0ca6b2c4612f69/untitled-paint-game/scenes/World.tscn) with the tile variations supplied by Jason and by following the layout of the level designed by Long. 

## Other Contributions ##
* I created the assets that are used for the paint items and the paint icons in the player's inventory.
