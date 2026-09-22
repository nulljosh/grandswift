import SwiftUI
import AppKit

// ponytail: whole game in one file, top-down GTA 1 style. Split into files when it outgrows ~500 lines.
let block: CGFloat = 260, road: CGFloat = 80
// ponytail: hand-drawn Vancouver, one char per block. W water, P Stanley Park, R bridge deck, B city, letters = landmarks
let vanMap = [
    "WWRWWWWWWWWWWWWW",
    "WPRPWWWWWWWWWWWW",
    "PPPPPWWWWCWWWWWW",
    "PPPPBBBBBBHBGWWW",
    "WPPBBBBBBBBBBBBW",
    "WYBBBBBBABBBBBBB",
    "WWYBBBBBBBBBBBBB",
    "WWWWBBBBBBBSOBBB",
    "WWWWWWBBBBBBBBBB",
    "WWWWWRWIRWWWWWEW",
    "BBYYBBBBBBBBBBBB",
    "BBBBBBBBBBBBBBBB",
    "WWWWWRWWWWWWWWWW",
    "WWWWWRWWWWWWWWWW",
    "WWWBBBBBWWWWWWWW",
    "WWWBBLBBWWWWWWWW",
    "WWWBBBBBWWWWWWWW",
    "WWWWWWWWWWWWWWWW",
].map { Array($0) }
let cols = vanMap[0].count, rows = vanMap.count
let world = CGSize(width: block * CGFloat(cols), height: block * CGFloat(rows))
let landmarks: [Character: (String, Color)] = ["C": ("Canada Place", .white), "S": ("BC Place", Color(white: 0.85)), "E": ("Science World", Color(red: 0.8, green: 0.8, blue: 0.9)), "L": ("BC Legislature", Color(red: 0.8, green: 0.75, blue: 0.6))]
let aves = ["", "", "", "W Hastings", "W Pender", "W Georgia", "Robson", "Smithe", "Pacific", "False Creek", "W 2nd", "W 4th"]
let streets = ["Chilco", "Denman", "Bidwell", "Nicola", "Bute", "Thurlow", "Burrard", "Hornby", "Granville", "Seymour", "Richards", "Homer", "Cambie", "Beatty", "Quebec", "Main"]

func cell(_ p: CGPoint) -> Character? {
    let c = Int(p.x / block), r = Int(p.y / block)
    return p.x < 0 || p.y < 0 || c >= cols || r >= rows ? nil : vanMap[r][c]
}
func solid(_ p: CGPoint) -> Bool {
    guard let k = cell(p), k != "W" else { return true }
    if k == "P" || k == "R" || k == "Y" { return false }
    let x = p.x.truncatingRemainder(dividingBy: block), y = p.y.truncatingRemainder(dividingBy: block)
    return x > road && y > road
}
func streetName(_ p: CGPoint) -> String {
    let c = Int(p.x / block), r = Int(p.y / block)
    if cell(p) == "P" { return "Stanley Park" }
    if cell(p) == "R" { return r >= 12 ? "Ferry Causeway" : c == 5 ? "Burrard Bridge" : "Granville Bridge" }
    if r >= 14 { return ["Belleville St", "Government St", "Douglas St"][(r - 14) % 3] + ", Victoria" }
    let x = p.x.truncatingRemainder(dividingBy: block), y = p.y.truncatingRemainder(dividingBy: block)
    let ave = r < aves.count ? aves[r] : "", st = c < streets.count ? streets[c] : ""
    if x <= road && y <= road { return "\(st) & \(ave)" }
    return x <= road ? st : ave
}

struct Car { var p: CGPoint; var a: CGFloat = 0; var v: CGFloat = 0; var color: Color; var cop = false; var ai = false; var kind = 0; var hp = 3 }
// kinds: 0 sedan, 1 taxi, 2 bus, 3 sports. (length, width, top speed)
let kinds: [(CGFloat, CGFloat, CGFloat)] = [(40, 20, 420), (40, 20, 400), (80, 24, 260), (38, 18, 600)]
struct Ped { var p: CGPoint; var a: CGFloat; var t: CGFloat = 0 }
// sidewalk walker: snap across-axis to the road edge so peds walk down the street, not through it
func sidewalkPed(_ p: CGPoint) -> Ped {
    let vert = Bool.random(), a: CGFloat = vert ? (Bool.random() ? .pi / 2 : -.pi / 2) : (Bool.random() ? 0 : .pi)
    var q = p; let edge: CGFloat = Bool.random() ? 6 : road - 6
    if vert { q.x = floor(q.x / block) * block + edge } else { q.y = floor(q.y / block) * block + edge }
    return Ped(p: solid(q) ? p : q, a: a, t: .random(in: 0...6))
}

final class Game: ObservableObject {
    var keys = Set<UInt16>()
    var player = CGPoint(x: 8 * block + 40, y: 5 * block + 40), pa: CGFloat = 0
    var cars: [Car] = [], peds: [Ped] = []
    var mouseDX: CGFloat = 0, paused = false, z: CGFloat = 0, vz: CGFloat = 0
    var driving: Int? = nil
    var wanted = 0, score = 0, last = Date()

    init() {
        walkFrom = player
        let colors: [Color] = [.red, .yellow, .orange, .green, .white, .pink]
        for i in 0..<25 { cars.append(Car(p: roadPoint(), a: CGFloat(i % 4) * .pi / 2, color: i % 5 == 1 ? .yellow : colors[i % colors.count], ai: i % 3 != 0, kind: i % 7 == 0 ? 2 : i % 5 == 1 ? 1 : i % 6 == 0 ? 3 : 0)) }
        for _ in 0..<60 { peds.append(sidewalkPed(roadPoint())) }
    }
    func roadPoint() -> CGPoint {
        while true { let p = CGPoint(x: .random(in: 10...world.width - 10), y: .random(in: 10...world.height - 10)); if !solid(p) { return p } }
    }
    func down(_ k: UInt16) -> Bool { keys.contains(k) }

    func toggleCar() {
        if let i = driving { driving = nil; player = CGPoint(x: cars[i].p.x - sin(cars[i].a) * 30, y: cars[i].p.y + cos(cars[i].a) * 30); if solid(player) { player = cars[i].p }; return }
        // ponytail: jacking an AI car just takes it out of traffic
        if let i = cars.indices.filter({ !cars[$0].cop }).min(by: { dist(cars[$0].p, player) < dist(cars[$1].p, player) }), dist(cars[i].p, player) < 45 { driving = i; cars[i].ai = false; wanted = max(wanted, 1) }
    }

    func tick() {
        if paused { last = Date(); return }
        let now = Date(); let dt = CGFloat(min(now.timeIntervalSince(last), 0.05)); last = now
        let fwd = down(13) || down(126), back = down(1) || down(125), left = down(0) || down(123), right = down(2) || down(124)
        if let i = driving {
            var c = cars[i]
            c.v += (fwd ? 500 : 0) * dt - (back ? 400 : 0) * dt; c.v *= 0.98; c.v = max(-150, min(kinds[c.kind].2, c.v)); Sound.engine = Float(abs(c.v) / 600)
            c.a += ((right ? 1 : 0) - (left ? 1 : 0)) * 2.8 * dt * (c.v / 300)
            move(&c, dt); cars[i] = c; player = c.p
        } else {
            pa += ((right ? 1 : 0) - (left ? 1 : 0)) * 3 * dt + mouseDX * 0.004; mouseDX = 0
            let s: CGFloat = (fwd ? (down(56) ? 270 : 140) : 0) - (back ? 80 : 0)
            let n = CGPoint(x: player.x + cos(pa) * s * dt, y: player.y + sin(pa) * s * dt)
            if !solid(n) { player = n }
            if z > 0 || vz > 0 { vz -= 600 * dt; z = max(0, z + vz * dt); if z == 0 { vz = 0 } }
        }
        for i in peds.indices {
            let n = CGPoint(x: peds[i].p.x + cos(peds[i].a) * 30 * dt, y: peds[i].p.y + sin(peds[i].a) * 30 * dt)
            peds[i].t += dt * 8
            if solid(n) || n.x < 0 || n.y < 0 { let d = (0..<4).map { CGFloat($0) * .pi / 2 }.filter { !solid(CGPoint(x: peds[i].p.x + cos($0) * 8, y: peds[i].p.y + sin($0) * 8)) }; peds[i].a = d.randomElement() ?? peds[i].a + .pi } else { peds[i].p = n }
        }
        // ponytail: O(cars*peds) hit scan, fine at 25x60; grid-bucket it if counts grow
        // ambient traffic: cruise, turn to a free cardinal heading when blocked
        for i in cars.indices where cars[i].ai && i != driving {
            var c = cars[i]; c.v = 150
            let ahead = CGPoint(x: c.p.x + cos(c.a) * 45, y: c.p.y + sin(c.a) * 45)
            if solid(ahead) || cars.indices.contains(where: { $0 != i && dist(cars[$0].p, ahead) < 25 }) {
                let dirs = (0..<4).map { CGFloat($0) * .pi / 2 }.filter { !solid(CGPoint(x: c.p.x + cos($0) * 45, y: c.p.y + sin($0) * 45)) }
                c.a = dirs.randomElement() ?? c.a + .pi; c.v = 0
            }
            move(&c, dt); cars[i] = c
        }
        for (ci, c) in cars.enumerated() where ci == driving && abs(c.v) > 120 { peds.removeAll { p in let hit = dist(p.p, c.p) < 20; if hit { score += 10; wanted = min(5, wanted + 1) }; return hit } }
        if peds.count < 50 { peds.append(sidewalkPed(roadPoint())) }
        let copCount = cars.filter(\.cop).count
        if copCount < wanted { var p = roadPoint(); while dist(p, player) < 500 { p = roadPoint() }; cars.append(Car(p: p, color: .blue, cop: true)) }
        for i in cars.indices where cars[i].cop {
            var c = cars[i]
            let want = atan2(player.y - c.p.y, player.x - c.p.x)
            c.a += max(-3 * dt, min(3 * dt, atan2(sin(want - c.a), cos(want - c.a))))
            c.v = min(c.v + 300 * dt, 330); move(&c, dt); cars[i] = c
            if dist(c.p, player) < 30 && (driving == nil || abs(cars[driving!].v) < 60) { busted() ; return }
        }
        if wanted > 0 && .random(in: 0...1) < 0.0008 { wanted -= 1; if let j = cars.lastIndex(where: \.cop) { cars.remove(at: j) } }
        progress()
        Sound.siren = wanted > 0 && cars.contains { $0.cop && dist($0.p, player) < 900 }
        if driving == nil { Sound.engine = 0 }
        flash = max(0, flash - Double(dt)); if !msg.isEmpty && Int(now.timeIntervalSince1970 * 60) % 240 == 0 { msg = "" }
        objectWillChange.send()
    }
    func move(_ c: inout Car, _ dt: CGFloat) {
        let n = CGPoint(x: c.p.x + cos(c.a) * c.v * dt, y: c.p.y + sin(c.a) * c.v * dt)
        if solid(n) { if abs(c.v) > 200 { Sound.bang(0.5) }; c.v *= -0.3 } else { c.p = n }
    }
    var ammo = 60, flash = 0.0, msg = ""
    // two playable heroes, Tab swaps (GTA V style). Inactive one is frozen where you left them.
    struct Hero { var name: String; var p: CGPoint; var a: CGFloat = 0; var driving: Int?; var ammo = 60 }
    var heroes = [Hero(name: "Joshua", p: CGPoint(x: 8 * block + 40, y: 5 * block + 40), driving: nil), Hero(name: "Alexandre", p: CGPoint(x: 5 * block + 40, y: 15 * block + 40), driving: nil)]
    var cur = 0
    // tutorial steps, then endless delivery missions to landmarks
    let tut = ["Walk with W A S D", "Aim with the mouse, click to shoot", "Find a car and press E to get in", "Drive to the yellow beacon", "Press Tab to switch to Alexandre", "Tutorial done. Deliver cars to the beacon for cash"]
    var step = 0, walkFrom = CGPoint.zero
    var target = CGPoint(x: 9 * block + 170, y: 2 * block + 40)
    static let spots: [CGPoint] = vanMap.indices.flatMap { r in vanMap[r].indices.compactMap { c in "CSEL".contains(vanMap[r][c]) ? CGPoint(x: CGFloat(c) * block + 40, y: CGFloat(r) * block + 40) : nil } }
    func progress() {
        switch step {
        case 0: if dist(player, walkFrom) > 100 { step = 1 }
        case 1: if ammo < 60 { step = 2 }
        case 2: if driving != nil { step = 3 }
        case 3: if dist(player, target) < 120 { step = 4; score += 100; Sound.bang(0.3) }
        case 4: if cur == 1 { step = 5; newTarget() }
        default: if driving != nil && dist(player, target) < 120 { score += 250; msg = "Delivered! +$250"; Sound.bang(0.3); newTarget() }
        }
    }
    func newTarget() { target = (Game.spots.filter { dist($0, player) > 600 }.randomElement() ?? target) }
    func swapHero() {
        heroes[cur] = Hero(name: heroes[cur].name, p: player, a: pa, driving: driving, ammo: ammo)
        cur ^= 1; let h = heroes[cur]
        player = h.p; pa = h.a; ammo = h.ammo
        // ponytail: stored car index may have shifted if cars were destroyed meanwhile; drop it rather than track ids
        driving = h.driving.flatMap { $0 < cars.count && !cars[$0].cop ? $0 : nil }
        if let d = driving { cars[d].v = 0 }
        msg = "Now playing \(h.name)"; Sound.bang(0.2)
    }
    func shoot() {
        guard driving == nil, ammo > 0 else { return }
        ammo -= 1; flash = 0.08; Sound.bang(1)
        let d = CGPoint(x: cos(pa), y: sin(pa))
        // ponytail: hitscan, nearest target within 12u of the ray, no walls check beyond first 600u
        func along(_ p: CGPoint) -> CGFloat? { let v = CGPoint(x: p.x - player.x, y: p.y - player.y); let t = v.x * d.x + v.y * d.y; return t > 0 && t < 600 && abs(v.x * d.y - v.y * d.x) < 14 ? t : nil }
        let pi = peds.indices.compactMap { i in along(peds[i].p).map { (i, $0) } }.min { $0.1 < $1.1 }
        let ci = cars.indices.compactMap { i in along(cars[i].p).map { (i, $0) } }.min { $0.1 < $1.1 }
        if let (i, t) = pi, t < (ci?.1 ?? .infinity) { peds.remove(at: i); score += 20; wanted = min(5, wanted + 1) }
        else if let (i, _) = ci { cars[i].hp -= 1; if cars[i].hp <= 0 { if cars[i].cop { score += 100 }; Sound.bang(1); cars.remove(at: i); if let dr = driving, dr > i { driving = dr - 1 }; wanted = min(5, wanted + 1) } }
    }
    func busted() { msg = "BUSTED"; ammo = 60; cars.removeAll(where: \.cop); wanted = 0; score = max(0, score - 50); driving = nil; player = CGPoint(x: 8 * block + 40, y: 5 * block + 40) }
}
func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

import SceneKit

// ponytail: 2D sim stays the source of truth, SceneKit just renders it first person. x->x, y->z.
final class World {
    let scene = SCNScene(), cam = SCNNode()
    var carNodes: [SCNNode] = [], pedNodes: [SCNNode] = []
    let sky = NSColor(red: 0.62, green: 0.74, blue: 0.86, alpha: 1)

    init() {
        let r = scene.rootNode
        scene.background.contents = sky
        scene.fogColor = sky; scene.fogStartDistance = 900; scene.fogEndDistance = 3200
        cam.camera = SCNCamera(); cam.camera!.zNear = 1; cam.camera!.zFar = 6000; cam.camera!.fieldOfView = 75
        r.addChildNode(cam)
        let sun = SCNNode(); sun.light = SCNLight(); sun.light!.type = .directional; sun.light!.castsShadow = true
        sun.eulerAngles = SCNVector3(-1.0, 0.6, 0); r.addChildNode(sun)
        let amb = SCNNode(); amb.light = SCNLight(); amb.light!.type = .ambient; amb.light!.intensity = 450; r.addChildNode(amb)
        r.addChildNode(plane(20000, 20000, NSColor(red: 0.12, green: 0.32, blue: 0.48, alpha: 1), CGPoint(x: world.width / 2, y: world.height / 2), -2))
        // North Shore mountains across the inlet
        for i in 0..<9 {
            let m = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: CGFloat(500 + i % 3 * 150), height: CGFloat(600 + i % 4 * 180)))
            m.geometry!.firstMaterial!.diffuse.contents = NSColor(red: 0.25, green: 0.36, blue: 0.3, alpha: 1)
            m.position = SCNVector3(CGFloat(i) * 520 - 400, CGFloat(300 + i % 4 * 90), -1500 - CGFloat(i % 2) * 300); r.addChildNode(m)
        }
        for by in 0..<rows { for bx in 0..<cols {
            let k = vanMap[by][bx]; if k == "W" { continue }
            let c = CGPoint(x: (CGFloat(bx) + 0.5) * block, y: (CGFloat(by) + 0.5) * block)
            r.addChildNode(plane(block, block, k == "P" ? NSColor(red: 0.18, green: 0.42, blue: 0.2, alpha: 1) : NSColor(white: 0.22, alpha: 1), c, 0))
            if k == "P" {
                for t in 0..<6 {
                    let tree = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 22, height: 90))
                    tree.geometry!.firstMaterial!.diffuse.contents = NSColor(red: 0.08, green: 0.28, blue: 0.12, alpha: 1)
                    tree.position = SCNVector3(c.x - 100 + CGFloat(t * 41 % 200), 45, c.y - 90 + CGFloat(t * 67 % 180)); r.addChildNode(tree)
                }
            }
            if k != "P" {
                let y = NSColor(red: 0.9, green: 0.75, blue: 0.2, alpha: 1)
                r.addChildNode(plane(block, 2, y, CGPoint(x: c.x, y: c.y - block / 2 + road / 2), 0.2))
                r.addChildNode(plane(2, block, y, CGPoint(x: c.x - block / 2 + road / 2, y: c.y), 0.2))
            }
            if k == "P" || k == "R" { continue }
            let lot = CGPoint(x: c.x + road / 2, y: c.y + road / 2), w = block - road - 20
            r.addChildNode(plane(block - road, block - road, NSColor(white: 0.45, alpha: 1), lot, 0.5))
            let node: SCNNode
            switch k {
            case "C": node = box(w, 60, w, .white); let sail = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 30, height: 70)); sail.geometry!.firstMaterial!.diffuse.contents = NSColor.white
                for i in 0..<4 { let s2 = sail.clone(); s2.position = SCNVector3(CGFloat(i) * 40 - 60, 65, 0); node.addChildNode(s2) }
            case "S": node = SCNNode(geometry: SCNSphere(radius: w / 2)); node.scale = SCNVector3(1, 0.4, 1); node.geometry!.firstMaterial!.diffuse.contents = NSColor(white: 0.9, alpha: 1)
            case "E": node = SCNNode(geometry: SCNSphere(radius: w / 2.4)); node.geometry!.firstMaterial!.diffuse.contents = NSColor(white: 0.8, alpha: 1); node.geometry!.firstMaterial!.metalness.contents = 0.9
            case "L": node = box(w, 50, w * 0.6, NSColor(red: 0.8, green: 0.75, blue: 0.6, alpha: 1)); let dome = SCNNode(geometry: SCNSphere(radius: 30)); dome.geometry!.firstMaterial!.diffuse.contents = NSColor(red: 0.4, green: 0.6, blue: 0.5, alpha: 1); dome.position.y = 35; node.addChildNode(dome)
            default:
                let h = CGFloat(80 + (bx * 37 + by * 91) % 7 * 60 + (by >= 3 && by <= 7 && bx >= 6 && bx <= 12 ? 200 : 0))
                let tone = 0.45 + CGFloat((bx * 7 + by) % 5) * 0.09
                node = box(w, h, w, NSColor(red: tone * 0.9, green: tone, blue: tone * 1.1, alpha: 1))
                node.geometry!.firstMaterial!.diffuse.contents = windows(NSColor(red: tone * 0.9, green: tone, blue: tone * 1.1, alpha: 1))
                node.geometry!.firstMaterial!.diffuse.contentsTransform = SCNMatrix4MakeScale(1, h / 40, 1)
                node.geometry!.firstMaterial!.diffuse.wrapT = .repeat; node.geometry!.firstMaterial!.diffuse.maxAnisotropy = 16; node.geometry!.firstMaterial!.diffuse.mipFilter = .linear
            }
            node.position = SCNVector3(lot.x, k == "C" || k == "E" ? w / 2.4 : k == "S" ? 0 : node.boundingBox.max.y, lot.y)
            if k == "C" { node.position.y = 30 }
            r.addChildNode(node)
        }}
    }
    func windows(_ c: NSColor) -> NSImage {
        NSImage(size: NSSize(width: 256, height: 256), flipped: false) { rect in
            c.setFill(); rect.fill()
            NSColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 1).setFill()
            for x in 0..<4 { for y in 0..<2 { NSRect(x: 16 + x * 64, y: 24 + y * 128, width: 40, height: 80).fill() } }
            NSColor(white: 1, alpha: 0.12).setFill(); for x in 0..<4 { for y in 0..<2 { NSRect(x: 16 + x * 64, y: 84 + y * 128, width: 40, height: 20).fill() } }
            return true
        }
    }
    func plane(_ w: CGFloat, _ h: CGFloat, _ c: NSColor, _ at: CGPoint, _ y: CGFloat) -> SCNNode {
        let n = SCNNode(geometry: SCNPlane(width: w, height: h)); n.geometry!.firstMaterial!.diffuse.contents = c
        n.eulerAngles.x = -.pi / 2; n.position = SCNVector3(at.x, y, at.y); return n
    }
    func box(_ w: CGFloat, _ h: CGFloat, _ l: CGFloat, _ c: NSColor) -> SCNNode {
        let n = SCNNode(geometry: SCNBox(width: w, height: h, length: l, chamferRadius: 2)); n.geometry!.firstMaterial!.diffuse.contents = c; return n
    }
    func carNode(_ c: Car) -> SCNNode {
        let (l, w, _) = kinds[c.kind], h: CGFloat = c.kind == 2 ? 26 : 10
        let n = box(l, h, w, NSColor(c.kind == 2 ? .blue.opacity(0.6) : c.color)); n.position.y = 8
        if c.kind == 1 { let sign = box(6, 4, 10, .white); sign.position = SCNVector3(0, 15, 0); n.addChildNode(sign) }
        for (x, z) in [(l / 2 - 8, w / 2), (l / 2 - 8, -w / 2), (-l / 2 + 8, w / 2), (-l / 2 + 8, -w / 2)] { let wh = SCNNode(geometry: SCNCylinder(radius: 5, height: 3)); wh.geometry!.firstMaterial!.diffuse.contents = NSColor.black; wh.eulerAngles.x = .pi / 2; wh.position = SCNVector3(x, -4, z); n.addChildNode(wh) }
        let cab = box(20, 8, 18, NSColor(white: 0.1, alpha: 0.8)); cab.position = SCNVector3(-2, 8, 0); n.addChildNode(cab)
        if c.cop { let bar = box(4, 3, 16, .red); bar.name = "bar"; bar.position = SCNVector3(-2, 13, 0); n.addChildNode(bar) }
        return n
    }

    lazy var beacon: SCNNode = {
        let n = SCNNode(geometry: SCNCylinder(radius: 14, height: 600)); n.geometry!.firstMaterial!.diffuse.contents = NSColor.systemYellow.withAlphaComponent(0.35)
        n.geometry!.firstMaterial!.emission.contents = NSColor.systemYellow; n.geometry!.firstMaterial!.lightingModel = .constant; scene.rootNode.addChildNode(n); return n
    }()
    lazy var hero: SCNNode = {
        let n = SCNNode(), body = box(8, 13, 6, NSColor(red: 0.75, green: 0.12, blue: 0.1, alpha: 1)); body.position.y = 13
        let head = SCNNode(geometry: SCNSphere(radius: 3.5)); head.geometry!.firstMaterial!.diffuse.contents = NSColor(red: 0.85, green: 0.65, blue: 0.5, alpha: 1); head.position.y = 23
        let gun = box(8, 2, 2, .black); gun.position = SCNVector3(7, 14, 4)
        for s in [-2.0, 2.0] { let leg = box(3, 7, 3, .darkGray); leg.name = "leg"; leg.pivot = SCNMatrix4MakeTranslation(0, 3.5, 0); leg.position = SCNVector3(0, 7, s); n.addChildNode(leg) }
        [body, head, gun].forEach(n.addChildNode); scene.rootNode.addChildNode(n); return n
    }()
    func sync(_ g: Game) {
        beacon.position = SCNVector3(g.target.x, 300, g.target.y); beacon.isHidden = g.step < 2
        // day/night: 4 minute cycle
        let day = (sin(Date().timeIntervalSince1970 * 2 * .pi / 240) + 1) / 2
        let skyC = NSColor(red: 0.08 + 0.54 * day, green: 0.1 + 0.64 * day, blue: 0.2 + 0.66 * day, alpha: 1)
        scene.background.contents = skyC; scene.fogColor = skyC
        scene.rootNode.childNodes.first { $0.light?.type == .directional }?.light?.intensity = 200 + 800 * day
        if carNodes.count != g.cars.count { carNodes.forEach { $0.removeFromParentNode() }; carNodes = g.cars.map(carNode); carNodes.forEach(scene.rootNode.addChildNode) }
        if pedNodes.count != g.peds.count {
            pedNodes.forEach { $0.removeFromParentNode() }
            pedNodes = g.peds.indices.map { i in
                let n = SCNNode(), body = box(7, 12, 5, [NSColor.brown, .systemRed, .systemBlue, .black, .systemGreen][i % 5]); body.position.y = 12
                let head = SCNNode(geometry: SCNSphere(radius: 3)); head.geometry!.firstMaterial!.diffuse.contents = NSColor(red: 0.85, green: 0.65, blue: 0.5, alpha: 1); head.position.y = 21
                for s in [-2.0, 2.0] { let leg = box(2.5, 6, 2.5, .darkGray); leg.name = "leg"; leg.pivot = SCNMatrix4MakeTranslation(0, 3, 0); leg.position = SCNVector3(0, 6, s); n.addChildNode(leg) }
                n.addChildNode(body); n.addChildNode(head); return n }
            pedNodes.forEach(scene.rootNode.addChildNode)
        }
        let flash = Int(Date().timeIntervalSince1970 * 6) % 2 == 0
        for (i, c) in g.cars.enumerated() {
            carNodes[i].position = SCNVector3(c.p.x, c.kind == 2 ? 16 : 8, c.p.y); carNodes[i].eulerAngles.y = -c.a; carNodes[i].isHidden = false
            carNodes[i].childNode(withName: "bar", recursively: false)?.geometry?.firstMaterial?.diffuse.contents = flash ? NSColor.red : NSColor.blue
        }
        for (i, p) in g.peds.enumerated() {
            pedNodes[i].position = SCNVector3(p.p.x, 0, p.p.y); pedNodes[i].eulerAngles.y = -p.a
            for (j, leg) in pedNodes[i].childNodes.filter({ $0.name == "leg" }).enumerated() { leg.eulerAngles.z = sin(p.t + CGFloat(j) * .pi) * 0.5 }
        }
        let a = g.driving.map { g.cars[$0].a } ?? g.pa
        hero.isHidden = g.driving != nil; hero.position = SCNVector3(g.player.x, g.z, g.player.y); hero.eulerAngles.y = -a
        let moving = !g.keys.isDisjoint(with: [13, 1, 126, 125])
        for (j, leg) in hero.childNodes.filter({ $0.name == "leg" }).enumerated() { leg.eulerAngles.z = moving ? sin(Date().timeIntervalSince1970 * 10 + Double(j) * .pi) * 0.6 : 0 }
        // third person: sit behind the hero, pull in so buildings never block the view
        let back: CGFloat = g.driving == nil ? 70 : 110, up: CGFloat = g.driving == nil ? 38 : 48
        var d = back
        while d > 12 && solid(CGPoint(x: g.player.x - cos(a) * d, y: g.player.y - sin(a) * d)) { d -= 6 }
        cam.position = SCNVector3(g.player.x - cos(a) * d, up, g.player.y - sin(a) * d)
        cam.eulerAngles = SCNVector3(-0.28, -a - .pi / 2, 0)
    }
}

struct SceneBox: NSViewRepresentable {
    let w: World
    func makeNSView(context: Context) -> SCNView {
        let v = SCNView(); v.scene = w.scene; v.pointOfView = w.cam; v.antialiasingMode = .multisampling8X; v.layer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 2; v.preferredFramesPerSecond = 60
        // QA hook: GS_SNAP=/path.png writes a frame after 3s and quits
        if let out = ProcessInfo.processInfo.environment["GS_SNAP"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                let img = v.snapshot(); let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
                try? rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out)); exit(0)
            }
        }
        return v
    }
    func updateNSView(_ v: SCNView, context: Context) {}
}

struct GameView: View {
    @StateObject var g = Game()
    @State var w = World()
    let timer = Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()
    var hud: String {
        let street = streetName(g.player)
        var t = g.step < g.tut.count ? "▶ " + g.tut[g.step] + "\n" : ""
        t += "\(g.heroes[g.cur].name)   $\(g.score)   " + String(repeating: "★", count: g.wanted)
        t += "\n" + street + (street.contains("Victoria") ? "" : ", Vancouver")
        if let d = g.driving { t += "\n\(Int(abs(g.cars[d].v) / 4)) km/h" } else { t += "\nAmmo \(g.ammo)" }
        t += "\nWASD move, E car, click/Enter shoot, Shift run, Space jump, Tab swap, Esc pause"
        if !g.msg.isEmpty { t += "\n" + g.msg }
        return t
    }
    func resume() { g.paused = false; g.keys = [] }
    var body: some View {
        SceneBox(w: w)
        .onReceive(timer) { _ in g.tick(); w.sync(g) }
        .overlay { Image(systemName: "plus").foregroundStyle(.white.opacity(0.7)) }
        .overlay { if g.flash > 0 { Circle().fill(.yellow.opacity(0.6)).frame(width: 30).blur(radius: 4).offset(y: 30).allowsHitTesting(false) } }
        .overlay {
            if g.paused {
                ZStack {
                    Color.black.opacity(0.6)
                    VStack(spacing: 14) {
                        Text("PAUSED").font(.system(size: 44, weight: .heavy))
                        Button("Resume") { resume() }.keyboardShortcut(.defaultAction)
                        Button("Toggle full screen (F)") { NSApp.windows.first?.toggleFullScreen(nil) }
                        Button("Restart tutorial") { g.step = 0; g.walkFrom = g.player; resume() }
                        Button("Quit") { NSApp.terminate(nil) }
                        Text("W A S D move · mouse look · click/Enter shoot · Shift run · Space jump · E car · Tab swap · Esc pause").font(.system(size: 13)).opacity(0.8).padding(.top, 10)
                    }.foregroundStyle(.white).buttonStyle(.borderedProminent).controlSize(.large)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            Text(hud)
                .font(.system(size: 16, weight: .bold)).foregroundStyle(.white).padding(12).shadow(radius: 2)
        }
        .overlay(alignment: .topTrailing) {
            Canvas { ctx, _ in
                let s: CGFloat = 10
                for by in 0..<rows { for bx in 0..<cols {
                    let k = vanMap[by][bx]
                    ctx.fill(Path(CGRect(x: CGFloat(bx) * s, y: CGFloat(by) * s, width: s, height: s)), with: .color(k == "W" ? .blue : k == "P" ? .green : .gray))
                }}
                for c in g.cars where c.cop { ctx.fill(Path(ellipseIn: CGRect(x: c.p.x / block * s - 2, y: c.p.y / block * s - 2, width: 4, height: 4)), with: .color(.red)) }
                ctx.fill(Path(ellipseIn: CGRect(x: g.player.x / block * s - 3, y: g.player.y / block * s - 3, width: 6, height: 6)), with: .color(.yellow))
            }
            .frame(width: CGFloat(cols) * 10, height: CGFloat(rows) * 10).padding(12)
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { e in
                if e.type == .flagsChanged { if e.modifierFlags.contains(.shift) { g.keys.insert(56) } else { g.keys.remove(56) }; return e }
                if e.type == .keyDown { if e.keyCode == 14 && !e.isARepeat { g.toggleCar() }; if e.keyCode == 53 && !e.isARepeat { if g.paused { resume() } else { g.paused = true; CGAssociateMouseAndMouseCursorPosition(1); NSCursor.unhide() } }; if e.keyCode == 3 && !e.isARepeat { NSApp.windows.first?.toggleFullScreen(nil) }; if g.paused { return e }; if e.keyCode == 49 && g.driving == nil && g.z == 0 { g.vz = 180 }; if e.keyCode == 36 { g.shoot() }; if e.keyCode == 48 && !e.isARepeat { g.swapHero() }; g.keys.insert(e.keyCode) } else { g.keys.remove(e.keyCode) }
                return nil
            }
            NSApp.windows.forEach { $0.acceptsMouseMovedEvents = true }
            if ProcessInfo.processInfo.environment["GS_SNAP"] == nil { DispatchQueue.main.async { NSApp.windows.first?.toggleFullScreen(nil) } }
            NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown]) { e in
                if g.paused { return e }; if e.type == .leftMouseDown { CGAssociateMouseAndMouseCursorPosition(0); NSCursor.hide(); g.shoot() } else { g.mouseDX += e.deltaX }
                return e
            }
        }
    }
}

// Dock icon: Vancouver skyline at dusk over the water
func appIcon() -> NSImage {
    NSImage(size: NSSize(width: 1024, height: 1024), flipped: false) { r in
        NSBezierPath(roundedRect: r.insetBy(dx: 100, dy: 100), xRadius: 185, yRadius: 185).addClip()
        NSGradient(starting: NSColor(red: 0.98, green: 0.55, blue: 0.25, alpha: 1), ending: NSColor(red: 0.2, green: 0.25, blue: 0.5, alpha: 1))!.draw(in: r, angle: -90)
        NSColor(red: 0.2, green: 0.3, blue: 0.3, alpha: 1).setFill()
        let m = NSBezierPath(); m.move(to: NSPoint(x: 100, y: 520)); m.line(to: NSPoint(x: 330, y: 760)); m.line(to: NSPoint(x: 520, y: 600)); m.line(to: NSPoint(x: 700, y: 800)); m.line(to: NSPoint(x: 924, y: 560)); m.line(to: NSPoint(x: 924, y: 400)); m.line(to: NSPoint(x: 100, y: 400)); m.fill()
        NSColor(red: 0.08, green: 0.1, blue: 0.16, alpha: 1).setFill()
        for (x, h) in [(160, 180), (240, 300), (330, 230), (420, 380), (510, 280), (600, 420), (690, 250), (780, 330), (860, 200)] { NSRect(x: x, y: 300, width: 72, height: h).fill() }
        NSColor(red: 0.1, green: 0.25, blue: 0.45, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: 1024, height: 310).fill()
        NSColor(red: 1, green: 0.85, blue: 0.4, alpha: 1).setFill()
        for i in 0..<14 { NSRect(x: 172 + (i * 83) % 700, y: 340 + (i * 57) % 200, width: 14, height: 18).fill() }
        return true
    }
}

import AVFoundation
// Synth audio: engine hum by speed, siren sweep, noise bursts for gunshots/crashes.
// ponytail: cross-thread vars without locks, fine for audio params; atomics if it ever glitches
enum Sound {
    static var engine: Float = 0, siren = false, burst: Float = 0
    static func bang(_ v: Float) { burst = max(burst, v) }
    static let av = AVAudioEngine()
    static func start() {
        var ph: Float = 0, sp: Float = 0, t: Float = 0
        let fmt = av.outputNode.inputFormat(forBus: 0), sr = Float(fmt.sampleRate)
        let src = AVAudioSourceNode { _, _, n, abl -> OSStatus in
            let bufs = UnsafeMutableAudioBufferListPointer(abl)
            for f in 0..<Int(n) {
                t += 1 / sr
                ph += (40 + engine * 140) / sr; if ph > 1 { ph -= 1 }
                var x = (ph * 2 - 1) * (engine > 0.01 ? 0.08 + engine * 0.1 : 0)
                if siren { sp += (700 + 300 * sin(t * 4)) / sr; x += sin(sp * 2 * .pi) * 0.06 }
                if burst > 0.001 { x += Float.random(in: -1...1) * burst * 0.6; burst *= 0.9993 }
                for b in bufs { b.mData!.assumingMemoryBound(to: Float.self)[f] = x }
            }
            return noErr
        }
        av.attach(src); av.connect(src, to: av.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: fmt.sampleRate, channels: 1))
        try? av.start()
    }
}

// Dogfood run: GS_QA=1 ./grandswift plays the sim headless and asserts the core loop works.
func runQA() -> Never {
    var fails: [String] = []
    func check(_ ok: Bool, _ what: String) { print(ok ? "PASS" : "FAIL", what); if !ok { fails.append(what) } }
    func run(_ g: Game, _ n: Int) { for _ in 0..<n { g.last = Date().addingTimeInterval(-1 / 60); g.tick() } }
    let g = Game()
    check(!solid(g.player), "spawn is on road")
    check(g.peds.allSatisfy { !solid($0.p) }, "all peds spawn on walkable ground")
    let trafficStart = g.cars.filter(\.ai).map(\.p)
    run(g, 120)
    check(zip(trafficStart, g.cars.filter(\.ai).map(\.p)).contains { dist($0, $1) > 20 }, "traffic moves")
    check(g.peds.allSatisfy { !solid($0.p) }, "peds stay off buildings/water after 2s")
    let p0 = g.player; g.keys = [13]; run(g, 60); g.keys = []
    check(dist(p0, g.player) > 30, "player walks forward")
    for _ in 0..<600 { g.keys = [13]; run(g, 1) }; g.keys = []
    check(!solid(g.player), "player never ends inside a building")
    // put a car next to player and jack it
    let ci = g.cars.firstIndex { !$0.cop }!; g.cars[ci].p = CGPoint(x: g.player.x + 20, y: g.player.y); g.cars[ci].v = 0; g.cars[ci].ai = false
    g.toggleCar(); check(g.driving != nil, "E enters nearby car")
    let c0 = g.player; g.keys = [13]; run(g, 90); g.keys = []
    check(dist(c0, g.player) > 50 || g.cars[g.driving!].v != 0, "car accelerates")
    g.toggleCar(); check(g.driving == nil && !solid(g.player), "E exits car onto road")
    // shoot a ped placed in front of us
    g.peds.append(Ped(p: CGPoint(x: g.player.x + cos(g.pa) * 60, y: g.player.y + sin(g.pa) * 60), a: 0))
    let n0 = g.peds.count, a0 = g.ammo; g.shoot()
    check(g.ammo == a0 - 1 && g.peds.count == n0 - 1, "gun hits ped in crosshair")
    check(g.wanted > 0, "shooting raises wanted level")
    run(g, 60); check(g.cars.contains(where: \.cop), "cops spawn when wanted")
    let jp = g.player; g.swapHero()
    check(g.heroes[g.cur].name == "Alexandre" && streetName(g.player).contains("Victoria"), "Tab swaps to Alexandre in Victoria")
    g.swapHero(); check(dist(g.player, jp) < 1, "swap back restores Joshua's spot")
    let t = Game(); t.walkFrom = t.player; t.player.x += 150; run(t, 1); check(t.step == 1, "tutorial: walking advances")
    t.shoot(); run(t, 1); check(t.step == 2, "tutorial: shooting advances")
    let tc = t.cars.firstIndex { !$0.cop }!; t.cars[tc].p = CGPoint(x: t.player.x + 20, y: t.player.y); t.toggleCar(); run(t, 1); check(t.step == 3, "tutorial: entering car advances")
    t.cars[t.driving!].p = t.target; run(t, 1); check(t.step == 4, "tutorial: reaching beacon advances")
    t.swapHero(); run(t, 1); check(t.step == 5, "tutorial: swap finishes it")
    check(!Game.spots.isEmpty && Game.spots.allSatisfy { !solid($0) }, "mission beacons are on road")
    g.paused = true; let pp = g.player; g.keys = [13]; run(g, 60); g.keys = []; check(dist(pp, g.player) < 0.01, "pause freezes the game"); g.paused = false
    run(g, 3600); check(g.peds.count > 20 && !g.player.x.isNaN, "60s soak, no NaN, city stays populated")
    print(fails.isEmpty ? "QA OK" : "QA FAILED: \(fails.count)"); exit(fails.isEmpty ? 0 : 1)
}

@main struct GrandSwift: App {
    init() { if ProcessInfo.processInfo.environment["GS_QA"] != nil { runQA() }; NSApplication.shared.setActivationPolicy(.regular); // one copy at a time: newest launch kills any older instance
        let me = ProcessInfo.processInfo.processIdentifier
        NSWorkspace.shared.runningApplications.filter { $0.executableURL?.lastPathComponent == "grandswift" && $0.processIdentifier != me }.forEach { $0.forceTerminate() }
        NSApp.applicationIconImage = appIcon(); Sound.start()
        if let out = ProcessInfo.processInfo.environment["GS_ICON"] { let rep = NSBitmapImageRep(data: appIcon().tiffRepresentation!)!; try? rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out)); exit(0) }; DispatchQueue.main.async { NSApp.activate(ignoringOtherApps: true) } }
    var body: some Scene { WindowGroup("Grand Swift") { GameView().frame(minWidth: 900, minHeight: 600) } }
}
