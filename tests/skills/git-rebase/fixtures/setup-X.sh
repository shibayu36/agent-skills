#!/usr/bin/env bash
# Fixture for scenario X: stacked rebase + upstream + conflict + all pushed
#
# Layout:
#   main (origin) ─ Add run()
#                    └─ feature-base ─ Add verbose param to run()
#                                       └─ feature-A ─ Implement verbose branch
#                                                       └─ feature-B ─ Adjust log format
#
# Then origin/main is advanced from another clone with a conflicting change
# to run()'s signature. Rebasing feature-B onto origin/main causes a conflict
# at the feature-base layer.
#
# Final state: cwd is the work clone, feature-B checked out, origin fetched.

set -euo pipefail

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/git-rebase-test-X.XXXXXX")
cd "$TEST_DIR"

# bare origin
git init -q -b main --bare origin.git

# main
git clone -q origin.git work
cd work
git config user.email "test@example.com"
git config user.name "Test User"
git config commit.gpgsign false
git config tag.gpgsign false

cat > app.py <<'EOF'
def run():
    print("running")
EOF
git add app.py
git commit -q -m "Add run()"
git push -q origin main

# feature-base: add verbose param
git checkout -q -b feature-base
cat > app.py <<'EOF'
def run(verbose=False):
    print("running")
EOF
git add app.py
git commit -q -m "Add verbose param to run()"
git push -q -u origin feature-base

# feature-A: implement verbose branch
git checkout -q -b feature-A
cat > app.py <<'EOF'
def run(verbose=False):
    if verbose:
        print("[verbose] starting")
    print("running")
EOF
git add app.py
git commit -q -m "Implement verbose branch"
git push -q -u origin feature-A

# feature-B: adjust log format
git checkout -q -b feature-B
cat > app.py <<'EOF'
def run(verbose=False):
    if verbose:
        print("[INFO] starting")
    print("running")
EOF
git add app.py
git commit -q -m "Adjust log format"
git push -q -u origin feature-B

# Advance origin/main from a separate clone (conflict seed at feature-base layer)
cd ..
git clone -q origin.git other
cd other
git config user.email "other@example.com"
git config user.name "Other User"
git config commit.gpgsign false
git config tag.gpgsign false
git checkout -q main
cat > app.py <<'EOF'
def run(name="world"):
    print(f"running for {name}")
EOF
git add app.py
git commit -q -m "Add name parameter to run()"
git push -q origin main

# Return to work clone, fetch, checkout feature-B
cd ../work
git fetch -q origin
git checkout -q feature-B

echo "TEST_DIR=$TEST_DIR"
echo "WORK_DIR=$TEST_DIR/work"
echo
echo "Local branches:"
git branch
echo
echo "Remote branches:"
git branch -r
