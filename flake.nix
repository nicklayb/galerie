{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            permittedInsecurePackages = [
              "dcraw-9.28.0"
            ];
          };
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [ 
              elixir
              erlang_26
              exiftool
              dcraw
              imagemagick
              docker
              direnv
              inotify-tools
              unzip
              gnumake
            ];

            shellHook = ''
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
