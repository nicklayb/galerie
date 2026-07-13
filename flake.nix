{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.permittedInsecurePackages = [
            "dcraw-9.28.0"
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            beam29Packages.elixir_1_20
            beam29Packages.erlang
            exiftool
            dcraw
            imagemagick
            docker
            direnv
            inotify-tools
            unzip
            gnumake
            just
            nodejs_22
          ];

          shellHook = ''
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex
            docker compose up -d
            eval "$(direnv hook bash)"
            direnv allow
            mix deps.get
          '';
          permittedInsecurePackages = [
            "dcraw-9.28.0"
          ];

        };
      }
    );
}
