# FASM Raycaster ![build badge](https://github.com/xtactis/fasm-raycaster/actions/workflows/main.yml/badge.svg)

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
    - [x] Step 4: virtual rangefinder aka first raycasting [final commit](https://github.com/xtactis/fasm-raycaster/tree/45da090e15f5b679156e99487ceeb53362b9c51b)
    - [x] Step 5: field of view [final commit](https://github.com/xtactis/fasm-raycaster/tree/f290361c7305777e8259f5bfeef1460140b40541)
    - [x] Step 6: 3D! [final commit](https://github.com/xtactis/fasm-raycaster/tree/b29c2f203580277508a8a46be9dd272ea08fa4a4)
    - [x] Step 7: first animation [final commit](https://github.com/xtactis/fasm-raycaster/tree/f6431d549dd591ae7bbde88aa0dedff8ea2e9861)
    - [x] Step 8: fisheye distortion correction [final commit](https://github.com/xtactis/fasm-raycaster/tree/389a15ceca4ab376214f54668c3c1b5fdee72fe7)
- Part 2: texturing the walls
    - [x] Step 9: loading the textures [final commit](https://github.com/xtactis/fasm-raycaster/tree/354b5870d1a1cb1ed86baf654ccc5780c46b0370)
    - [x] Step 10: rudimentary use of textures [final commit](https://github.com/xtactis/fasm-raycaster/tree/9d5da2e4b9893de73773ec238c9f1c701c395b84)
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
