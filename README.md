# Tou Dudes

> A recreation of [Bomberman 5](https://pt.wikipedia.org/wiki/Super_Bomberman_5) made with the
> [Godot](https://godotengine.org/) engine, for educational purposes.

## Features

- 2 players on the same machine, with fixed controls.
- Powerups: :bomb: Extra bomb, :fire: Intensity, :athletic_shoe: Kick bomb, :boxing_glove: Punch
  bomb, :gloves: Pick up bomb, :runner: Extra speed.
- 1 default character: Bomberman.
- 1 default map with simple obstacles.
- Random powerup spawn and initial obstacle configuration.
- Bombs bounce on other bombs when thrown.

## Download

Check out the latest [Windows release](https://github.com/MikeFP/tou-dudes/releases).

## Pending features

- Game title screen.
- Win condition and Victory UI.
- Fix: Speed powerups are only noticeable once 4 of them are stacked.

## How to play

### Player controls

**Player 1:** WASD for movement, F for "Bomb", H for "Punch bomb".

**Player 2:** Numberpad for movement, Comma for "Bomb", Semicolon for "Punch bomb". (Brazilian
Portuguese keyboard layout).

### New match

Currently, the only way to begin another match is by relaunching the game.

# For Devs

## Installing

The game was made in Godot 3.5. You can download it
[here](https://godotengine.org/download/3.x/windows/).

After cloning this repository, to edit the game, open Godot. In the Project Manager window,
import and open the cloned project folder.

## Testing

Initial game state can be mocked by enabling the `tester` node in the `map.tscn` scene, and
implementing the startup method in `tester.gd`. In it, you can access nodes to set them up,
which enables editing the game grid and adding initial powerups to the players.

Powerups can also be more easily tested by changing the `powerup_spawn_probability` in the root
`Map` node, combined with changing the probability rates in `powerup_data` in
`game-controller.gd`.
