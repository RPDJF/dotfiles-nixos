{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "hyprcapture";
  version = "0.2.7";

  src = pkgs.fetchFromGitHub {
    owner = "gfhdhytghd";
    repo = "HyprCapture";
    rev = "b074739";
    sha256 = "sha256-Ua7Kfq1bKVJXMAM2NJtPYtabhUe7uj7+CKg+fHg/0pc=";
  };

  nativeBuildInputs = with pkgs; [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = with pkgs; [
    hyprland
    aquamarine
    hyprcursor
    hyprgraphics
    hyprlang
    hyprutils
    cairo
    libinput
    libxcb-errors
    lua
    glslang
    nlohmann_json
    qt6.qtbase
    qt6.qtwayland
    kdePackages.layer-shell-qt
    ffmpeg
    wl-clipboard
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/lib
    install -Dm755 hyprcapture-ui $out/bin/hyprcapture-ui
    install -Dm755 libhyprcapture.so $out/lib/libhyprcapture.so
    runHook postInstall
  '';
}