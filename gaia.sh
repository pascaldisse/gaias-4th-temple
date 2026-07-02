#!/bin/sh
# gaia.sh -- one command: boot TempleOS, run Gaia Engine 64, leave the vision up.
#
#   ./gaia.sh          boot the Temple in a desktop window, beam in the engine,
#                      run the Seven Commands, and leave the 64-vector vision
#                      on screen (the terminal shows the rite's output)
#   ./gaia.sh stop     lay the Temple to rest
#
# Requires the fable-of-god bridge. If it lives somewhere other than
# ~/projects/fable-of-god, set FABLE_OF_GOD to its path.

set -e
GAIA_DIR="$(cd "$(dirname "$0")" && pwd)"
FOG="${FABLE_OF_GOD:-$HOME/projects/fable-of-god}"
[ -d "$FOG/ladder" ] || { echo "fable-of-god not found at $FOG (set FABLE_OF_GOD)"; exit 1; }
cd "$FOG"

if [ "$1" = "stop" ]; then
    exec python3 -m ladder quell
fi

GAIA_DIR="$GAIA_DIR" exec python3 - <<'EOF'
import os, pathlib, sys
sys.path.insert(0, os.getcwd())
from ladder import tabernacle
from ladder.voice import pentecost
from ladder.parable import bestow

tabernacle.WINDOWED = True  # a cold boot opens a real QEMU window

if tabernacle.pid():
    print("The Temple is already risen -- attaching to it.")
    print("(If you see no window, it was raised headless: ./gaia.sh stop, then rerun me.)")

src = (pathlib.Path(os.environ["GAIA_DIR"]) / "GaiaTemple.HC").read_text()

v = None
for attempt in (1, 2, 3):
    try:
        v = pentecost(verbose=True)
        break
    except Exception as woe:
        print(f"Pentecost faltered (attempt {attempt}/3): {woe}")
        if attempt == 3:
            sys.exit("The Temple would not attune. ./gaia.sh stop, then retry.")
        import time
        time.sleep(3)
try:
    print("Beaming the latest GaiaTemple.HC onto the Temple's disk...")
    bestow(v, "C:/Home/GaiaTemple.HC", src.encode("ascii"))

    u = v.utter('#include "C:/Home/GaiaTemple";', timeout=120)
    if not u.ok:
        print(u.text)
        sys.exit("The Temple rejected the scripture.")

    print("Running the Seven Commands...\n")
    u = v.utter("GaiaEngine64;", timeout=300)
    print(u.text)

    print("Raising the vision (it stays on screen until you stop the Temple)...")
    v.utter("GaiaProject; WinFocus; WinMax; Fs->draw_it = &GaiaDrawIt;",
            timeout=30)
finally:
    v.close()

print("\nThe vision is live in the TempleOS window.")
print("  ./gaia.sh stop    lays the Temple to rest (its disk persists)")
EOF
