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

struct Car { var p: CGPoint; var a: CGFloat = 0; var v: CGFloat = 0; var color: Color; var cop = false }
struct Ped { var p: CGPoint; var a: CGFloat }

final class Game: ObservableObject {
    var keys = Set<UInt16>()
    var player = CGPoint(x: 8 * block + 40, y: 5 * block + 40), pa: CGFloat = 0
    var cars: [Car] = [], peds: [Ped] = []
    var driving: Int? = nil
    var wanted = 0, score = 0, last = Date()

    init() {
        let colors: [Color] = [.red, .yellow, .orange, .green, .white, .pink]
        for i in 0..<25 { cars.append(Car(p: roadPoint(), a: CGFloat(i % 4) * .pi / 2, color: colors[i % colors.count])) }
        for _ in 0..<60 { peds.append(Ped(p: roadPoint(), a: .random(in: 0...(2 * .pi)))) }
    }
    func roadPoint() -> CGPoint {
        while true { let p = CGPoint(x: .random(in: 10...world.width - 10), y: .random(in: 10...world.height - 10)); if !solid(p) { return p } }
    }
    func down(_ k: UInt16) -> Bool { keys.contains(k) }

    func toggleCar() {
        if let i = driving { driving = nil; player = CGPoint(x: cars[i].p.x - sin(cars[i].a) * 30, y: cars[i].p.y + cos(cars[i].a) * 30); if solid(player) { player = cars[i].p }; return }
        if let i = cars.indices.filter({ !cars[$0].cop }).min(by: { dist(cars[$0].p, player) < dist(cars[$1].p, player) }), dist(cars[i].p, player) < 45 { driving = i; wanted = max(wanted, 1) }
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
        for c in cars where abs(c.v) > 120 { peds.removeAll { p in let hit = dist(p.p, c.p) < 20; if hit { score += 10; wanted = min(5, wanted + 1) }; return hit } }
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

struct GameView: View {
    @StateObject var g = Game()
    var body: some View {
        TimelineView(.animation) { t in
            Canvas { ctx, size in
                _ = t.date; g.tick()
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.1, green: 0.3, blue: 0.5)))
                ctx.translateBy(x: size.width / 2 - g.player.x, y: size.height / 2 - g.player.y)
                for by in 0..<rows { for bx in 0..<cols {
                    let k = vanMap[by][bx], full = CGRect(x: CGFloat(bx) * block, y: CGFloat(by) * block, width: block, height: block)
                    if k == "W" { continue }
                    if k == "P" { ctx.fill(Path(full), with: .color(Color(red: 0.15, green: 0.4, blue: 0.18))); continue }
                    ctx.fill(Path(full), with: .color(Color(white: 0.28)))
                    if k == "R" { continue }
                    let r = CGRect(x: full.minX + road, y: full.minY + road, width: block - road, height: block - road)
                    if let (name, col) = landmarks[k] {
                        ctx.fill(Path(r), with: .color(col))
                        ctx.draw(Text(name).font(.system(size: 18, weight: .heavy)).foregroundColor(.black), at: CGPoint(x: r.midX, y: r.midY))
                    } else {
                        ctx.fill(Path(r), with: .color((bx * 3 + by) % 7 == 0 ? Color(red: 0.2, green: 0.45, blue: 0.2) : Color(white: 0.5 + CGFloat((bx * 7 + by) % 4) * 0.07)))
                        ctx.stroke(Path(r.insetBy(dx: 12, dy: 12)), with: .color(.black.opacity(0.2)), lineWidth: 3)
                    }
                }}
                for p in g.peds { ctx.fill(Path(ellipseIn: CGRect(x: p.p.x - 5, y: p.p.y - 5, width: 10, height: 10)), with: .color(.brown)) }
                for c in g.cars {
                    var cc = ctx; cc.translateBy(x: c.p.x, y: c.p.y); cc.rotate(by: .radians(c.a))
                    cc.fill(Path(roundedRect: CGRect(x: -20, y: -10, width: 40, height: 20), cornerRadius: 4), with: .color(c.color))
                    cc.fill(Path(CGRect(x: 4, y: -8, width: 8, height: 16)), with: .color(.black.opacity(0.5)))
                    if c.cop { cc.fill(Path(CGRect(x: -4, y: -9, width: 6, height: 18)), with: .color(Int(t.date.timeIntervalSince1970 * 6) % 2 == 0 ? .red : .white)) }
                }
                if g.driving == nil {
                    var pc = ctx; pc.translateBy(x: g.player.x, y: g.player.y); pc.rotate(by: .radians(g.pa))
                    pc.fill(Path(ellipseIn: CGRect(x: -7, y: -7, width: 14, height: 14)), with: .color(.cyan))
                    pc.fill(Path(CGRect(x: 4, y: -2, width: 6, height: 4)), with: .color(.black))
                }
            }
        }
        .overlay(alignment: .topLeading) {
            Text("$\(g.score)   " + String(repeating: "★", count: g.wanted) + "\n\(streetName(g.player)), Vancouver\nWASD/arrows move, E enter/exit car")
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

@main struct GrandSwift: App {
    init() { NSApplication.shared.setActivationPolicy(.regular); DispatchQueue.main.async { NSApp.activate(ignoringOtherApps: true) } }
    var body: some Scene { WindowGroup("Grand Swift") { GameView().frame(minWidth: 900, minHeight: 600) } }
}
