{
  description = "OpenCode, pre-loaded with the opencode-power-dev profile";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    { self
    , nixpkgs
    , systems
    }:
    let
      inherit (nixpkgs) lib;
      eachSystem = f: lib.foldl' lib.recursiveUpdate { } (map f (import systems));

      overlay = final: prev: {
        opencode-power-dev = final.callPackage ./package.nix { };
      };
    in
    eachSystem
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages.${system} = {
          default = pkgs.opencode-power-dev;
          opencode-power-dev = pkgs.opencode-power-dev;
        };

        apps.${system} = {
          default = {
            type = "app";
            program = "${pkgs.opencode-power-dev}/bin/opencode-power-dev";
            meta.description = "OpenCode running the opencode-power-dev profile";
          };
          opencode-power-dev = {
            type = "app";
            program = "${pkgs.opencode-power-dev}/bin/opencode-power-dev";
            meta.description = "OpenCode running the opencode-power-dev profile";
          };
        };

        devShells.${system}.default = pkgs.mkShell {
          buildInputs = with pkgs; [ nixpkgs-fmt ];
        };
      }) // {
      overlays.default = overlay;
    };
}
