{ pkgs ? import <nixpkgs> { } }:

let
  version = "1.0.0-nightly.20261113.90";

  src = pkgs.fetchFromGitHub {
    owner = "ViceVerse-cz";
    repo = "Serein";
    rev = "v1.0.0-nightly.20261113.90";
    hash = "sha256-N+fcKq9ZKN5JjZ6eBnHXD0xE3Wdq8p1p9rmHiik9qxs=";
  };

  serein = pkgs.callPackage "${src}/packaging/nix/package.nix" { };
in
serein.overrideAttrs (_: {
  pname = "serein-discord";
  inherit src;
  inherit version;
})
