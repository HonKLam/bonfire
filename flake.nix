{
  description = "Bonfire — a WebGL start page that follows the Noctalia colour scheme";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f nixpkgs.legacyPackages.${system});
    in
    {
      # The static site itself. Just the files, no build step.
      packages = forAllSystems (pkgs: {
        default = self.packages.${pkgs.system}.bonfire;

        bonfire = pkgs.stdenvNoCC.mkDerivation {
          pname = "bonfire";
          version = "0.1.0";
          src = ./.;

          dontBuild = true;
          dontConfigure = true;

          installPhase = ''
            mkdir -p $out
            cp -r index.html style.css main.js shaders $out/
          '';

          meta = with pkgs.lib; {
            description = "WebGL start page themed from Noctalia";
            platforms = platforms.linux;
          };
        };
      });

      # Import this in home-manager: bonfire.homeManagerModules.default
      homeManagerModules.default = import ./module.nix self;

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.nodePackages.live-server ];
          shellHook = ''
            echo "run: live-server --port=8420 --ignore=colors.css"
          '';
        };
      });
    };
}
