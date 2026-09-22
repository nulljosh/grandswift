# Grand Swift

A first person GTA-style game set in Vancouver and Victoria, written as one SwiftUI + SceneKit file for macOS.

You start downtown at Granville and Georgia. A short tutorial walks you through moving, shooting, jacking a car, driving to a beacon and switching characters. After that you run car deliveries to Canada Place, BC Place, Science World and the BC Legislature for cash while the cops chase you.

## Controls
W A S D or arrows to move, mouse to look (click to lock, Esc to release), Space or click to shoot, E to get in or out of a car, Tab to switch between Joshua and Alexandre.

## Build
`./build.sh && open "Grand Swift.app"`

## QA
`GS_QA=1 ./grandswift` plays the game headless and checks the core loop, tutorial and missions. `GS_SNAP=/tmp/frame.png ./grandswift` saves a frame.

See roadmap.md for what's next, including Windows, Linux and Joshua Tree ports.
