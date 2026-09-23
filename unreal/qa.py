"""Auto player / QA for the Unreal build. Needs the editor open with Content/Python/init_unreal.py (the QA bridge).
Usage: python3 qa.py            -> starts Play, runs the walk test, prints PASS/FAIL, stops Play
       python3 qa.py drive      -> same, but jacks the getaway car and drives it (qa_drive.py)
       python3 qa.py 'print(1)' -> runs one Python snippet inside the editor
"""
import os, sys, time, json, subprocess
D = "/tmp/vv_qa"; HERE = os.path.dirname(os.path.abspath(__file__))

def run(src, timeout=int(os.environ.get("QA_TIMEOUT", 60))):  # long builds: QA_TIMEOUT=600
    os.makedirs(D, exist_ok=True)
    out = os.path.join(D, "out.txt")
    if os.path.exists(out): os.remove(out)
    open(os.path.join(D, "cmd.py"), "w").write(src)
    end = time.time() + timeout
    while time.time() < end:
        if os.path.exists(out): time.sleep(0.2); return open(out).read()
        time.sleep(0.5)
    raise SystemExit("editor did not answer (is the QA bridge loaded?)")

def mcp(toolset, tool, args):
    call = {"name": "call_tool", "arguments": {"toolset_name": toolset, "tool_name": tool, "arguments": args}}
    return subprocess.run([sys.executable, os.path.join(HERE, "mcp.py"), "tools/call", json.dumps(call)], capture_output=True, text=True, timeout=400).stdout

if __name__ == "__main__":
    test = "qa_drive.py" if sys.argv[1:] == ["drive"] else "qa_walk.py"
    if len(sys.argv) > 1 and test == "qa_walk.py":
        print(run(sys.argv[1])); sys.exit()

    A = "EditorToolset.EditorAppToolset"
    mcp(A, "StartPIE", {"options": {"bSimulate": False, "playMode": "PlayMode_InViewPort", "warmupSeconds": 5}})
    print("waiting for Vancouver to stream in"); time.sleep(90)
    print(run("QA_RESULT = 'FAIL test script crashed before it started'\n" + open(os.path.join(HERE, test)).read()))  # no stale PASS from an earlier run
    for _ in range(60):  # up to 2 minutes, polls until the walk reports
        time.sleep(2); res = run("print(QA_RESULT)")
        if not res.startswith("RUNNING"): break
    print(res)
    mcp(A, "StopPIE", {})
    sys.exit(0 if res.startswith("PASS") else 1)
