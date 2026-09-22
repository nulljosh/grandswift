export const block = 260, road = 80;
export const vanMap = ["WWRWWWWWWWWWWWWW","WPRPWWWWWWWWWWWW","PPPPPWWWWCWWWWWW","PPPPBBBBBBHBGWWW","WPPBBBBBBBBBBBBW","WYBBBBBBABBBBBBB","WWYBBBBBBBBBBBBB","WWWWBBBBBBBSOBBB","WWWWWWBBBBBBBBBB","WWWWWRWIRWWWWWEW","BBYYBBBBBBBBBBBB","BBBBBBBBBBBBBBBB","WWWWWRWWWWWWWWWW","WWWWWRWWWWWWWWWW","WWWBBBBBWWWWWWWW","WWWBBLBBWWWWWWWW","WWWBBBBBWWWWWWWW","WWWWWWWWWWWWWWWW"];
export const cols = 16, rows = vanMap.length, W = cols * block, H = rows * block;
export const aves = ["Burrard Inlet","Coal Harbour","Canada Place Way","W Hastings","W Pender","W Georgia","Robson","Smithe","Pacific","False Creek","W 2nd","W 4th"];
export const streets = ["Chilco","Denman","Bidwell","Nicola","Bute","Thurlow","Burrard","Hornby","Granville","Seymour","Richards","Homer","Cambie","Beatty","Quebec","Main"];
export const NAMES = { C: "Canada Place", S: "BC Place", E: "Science World", L: "BC Legislature", H: "Harbour Centre", G: "Gastown Steam Clock", A: "Vancouver Art Gallery", O: "Rogers Arena", I: "Granville Island" };
export const HOODS = {
  dtes: { name: "Downtown Eastside", shirts: [0x5a5048, 0x3d3d3d, 0x6b5b4a, 0x4a4f3a], cart: .35, slow: .6, lines: ["Got a smoke?", "Shelter's full again tonight", "Stay safe out here, alright", "Housing first, that's all I'm saying", "Spare a toonie?", "I used to work the docks, you know"] },
  gastown: { name: "Gastown", shirts: [0xc0392b, 0xe0a526, 0x2a6fdb, 0xeeeeee], camera: .5, lines: ["Where's the steam clock?", "Is this where they film everything?", "Cobblestones, so charming", "Twelve dollar coffee, wow"] },
  westend: { name: "West End / Coal Harbour", shirts: [0x1f2a44, 0x111111, 0xdddddd, 0x5a1f2a], dog: .35, lines: ["My Tesla's double parked", "The condo went up again, love it", "Seawall run at six, then the yacht club", "Have you tried the new omakase?"] },
  yaletown: { name: "Yaletown", shirts: [0x222222, 0x6b7f8f, 0xeeeeee, 0x2e5e4e], lines: ["Brunch was forty bucks each, worth it", "Startup's pivoting again", "Did you see the Canucks game?"] },
  kits: { name: "Kitsilano", shirts: [0x8fb8a8, 0xe8d8c8, 0x1c1c1c, 0xd98b8b], dog: .25, lines: ["Namaste", "Just did the Grouse Grind", "Kits Beach later?", "Oat milk, obviously"] },
  victoria: { name: "Victoria", shirts: [0x7a6a8a, 0x8a9a7a, 0xc8b89a, 0x2a4a6a], lines: ["Tea at the Empress?", "Ferry was late again", "Lovely day for the harbour", "Are you from the mainland, dear?"] },
  downtown: { name: "Downtown", shirts: [0x8b5a2b, 0xc0392b, 0x2a6fdb, 0x222222, 0x2e9e4f, 0xe0a526], lines: [] },
};
export const kinds = [[40, 20, 420], [40, 20, 400], [80, 24, 260], [38, 18, 600]];
export const colors = [0xd33, 0xeec21b, 0xe67e22, 0x2e9e4f, 0xeeeeee, 0xe86aa6];
export const PERKS = {
  Joshua: { blurb: "Gastown hustler: +50% mission cash, cops lose interest twice as fast", cash: 1.5, cool: 2 },
  Ben: { blurb: "Kits athlete: runs 40% faster, jumps higher, drops people in two punches", run: 1.4, jump: 1.35, fists: 2 },
  Alexandre: { blurb: "Victoria fixer: steady aim (+50% range), faster cars, shrugs off 30% of damage", aim: 1.5, drive: 1.15, armor: .7 },
};
export const HERO_LOOK = { Joshua: 0xe8b21a, Ben: 0x2a5fb8, Alexandre: 0x1c1c1f };
export const STARS = [1, 20, 60, 140, 260];
export const WEAPONS = [{ name: "Fists" }, { name: "Pistol", dmg: 1, range: 600, rate: 250, max: 90 }, { name: "Shotgun", dmg: 3, range: 220, rate: 800, pellets: 3, max: 30 }, { name: "SMG", dmg: 1, range: 450, rate: 90, max: 240 }];
export const ACH = { first: "First Blood", thief: "Grand Theft Auto", five: "Five Star Menace", copkill: "Cop Killer", island: "Island Hopper", tourist: "Tourist: every landmark", courier: "Courier: 5 deliveries", taxi: "Night Shift: first fare", ghost: "Ghost: lost a 3 star chase", champ: "Level 5" };
export const MISSIONS = ["deliver", "taxi", "evade"];
export const STATIONS = [{ name: "Off" }, { name: "Kits Beach FM", bpm: 104, root: 55, beat: [1, 0, 0, 0, 1, 0, 0, 0], hat: true }, { name: "Hastings Hardcore", bpm: 150, root: 41, beat: [1, 0, 1, 0, 1, 0, 1, 1], hat: true }, { name: "CBC Rain Radio", bpm: 70, root: 48, beat: [1, 0, 0, 0, 0, 0, 0, 0], pad: true }];
export const WX = { 0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Fog", 51: "Drizzle", 53: "Drizzle", 55: "Drizzle", 61: "Rain", 63: "Rain", 65: "Heavy rain", 71: "Snow", 73: "Snow", 75: "Heavy snow", 80: "Showers", 81: "Showers", 82: "Downpour", 95: "Thunderstorm", 96: "Thunderstorm", 99: "Thunderstorm" };
export const LINES = ["Sorry!", "Canucks are gonna choke again, eh", "Rent's thirty-four hundred for a one bedroom, man", "You been to Granville Island? The market's sick", "It's gonna rain. It's always gonna rain", "Spare some change for the SkyTrain?", "Nice day for the seawall", "Have you seen my dog? Off leash at English Bay", "Go Whitecaps!", "Where's the nearest Tim's?", "Bro, the Expo line is down again", "You look like you could use a JapaDog", "Hey, you're Brian's kid, aren't you? Still owe him that hard drive", "Your mom's called me twice today looking for you, Joshua", "Sarah again? Smartest one in that family by a mile"];
export const BUMPS = ["Watch it, bud", "Hey! Eyes up", "Seriously?"];
export const FIGHTS = ["You got a problem?", "Wanna go?", "Say that again"];
export const STORY = [
  { title: "Joshua: Get Out of Here", kind: "evade", text: "You just burst out of the Apple Store on Georgia with a bag of Mac minis. Two guys in blue shirts are yelling behind you and one's already on the phone to the cops. Jack a car and lose them", pay: 300 },
  { title: "Joshua: Pawn the Mac minis", kind: "deliver", text: "Six Mac minis, no receipts, no questions you want asked. Get them down to the pawn shop on Granville before Dmitri finds out they were never yours to sell", pay: 400 },
  { title: "Joshua: Night Shift", kind: "taxi", text: "Cover a buddy's cab. Pick up the fare", pay: 350 },
  { title: "Alexandre: Island Business", kind: "hit", text: "Someone's been talking. Find the marked man and deal with him", pay: 500 },
  { title: "Joshua: Heat on Hastings", kind: "evade", text: "Get the cops' attention, three stars, then lose them", pay: 600 },
  { title: "Joshua: The Granville Job", kind: "deliver", text: "Last one. Bring a fast car to the beacon. Don't scratch it", pay: 1000 },
];
export const SKIN = [0xf1c9a5, 0xd9a680, 0xb67b53, 0x8d5a3b, 0x5c3a24];
export const HAIR = [0x1c140f, 0x3b2616, 0x6b4a2b, 0xb58a4c, 0x8f8f8f];
export const PANTS = [0x2b3440, 0x1f1f24, 0x4a3b2a, 0x3b4f6b, 0x5a5a5a];
export const HERO_BODY = { Joshua: "hero", Ben: "male_adult_05", Alexandre: "male_adult_09" };
