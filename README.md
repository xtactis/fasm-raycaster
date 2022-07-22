![build badge](https://github.com/xtactis/fasm-raycaster/actions/workflows/main.yml/badge.svg)

# FASM Raycaster

FASM implementation of https://github.com/ssloy/tinyraycaster/wiki

I've never done anything more than hello world in x86/x64 assembly so this will either never be completed, or will be a complete trashfire by the end. Or both! Hopefully just the latter tho!

## How to run

At the moment I'm only building this for Linux and making Linux specific system calls. I might go insane and try to make it crossplatform when I'm done, but don't expect much.

1. Download [FASM](https://flatassembler.net/download.php)
2. Unpack it somewhere where you can access fasm.x64
3. Run `fasm.x64 raycaster.asm`
4. Check that the `image_file.ppm` file contains something interesting
5. T-that's it.

## Progress

- Part 1: crude 3D renderings
    - [x] Step 1: save an image to disk [final commit](https://github.com/xtactis/fasm-raycaster/tree/039691fbebe27b36a592f270c19cd438ff648f71)
    - [x] Step 2: draw the map [final commit](https://github.com/xtactis/fasm-raycaster/tree/8f43284b93cefa530d9485f72e030cdc011bf0cb)
    - [x] Step 3: add the player [final commit](https://github.com/xtactis/fasm-raycaster/tree/e291d6025274e64118e1df05652631491d4cca70)
    - [ ] Step 4: virtual rangefinder aka first raycasting
    - [ ] Step 5: field of view
    - [ ] Step 6: 3D!
    - [ ] Step 7: first animation
    - [ ] Step 8: fisheye distortion correction
- Part 2: texturing the walls
    - [ ] Step 9: loading the textures
    - [ ] Step 10: rudimentary use of textures
    - [ ] Step 11: texturing the walls
    - [ ] Step 12: refactoring time!
- Part 3: populating the world
    - [ ] Step 13: draw monsters on the map
    - [ ] Step 14: black squares as a placeholder
    - [ ] Step 15: depth map
    - [ ] Step 16: one more problem with the sprites
    - [ ] Step 17: sort the sprites
- Part 4: SDL
    - [ ] Step 18: instead of SDL, I'll likely try to link againt opengl or sth more directly, I have no idea at the present moment how to work with graphics from FASM, so this will be interesing.
