# Cops: how the chase works

Stars come from what you do. Grabbing the Mac minis is one star. Hitting a car or a person adds one. Driving into a cop car adds two. Five is the ceiling.

Each star spawns more pursuit. One star is a single patrol car a block behind you. Three brings two cars and a roadblock on your street ahead. Five adds the helicopter spotlight.

Losing them is about line of sight. Break it and a search circle appears on the map around where they last saw you. Stay out of the circle for 20 seconds per star and the stars drain one at a time.

In Unreal this is one Blueprint, BP_Heat, living in the level. It holds the star count, listens for crimes, spawns pursuers from BP_VehicleAdvSportsCar with an AI driver that steers at the player every tick (no navmesh needed on Google's tiles), and runs the search timer. The HUD shows stars top right, next to the minimap.

## Build status

heat.dsl is drafted and not yet applied in Unreal. It covers the first slice: heat increases on crime, decays on line of sight, and displays on screen. Pursuit cars, roadblocks, and helicopter are next.
