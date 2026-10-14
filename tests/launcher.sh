#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
NAME=${1:-opencode-power-dev}
case "$NAME" in
  opencode-power-dev) VAR=OPENCODE_POWER_DEV_DIR ;;
  opencode-game-dev) VAR=OPENCODE_GAME_DEV_DIR ;;
  *) echo "Unknown profile: $NAME" >&2; exit 1 ;;
esac
URL="https://github.com/M4jor-Tom/$NAME.git"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/project with spaces"
# Evaluate package.nix's real text; mock only derivation packaging and input attributes.
nix eval --impure --raw --expr "let names = [ \"opencode\" \"pi-coding-agent\" \"git\" \"gh\" \"glab\" \"nodejs\" \"bun\" \"ripgrep\" \"fd\" \"jq\" \"yq-go\" \"uv\" \"python3\" \"rtk\" \"graphify\" \"markitdown\" \"pandoc\" \"poppler-utils\" \"yt-dlp\" ]; inputs = builtins.listToAttrs (map (name: { inherit name; value = null; }) names); in let pkg = import $ROOT/package.nix; in pkg ((builtins.intersectAttrs (builtins.functionArgs pkg) inputs) // { lib.platforms.unix = []; writeShellApplication = x: x.text; profileName = \"$NAME\"; configRepo = \"$URL\"; dirEnvVar = \"$VAR\"; })" > "$WORK/launcher"
cat > "$WORK/bin/git" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$LOG"
if [ "$1" = clone ]; then
  [ "$2" = "$URL" ] || exit 42
  mkdir -p "$3/.git" "$3/scripts"
  cp "$RUN_FIXTURE" "$3/scripts/run.sh"
elif [ "$1" = -C ]; then
  case "$3" in
    remote) printf '%s\n' "${GIT_ORIGIN:-$URL}" ;;
    status) printf '%s' "${GIT_STATUS:-}" ;;
    pull) [ "${GIT_PULL_FAIL:-0}" != 1 ] ;;
    *) exit 43 ;;
  esac
else
  exit 44
fi
EOF
cat > "$WORK/run.sh" <<'EOF'
#!/usr/bin/env bash
{
  printf 'entrypoint\n%s\n' "$PWD"
  printf 'arg:%s\n' "$@"
} > "$CAPTURE"
EOF
cat > "$WORK/bin/pi" <<'EOF'
#!/usr/bin/env bash
echo legacy-pi > "$CAPTURE"
EOF
chmod +x "$WORK/bin/git" "$WORK/bin/pi"
export PATH="$WORK/bin:$PATH" LOG="$WORK/log" URL RUN_FIXTURE="$WORK/run.sh" CAPTURE="$WORK/capture"
DIR="$WORK/profile with spaces"
export "$VAR=$DIR"
cd "$WORK/project with spaces"
run() { : > "$LOG"; rm -f "$CAPTURE"; bash "$WORK/launcher" 'two words' '--version'; }
assert_run() { grep -Fxq entrypoint "$CAPTURE"; grep -Fxq "$PWD" "$CAPTURE"; grep -Fxq 'arg:two words' "$CAPTURE"; grep -Fxq 'arg:--version' "$CAPTURE"; }
run
assert_run
grep -Fxq "clone $URL $DIR" "$LOG"
run
assert_run
grep -Fxq -- "-C $DIR pull --ff-only --quiet" "$LOG"
export GIT_STATUS=dirty
run
assert_run
! grep -q 'pull ' "$LOG"
unset GIT_STATUS
export GIT_ORIGIN='https://example.invalid/foreign.git'
run
assert_run
! grep -q 'pull ' "$LOG"
unset GIT_ORIGIN
export GIT_PULL_FAIL=1
run
assert_run
test -d "$DIR/.git"
grep -Fxq -- "-C $DIR pull --ff-only --quiet" "$LOG"
unset GIT_PULL_FAIL
rm "$DIR/scripts/run.sh"
if run; then echo 'Missing entrypoint was accepted' >&2; exit 1; fi
test -d "$DIR/.git"
printf '%s\n' "$NAME launcher cases passed"
