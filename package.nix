{ lib
, writeShellApplication
, opencode
, git
, gh
, glab
, nodejs
, bun
, ripgrep
, fd
, jq
, yq-go
, uv
, python3
, rtk
, graphify
, markitdown
, pandoc
, poppler-utils
, yt-dlp
  # Game-specific values are supplied by the game flake.
, profileName ? "opencode-power-dev"
, configRepo ? "https://github.com/M4jor-Tom/opencode-power-dev.git"
, dirEnvVar ? "OPENCODE_POWER_DEV_DIR"
}:

writeShellApplication {
  name = profileName;

  runtimeInputs = [
    opencode
    git
    gh
    glab
    nodejs
    bun
    ripgrep
    fd
    jq
    yq-go
    uv
    python3
    rtk
    graphify
    markitdown
    pandoc
    poppler-utils
    yt-dlp
  ];

  # The config repo must remain writable for native skill and plugin setup.
  text = ''
    DIR="''${${dirEnvVar}:-$HOME/.${profileName}}"

    if [ ! -e "$DIR" ]; then
      echo "${profileName}: cloning ${configRepo} -> $DIR" >&2
      git clone "${configRepo}" "$DIR"
    elif [ -d "$DIR/.git" ] \
      && [ "$(git -C "$DIR" remote get-url origin 2>/dev/null)" = "${configRepo}" ] \
      && STATUS=$(git -C "$DIR" status --porcelain) \
      && [ -z "$STATUS" ]; then
      # Clean tree, and only a checkout of this profile's own repo. A dirty
      # tree keeps its local edits, always; an unrelated checkout is never
      # touched.
      git -C "$DIR" pull --ff-only --quiet \
        || echo "${profileName}: pull failed, using the local checkout" >&2
    fi

    [ -f "$DIR/scripts/run.sh" ] || { echo "${profileName}: profile entrypoint missing: $DIR/scripts/run.sh" >&2; exit 1; }
    exec bash "$DIR/scripts/run.sh" "$@"
  '';

  meta = {
    description = "OpenCode running the ${profileName} profile";
    homepage = "https://github.com/M4jor-Tom/${profileName}.app";
    mainProgram = profileName;
    platforms = lib.platforms.unix;
  };
}
