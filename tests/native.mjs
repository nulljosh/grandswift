// Native shell checks: every app points at the live game and nothing bundles a browser. node tests/native.mjs
import { readFileSync, existsSync } from "fs";
const URL = "https://vancouvervice.heyitsmejosh.com/play.html";
const shells = { windows: "apps/windows/App.cs", linux: "apps/linux/main.c", apple: "apps/apple/App.swift", android: "apps/android/app/src/main/java/com/jaybulb/vancouvervice/MainActivity.java" };
let fail = 0;
for (const [name, f] of Object.entries(shells)) { const ok = existsSync(f) && readFileSync(f, "utf8").includes(URL); console.log(ok ? "PASS" : "FAIL", name, f); if (!ok) fail++; }
const noElectron = !existsSync("apps/desktop") && !readFileSync(".github/workflows/release.yml", "utf8").includes("electron");
console.log(noElectron ? "PASS" : "FAIL", "no Electron anywhere"); if (!noElectron) fail++;
process.exit(fail ? 1 : 0);
