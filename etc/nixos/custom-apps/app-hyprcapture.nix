{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "hyprcapture";
  version = "0.6.0-unstable-2026-11-13";

  src = pkgs.fetchFromGitHub {
    owner = "gfhdhytghd";
    repo = "HyprCapture";
    rev = "56175f3bef3f033fcd2168d7ca1a5db9882abc4e";
    hash = "sha256-ytfpUTq6CN1vMZdaA7tgpKnN+bNjH0no0fV7OG9BOEE=";
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
    libpulseaudio
    pipewire
    fftw
    lua
    glslang
    nlohmann_json
    qt6.qtbase
    qt6.qtwayland
    kdePackages.layer-shell-qt
    ffmpeg
    wl-clipboard
    opencv
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DHYPRCAPTURE_GAINMAP_HEIC=OFF"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/lib
    install -Dm755 hyprcapture-ui $out/bin/hyprcapture-ui
    install -Dm755 libhyprcapture.so $out/lib/libhyprcapture.so
    runHook postInstall
  '';
}
