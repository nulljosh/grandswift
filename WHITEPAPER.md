# Vancouver Vice Technical Whitepaper

**v1.25** | September 2026

Vancouver Vice is a crime game set in the real Vancouver that runs in a browser. It was built in one day by one person working with Claude. It shows that a playable open-city game no longer needs a studio: real map data, free models and a small amount of code get most of the way.

## The core idea
The city is real data, not hand-built art. OpenStreetMap gives every building footprint, height, street name, shop and SkyTrain station. A short Python exporter turns that into local metres, and the game extrudes it into a walkable city. A place tag inside a footprint tells the game what that building is, so walking into it opens a matching interior: a 7-Eleven you can rob, a bar, a hotel lobby.

## Collision without a physics engine
Footprints go into a 25 metre grid. Asking "is this spot solid" is one grid lookup and a point-in-polygon test. Walking, driving, traffic and cops all use that one question.

## Crime and heat
Crimes add heat. Stars are thresholds on heat. Heat only cools when no cop can see you, which is what makes escaping feel earned.

## Three versions
A simplified main game with the full gameplay, a real-streets city built from map data, and a photoreal beta streaming Google 3D tiles through Cesium. An Unreal Engine build is next, using the same map data and Cesium's Unreal plugin.

## Online
One Cloudflare Durable Object is the shared city. It relays positions between players, cleans bad input and stores nothing.

## Everywhere
The game is web code. Native shells host it on each platform: C# on Windows, C on Linux, SwiftUI on Mac and iOS, Java on Android.

## Limits
Hand-built GTA content (story, voice, animation, physics) is still the gap. The roadmap lists it honestly against GTA 3 through 6.

MIT license.
