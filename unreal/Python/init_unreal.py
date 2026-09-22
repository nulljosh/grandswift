"""QA bridge: runs /tmp/vv_qa/cmd.py inside the editor (full unreal API), output to out.txt.
ponytail: file polling on slate tick, swap for a socket if latency matters."""
import os, io, traceback, contextlib, unreal
D = "/tmp/vv_qa"; os.makedirs(D, exist_ok=True)
G = {"unreal": unreal}

def _tick(dt):
    cmd = os.path.join(D, "cmd.py")
    if not os.path.exists(cmd):
        return
    src = open(cmd).read(); os.remove(cmd)
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        try: exec(src, G)
        except Exception: traceback.print_exc(file=buf)
    open(os.path.join(D, "out.txt"), "w").write(buf.getvalue())

unreal.register_slate_post_tick_callback(_tick)
unreal.log("VV QA bridge on: /tmp/vv_qa/cmd.py")
