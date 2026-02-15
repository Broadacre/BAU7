# BAU7

An Ultima VII game engine/viewer for iOS, written in Objective-C.

## Overview

BAU7 loads and renders Ultima VII game data including tile maps, shapes, sprites, and supports AI-controlled actors with A* pathfinding. It also includes procedural map generation for random worlds, islands, and dungeons.

## Project Structure

### App Infrastructure
- `main.m` - iOS app entry point
- `AppDelegate.h/m` - Application delegate
- `SceneDelegate.h/m` - Scene lifecycle management

### View Controllers
- **`BAMapViewController.m`** - Main map display controller with scrolling, gestures, height control, draw mode toggles
- `RandoMapViewController` - Controller for procedurally generated maps
- `U7ShapeViewController.h` - Shape/sprite browser and inspector
- `PalletViewController.h` - Palette viewer

### Map Views (UIView subclasses)
- **`BAMapView.h/m`** - Base map renderer with chunk drawing, spawn system, minimap generation
- `RandoMapView.h/m` - Procedural terrain with continent detection
- `IslandMapView.h/m` - Island-based procedural generation

### Core Data Model (`BAU7Objects.h/m`)
- **`U7Environment`** - Root container holding palettes, shapes, chunks, map, animations
- **`U7Map`** - Map grid of chunks, actor list, passability/pathfinding queries
- **`U7MapChunk`** - Individual chunk with static/game/ground items, sprites, passability bitmap
- `U7Chunk` - Raw tile chunk definition
- `U7Shape` - Shape data with frames, animation, collision properties
- `U7ShapeReference` - Shape instance in world (position, lift, frame)
- `U7Bitmap` - Pixel data with palette cycling
- `U7Palette` / `U7Color` - Color palette system
- `U7AnimationSequence` - Animation frame sequences
- `U7MapChunkCoordinate` - Coordinate conversion utility

### Sprite & Actor System
- **`BASprite.h`** - Base sprite class (location, movement, resource type)
- **`BAActor`** - Sprite subclass with inventory, AI manager, HP
- `BASpriteArray` - Collection with nearest-sprite queries
- `BASpawn` - Spawn configuration (frequency, triggers, types)

### AI & Action System
- **`BAActionManager.h`** - Action controller with A* pathfinding, target management
- `BAActionSequence` - Sequence of actions with looping
- `BASpriteAction.h` - Individual action definitions
- `BAAIManager.h` - AI decision-making manager
- `ShortestPathStep` - A* pathfinding node

### Utilities
- `Includes.h` - Master header importing all dependencies
- `Globals.h` - Global variables and settings
- `enums.h` - All enum definitions
- `BABitmap.h` - Bitmap utilities
- `BATable.h` - Data structure utilities
- `CGPointUtilities.h` - CGPoint helpers
- `CGRectUtilities.h` - CGRect helpers
- `BADirectionUtilities.h` - Cardinal direction utilities
- `BAU7BitmapInterpreter.h` - Bitmap interpretation
- `BAEnvironmentMap.h/m` - Environment type mapping per chunk
- `U7CharacterSprite.h` - Character sprite definitions

### Procedural Generation
- `BAProceduralGenerator.h` - Base procedural generation
- `BAIslandGenerator.h` - Island terrain generation
- `BARiverGenerator.h` - River generation
- `BARandomDungeonGenerator.h` - Dungeon generation v1
- `BARandomDungeonGeneratorDeux.h` - Dungeon generation v2

## Architecture

```
U7Environment
├── U7Palette
├── U7Shapes[]
├── U7Chunks[]
└── U7Map
    ├── U7MapChunk[] (192x192 grid)
    │   ├── staticItems[]
    │   ├── gameItems[]
    │   ├── groundObjects[]
    │   ├── sprites[]
    │   ├── passabilityBitMap
    │   └── environmentMap
    └── actors[] (BAActor)
        └── aiManager
            └── actionManager (A* pathfinding)
```

## Key Constants

```objc
#define TILESIZE 8          // Pixels per tile
#define CHUNKSIZE 16        // Tiles per chunk
#define SUPERCHUNKSIZE 16   // Chunks per superchunk
#define MAPSIZE 12          // Superchunks per map dimension
#define TOTALMAPSIZE 192    // Total chunks (16 * 12)

#define HEIGHTMAXIMUM 16    // Max height layers
#define CHUNKSTODRAW 10     // Visible chunks
#define REFRESHRATE 0.1     // Map refresh interval
#define PALLETCYCLERATE 0.25 // Palette animation rate
```

## Key Enums

```objc
// Map Types
enum BAMapType { BAMapTypeNormal, BAMapTypeRandom, BAMapTypeIsland };

// Draw Modes
enum BAMapDrawMode { NormalMapDrawMode, MiniMapDrawMode };

// Action Types
enum BAActionType { MoveActionType, ... };

// Cardinal Directions
enum BACardinalDirection { North, NorthEast, East, ... };

// Environment Types
enum BAEnvironmentType { NoBAEnvironmentType, ... };
```

## Features

- **Tile-based map rendering** with depth sorting
- **Chunk-based loading** (10x10 visible chunks)
- **Height layers** (0-16 levels)
- **Palette cycling** for animated water/lava
- **Zoom/scroll** via UIScrollView
- **Actor AI** with A* pathfinding
- **Gesture handling** (tap to move, long press to spawn)
- **Drawing toggles** (tiles, objects, passability, environment map)
- **Minimap generation**
- **Procedural generation** (random terrain, islands, dungeons)
- **Spawn system** with triggers and frequencies

## Usage

The app loads the U7 environment on launch (displays loading alert), then renders the map in a scrollable view. Use:
- **Sliders** to navigate X/Y position
- **Buttons** to adjust height layers
- **Tap** to move the main actor
- **Long press** to spawn actors
- **Toggles** to show/hide tiles, objects, passability, etc.

## Author

Dan Brooker - Created August 2021
