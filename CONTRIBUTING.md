# How our group works with this repo

## First time
```bash
git clone <repo-url>
cd quantum-sim-vlsi
git config user.name  "Your Name"
git config user.email "you@example.com"
```

## Every working session
```bash
git pull                      # get teammates' latest work FIRST
# ... add / edit your files ...
git add <files you changed>
git commit -m "rtl: add pair address generator"
git push
```

## Simple rules
1. **Pull before you start, pull before you push.** Most conflicts come from skipping this.
2. **Put files in the right folder** (see README). RTL in `rtl/`, testbenches in `tb/`, Python in `python/`.
3. **Name files by role**: `rtl/addr_gen.v`, `rtl/lane.v`, `tb/tb_addr_gen.v`, `python/golden.py`.
4. **Owners**: one person per file at a time. Write who owns what in `docs/ownership.md`.
5. **Commit message format**: `area: what you did` (areas: rtl, tb, python, synth, pnr, docs, scripts).
6. **Do not commit** big generated files (waveforms `.vcd`, `.gds`, tool work directories). `.gitignore` already blocks the common ones. Reports (`.rpt`) are fine and wanted.
7. **Never commit passwords or server details** (Cadence server logins etc.).
8. If your push is rejected: `git pull --rebase`, fix conflicts if any, then `git push`.

## Optional: branches (if two people touch the same area)
```bash
git checkout -b feature/lane-datapath
# work, commit
git push -u origin feature/lane-datapath
# then merge on GitHub via a Pull Request
```

## Pass criteria before merging RTL
- `make sim` passes
- No latches / X states
- Python vs RTL scoreboard matches
