{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [ 
    elixir_1_16
    erlang_26
    exiftool
    dcraw
    imagemagick
    docker
    direnv
    inotify-tools
    unzip
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
}
