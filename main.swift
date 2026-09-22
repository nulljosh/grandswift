import SwiftUI
import AppKit

// ponytail: whole game in one file, top-down GTA 1 style. Split into files when it outgrows ~500 lines.
let block: CGFloat = 260, road: CGFloat = 80
// ponytail: hand-drawn Vancouver, one char per block. W water, P Stanley Park, R bridge deck, B city, letters = landmarks
let vanMap = [
    "WWWWWWWWWWWWWWWW",
    "WPPPWWWWWWWWWWWW",
    "PPPPPWWWWCWWWWWW",
    "PPPPBBBBBBBBBWWW",
    "WPPBBBBBBBBBBBBW",
    "WWBBBBBBBBBBBBBB",
    "WWWBBBBBBBBBBBBB",
    "WWWWBBBBBBBSBBBB",
    "WWWWWWBBBBBBBBBB",
    "WWWWWRWWRWWWWWEW",
    "BBBBBBBBBBBBBBBB",
    "BBBBBBBBBBBBBBBB",
].map { Array($0) }
let cols = vanMap[0].count, rows = vanMap.count
let world = CGSize(width: block * CGFloat(cols), height: block * CGFloat(rows))
let landmarks: [Character: (String, Color)] = ["C": ("Canada Place", .white), "S": ("BC Place", Color(white: 0.85)), "E": ("Science World", Color(red: 0.8, green: 0.8, blue: 0.9))]
let aves = ["", "", "", "W Hastings", "W Pender", "W Georgia", "Robson", "Smithe", "Pacific", "False Creek", "W 2nd", "W 4th"]
let streets = ["Chilco", "Denman", "Bidwell", "Nicola", "Bute", "Thurlow", "Burrard", "Hornby", "Granville", "Seymour", "Richards", "Homer", "Cambie", "Beatty", "Quebec", "Main"]

func cell(_ p: CGPoint) -> Character? {
    let c = Int(p.x / block), r = Int(p.y / block)
    return p.x < 0 || p.y < 0 || c >= cols || r >= rows ? nil : vanMap[r][c]
}
func solid(_ p: CGPoint) -> Bool {
    guard let k = cell(p), k != "W" else { return true }
    if k == "P" || k == "R" { return false }
    let x = p.x.truncatingRemainder(dividingBy: block), y = p.y.truncatingRemainder(dividingBy: block)
    return x > road && y > road
}
func streetName(_ p: CGPoint) -> String {
    let c = Int(p.x / block), r = Int(p.y / block)
    if cell(p) == "P" { return "Stanley Park" }
    if cell(p) == "R" { return c == 5 ? "Burrard Bridge" : "Granville Bridge" }
    let x = p.x.truncatingRemainder(dividingBy: block), y = p.y.truncatingRemainder(dividingBy: block)
    let ave = r < aves.count ? aves[r] : "", st = c < streets.count ? streets[c] : ""
    if x <= road && y <= road { return "\(st) & \(ave)" }
    return x <= road ? st : ave
}

struct Car { var p: CGPoint; var a: CGFloat = 0; var v: CGFloat = 0; var color: Color; var cop = false; var ai = false }
struct Ped { var p: CGPoint; var a: CGFloat }

final class Game: ObservableObject {
    var keys = Set<UInt16>()
    var player = CGPoint(x: 8 * block + 40, y: 5 * block + 40), pa: CGFloat = 0
    var cars: [Car] = [], peds: [Ped] = []
    var driving: Int? = nil
    var wanted = 0, score = 0, last = Date()

    init() {
        let colors: [Color] = [.red, .yellow, .orange, .green, .white, .pink]
        for i in 0..<25 { cars.append(Car(p: roadPoint(), a: CGFloat(i % 4) * .pi / 2, color: colors[i % colors.count], ai: i % 3 != 0)) }
        for _ in 0..<60 { peds.append(Ped(p: roadPoint(), a: .random(in: 0...(2 * .pi)))) }
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
        let now = Date(); let dt = CGFloat(min(now.timeIntervalSince(last), 0.05)); last = now
        let fwd = down(13) || down(126), back = down(1) || down(125), left = down(0) || down(123), right = down(2) || down(124)
        if let i = driving {
            var c = cars[i]
            c.v += (fwd ? 500 : 0) * dt - (back ? 400 : 0) * dt; c.v *= 0.98; c.v = max(-150, min(420, c.v))
            c.a += ((right ? 1 : 0) - (left ? 1 : 0)) * 2.8 * dt * (c.v / 300)
            move(&c, dt); cars[i] = c; player = c.p
        } else {
            pa += ((right ? 1 : 0) - (left ? 1 : 0)) * 4 * dt
            let s: CGFloat = (fwd ? 140 : 0) - (back ? 80 : 0)
            let n = CGPoint(x: player.x + cos(pa) * s * dt, y: player.y + sin(pa) * s * dt)
            if !solid(n) { player = n }
        }
        for i in peds.indices {
            let n = CGPoint(x: peds[i].p.x + cos(peds[i].a) * 30 * dt, y: peds[i].p.y + sin(peds[i].a) * 30 * dt)
            if solid(n) || .random(in: 0...1) < 0.005 { peds[i].a = .random(in: 0...(2 * .pi)) } else { peds[i].p = n }
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
        if peds.count < 40 { peds.append(Ped(p: roadPoint(), a: 0)) }
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
        objectWillChange.send()
    }
    func move(_ c: inout Car, _ dt: CGFloat) {
        let n = CGPoint(x: c.p.x + cos(c.a) * c.v * dt, y: c.p.y + sin(c.a) * c.v * dt)
        if solid(n) { c.v *= -0.3 } else { c.p = n }
    }
    func busted() { cars.removeAll(where: \.cop); wanted = 0; score = max(0, score - 50); driving = nil; player = CGPoint(x: 8 * block + 40, y: 5 * block + 40) }
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
            default:
                let h = CGFloat(80 + (bx * 37 + by * 91) % 7 * 60 + (by >= 3 && by <= 7 && bx >= 6 && bx <= 12 ? 200 : 0))
                let tone = 0.45 + CGFloat((bx * 7 + by) % 5) * 0.09
                node = box(w, h, w, NSColor(red: tone * 0.9, green: tone, blue: tone * 1.1, alpha: 1))
                node.geometry!.firstMaterial!.diffuse.contents = windows(NSColor(red: tone * 0.9, green: tone, blue: tone * 1.1, alpha: 1))
                node.geometry!.firstMaterial!.diffuse.contentsTransform = SCNMatrix4MakeScale(1, h / 40, 1)
                node.geometry!.firstMaterial!.diffuse.wrapT = .repeat
            }
            node.position = SCNVector3(lot.x, k == "C" || k == "E" ? w / 2.4 : k == "S" ? 0 : node.boundingBox.max.y, lot.y)
            if k == "C" { node.position.y = 30 }
            r.addChildNode(node)
        }}
    }
    func windows(_ c: NSColor) -> NSImage {
        NSImage(size: NSSize(width: 64, height: 64), flipped: false) { rect in
            c.setFill(); rect.fill()
            NSColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 1).setFill()
            for x in 0..<4 { for y in 0..<2 { NSRect(x: 4 + x * 16, y: 6 + y * 32, width: 10, height: 20).fill() } }
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
        let n = box(40, 10, 20, NSColor(c.color)); n.position.y = 8
        let cab = box(20, 8, 18, NSColor(white: 0.1, alpha: 0.8)); cab.position = SCNVector3(-2, 8, 0); n.addChildNode(cab)
        if c.cop { let bar = box(4, 3, 16, .red); bar.name = "bar"; bar.position = SCNVector3(-2, 13, 0); n.addChildNode(bar) }
        return n
    }

    func sync(_ g: Game) {
        if carNodes.count != g.cars.count { carNodes.forEach { $0.removeFromParentNode() }; carNodes = g.cars.map(carNode); carNodes.forEach(scene.rootNode.addChildNode) }
        if pedNodes.count != g.peds.count {
            pedNodes.forEach { $0.removeFromParentNode() }
            pedNodes = g.peds.indices.map { i in let n = box(6, 16, 6, [NSColor.brown, .systemRed, .systemBlue, .black][i % 4]); n.position.y = 8; return n }
            pedNodes.forEach(scene.rootNode.addChildNode)
        }
        let flash = Int(Date().timeIntervalSince1970 * 6) % 2 == 0
        for (i, c) in g.cars.enumerated() {
            carNodes[i].position = SCNVector3(c.p.x, 8, c.p.y); carNodes[i].eulerAngles.y = -c.a; carNodes[i].isHidden = g.driving == i
            carNodes[i].childNode(withName: "bar", recursively: false)?.geometry?.firstMaterial?.diffuse.contents = flash ? NSColor.red : NSColor.blue
        }
        for (i, p) in g.peds.enumerated() { pedNodes[i].position = SCNVector3(p.p.x, 8, p.p.y) }
        let a = g.driving.map { g.cars[$0].a } ?? g.pa
        cam.position = SCNVector3(g.player.x, g.driving == nil ? 14 : 11, g.player.y)
        cam.eulerAngles = SCNVector3(-0.04, -a - .pi / 2, 0)
    }
}

struct SceneBox: NSViewRepresentable {
    let w: World
    func makeNSView(context: Context) -> SCNView {
        let v = SCNView(); v.scene = w.scene; v.pointOfView = w.cam; v.antialiasingMode = .multisampling4X; v.preferredFramesPerSecond = 60
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
    var body: some View {
        SceneBox(w: w)
        .onReceive(timer) { _ in g.tick(); w.sync(g) }
        .overlay { Image(systemName: "plus").foregroundStyle(.white.opacity(0.7)) }
        .overlay(alignment: .topLeading) {
            Text("$\(g.score)   " + String(repeating: "★", count: g.wanted) + "\n\(streetName(g.player)), Vancouver" + (g.driving.map { "\n\(Int(abs(g.cars[$0].v) / 4)) km/h" } ?? "") + "\nWASD/arrows move, E enter/exit car")
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
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { e in
                if e.type == .keyDown { if e.keyCode == 14 && !e.isARepeat { g.toggleCar() }; g.keys.insert(e.keyCode) } else { g.keys.remove(e.keyCode) }
                return nil
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

@main struct GrandSwift: App {
    init() { NSApplication.shared.setActivationPolicy(.regular); NSApp.applicationIconImage = appIcon()
        if let out = ProcessInfo.processInfo.environment["GS_ICON"] { let rep = NSBitmapImageRep(data: appIcon().tiffRepresentation!)!; try? rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out)); exit(0) }; DispatchQueue.main.async { NSApp.activate(ignoringOtherApps: true) } }
    var body: some Scene { WindowGroup("Grand Swift") { GameView().frame(minWidth: 900, minHeight: 600) } }
}
