# YUISHIKI

This is the code used for the following papers:

- [Believable fighting characters in role-playing games using the BDI model](https://cir.nii.ac.jp/crid/1573950402597012736) \[IPSJ 2015\]
- [AI platform for supporting believable combat in role-playing games](https://cir.nii.ac.jp/crid/1050574047113723520) \[IPSJ 2014\]

## Components

- The game engine (summon), implemented on top of LOVE2D.
- The AI engine (yuishiki).
- The game data (assets). Of note are:
  - The ruleset in `assets/rulesets/r0`, where game races, classes, items and actions are defined.
  - The characters in `assets/characters`, where traits and modules are defined.
  - The scenarios in `assets/scenarios`, where characters are placed in a map and given goals and beliefs.
