# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zuma-Deluxe-HD is a C-based remake of the 2003 PopCap game Zuma, featuring improved HD textures and 16:9 aspect ratio support. The project uses SDL2 for graphics, BASS audio library for sound, and libexpat for XML parsing.

## Build Commands

### Quick Build (Recommended)
```bash
./build_all.sh
```
This automated script handles all steps: dependency initialization, downloading BASS/BASSFX libraries, CMake configuration, compilation, and packaging.

### Manual Build Steps
```bash
# Initialize libexpat submodule
git submodule update --init --recursive

# Download BASS and BASSFX dependencies (optional - CMake auto-downloads)
./scripts/download_deps.sh

# Configure and build
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# Create portable package
make install

# Run the game
cd install
./run.sh
```

### Clean Build
```bash
rm -rf build/
```

### Development Build (Debug Mode)
```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j$(nproc)
```

## Project Architecture

### Core Engine System (`Engine.h`, `Engine.c`)

The `engine` global struct is the central hub managing all runtime systems:
- **Graphics**: SDL window, renderer, texture cache, custom font system
- **Audio**: BASS-based music and sound effects with volume control
- **Scaling**: Maintains aspect ratio scaling (`scale_x`, `scale_y`) for 16:9 support

Key subsystems:
- **Texture Management**: Centralized texture loading and caching via texture ID system
- **Font System**: Custom bitmap font renderer with kerning support (see `Font` struct)
- **Audio Layers**: `HMUSIC` for background music, `HSAMPLE` for one-shot sounds, `HSTREAM` for pitched/effects sounds

### Game State Flow

The main loop in `src/main.c` switches between two primary states:

1. **Menu State** (`MenuMgr`): Main menu, level selection, settings
2. **Game State** (`Game`): Active gameplay

Transition: When `menuMgr.roomID == MR_GAME`, initializes Game state with selected level and difficulty.

### Level System (`Level.h`, `Level.c`)

Levels are loaded from `content/levels/levels.xml` using Expat XML parser.

**Key Architecture:**
- **LevelGraphics**: Visual data (textures, paths, frog position, treasure points)
- **LevelSettings**: Gameplay parameters (ball speed, colors, scoring thresholds)
  - Each level can have 4 difficulty variants (same graphics, different settings)
- **Level**: Runtime instance combining graphics + settings reference
- **Spiral Paths**: Ball movement paths stored as `SpiralDot` arrays loaded from `.dat` files

**LevelMgr Global State:**
- `levelMgr.graphics[]`: Array of all level visual definitions
- `levelMgr.settings[]`: Array of all difficulty configurations
- `levelMgr.stages[]`: Organized level progression
- Progress tracking: `bestScore[][]` and `bestTime[][]` (2D arrays: [level][difficulty])

### Ball Chain Mechanics (`BallChain.h`, `BallChain.c`)

The ball chain is the core gameplay element - a dynamic array of balls moving along the spiral path.

**Critical Concepts:**
- **Position System**: Each ball has a `pos` field representing distance along the spiral path
- **Collision Detection**: `BallChain_CollidesFront()` and `_CollidesBack()` use distance thresholds (`BALLS_CHAIN_PAD`)
- **Insertion**: New balls are inserted with `isInserted` flag, smoothly merge into chain at `BALL_INSERTION_SPD`
- **Chain Reactions**: `BallChain_FindSubChain()` identifies matching color sequences for combo explosions
- **Physics**: Balls have acceleration, friction, and can move backwards when inserting causes compression

**State Flags:**
- `goBack`: Ball moving backwards during chain compression
- `isInserted`: Ball being inserted (not yet part of main chain physics)
- `isExploding`: Ball in destruction animation
- `inTunnel`: Ball hidden behind top layer (drawn with different priority)

### Game Loop (`Game.h`, `Game.c`)

The `Game` struct orchestrates all gameplay elements:

**Core Components:**
- `chain`: The BallChain instance
- `bullets`: Player-fired balls in flight
- `frog`: Player entity (position, rotation, next ball color)
- `particles`: Visual effects system
- `msgs`: On-screen score/combo messages

**State Machine:**
- `isFirstTime`: Intro sequence (level name display)
- `isIntroEnded`: Gameplay active
- `isLosed`/`isWon`: End game states
- `isOutroEnded`: Victory animation complete

**Treasure System:**
- Spawns when chain reaches `TREASURE_COLLIDE_DIST` progress
- `treasurePos`: Current coin position in level's `coinsPos[]` array
- Uses state flags: `treasureActive`, `treasureBlinking`, `treasureFading`

### Content Organization

```
content/
├── images/          # Textures loaded via TEXTURE_FOLDER
├── music/           # Background music via MUSIC_FOLDER
├── sounds/          # Sound effects via SOUND_FOLDER
├── fonts/           # Custom bitmap fonts via FONT_FOLDER
└── levels/
    ├── levels.xml   # Level definitions (graphics + settings)
    └── *.dat        # Spiral path data files
```

All asset loading paths are relative to the `content/` directory. The executable must have `content/` accessible via `LD_LIBRARY_PATH` or be run from the correct directory.

### Dependency Management

**libexpat (Git Submodule):**
- Located at `deps/libexpat/`
- Automatically compiled by CMake as part of build
- Used for parsing `levels.xml`

**BASS Audio Libraries (Auto-downloaded):**
- BASS: `deps/bass/libs/{arch}/libbass.so`
- BASS FX: `deps/bassfx/libs/{arch}/libbass_fx.so`
- Downloaded from un4seen.com by `scripts/download_deps.sh`
- CMake auto-detects architecture (x86_64, aarch64, armhf, x86)
- **License**: Free for non-commercial use

**SDL2 (System Libraries):**
- Must be installed via package manager
- Required: `libsdl2-dev`, `libsdl2-image-dev`, `libsdl2-ttf-dev`
- Detected via pkg-config

### Resource Constants (`Consts.h`)

This file contains static arrays defining all assets to load at startup:
- `filesTextures[]`: Texture file paths (size: `TEXTURES_COUNT`)
- `filesSounds[]`: Sound effect paths (size: `SOUNDS_COUNT`)
- `filesSoundsSfx[]`: Streaming sound paths (size: `SOUNDS_SFX_COUNT`)
- `filesFonts[]`: Font definition paths (size: `FONTS_COUNT`)
- `fileMusic`: Background music path

**Important**: When adding new assets, update both the array AND the corresponding `*_COUNT` define.

### Coordinate System

- **Window**: 1280x720 pixels (16:9)
- **Scaling**: `engine.scale_x` and `engine.scale_y` map game coordinates to actual window size
- **Spiral Paths**: Use normalized 0-1 coordinates, scaled during rendering
- **Frog Position**: Stored in `LevelGraphics.frogPos` as floating point screen coordinates

## Code Patterns

### Error Handling
Use `Engine_PushError*()` family of functions for all errors:
```c
Engine_PushErrorFile("levels.xml", "Parsing failed");
Engine_PushErrorCode("SDL_CreateWindow", SDL_GetError());
```

### Texture Access
```c
// Load: returns index for later use
int texID = Engine_TextureLoad("path/to/image.png");

// Draw at screen coordinates
Engine_DrawTexture(texID, x, y);
Engine_DrawTextureWithRot(texID, x, y, rotation);
```

### Sound Playback
```c
// One-shot sounds
Engine_PlaySound(SOUND_BALLCLICK1);

// Pitched sound effects (sfx)
Engine_PlaySoundSfxPitch(SFX_LIGHTNINGTRAIL, pitchValue);
```

### Memory Management
This codebase uses manual memory management:
- Always check `malloc`/`realloc` return values
- Free dynamically allocated members in cleanup functions (e.g., `Level_Free()`, `LevelMgr_Free()`)
- Ball chains and particle systems use fixed-size arrays to avoid dynamic allocation during gameplay

## File Organization

```
include/        # Header files (.h)
src/            # Implementation files (.c)
deps/           # Third-party dependencies
  libexpat/     # Git submodule
  bass/         # Auto-downloaded
  bassfx/       # Auto-downloaded
content/        # Game assets (must be present at runtime)
scripts/        # Build automation scripts
CMakeLists.txt  # CMake build configuration
```

### Major Components
- `Engine.*`: Core systems (graphics, audio, utilities)
- `Level.*`: Level loading and management
- `BallChain.*`: Ball physics and chain logic
- `Frog.*`: Player character
- `Bullet.*`: Projectile system
- `Game.*`: Main gameplay orchestration
- `MenuMgr.*`: Menu system
- `FX.*`: Particle effects and messages
- `Animation.*`: Sprite animation helper

## Platform Notes

- **Linux Only**: Build system targets Linux with architecture detection
- **Portable Packaging**: `make install` creates a self-contained directory with all dependencies in `lib/`
- **Run Script**: Always use `run.sh` to launch - it sets `LD_LIBRARY_PATH` correctly
- **Architecture Support**: x86_64, aarch64, armhf, x86 (auto-detected by CMake)

## Settings Persistence

- `Engine_SaveSettings()`: Writes audio volumes and fullscreen preference
- `Engine_LoadSettings()`: Loads user settings at startup
- `LevelMgr_SaveProgress()`: Saves best scores and times
- `LevelMgr_LoadProgress()`: Loads progress data
