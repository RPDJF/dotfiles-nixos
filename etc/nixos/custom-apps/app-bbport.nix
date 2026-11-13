{ pkgs ? import <nixpkgs> {} }:

let
  libdecor = pkgs.libdecor.overrideAttrs (old: {
    buildInputs = pkgs.lib.remove pkgs.gtk3 old.buildInputs;
    mesonFlags = old.mesonFlags ++ [ "-Dgtk=disabled" ];
  });

  sdl3 = pkgs.sdl3.override {
    inherit libdecor;
    zenity = pkgs.writeShellScriptBin "zenity" ''
      host=$(command -v zenity) && exec "$host" "$@"
      exit 1
    '';
  };

  # Official NVIDIA DLSS SDK repository checkout from GitHub with the verified hash
  dlssSdk = pkgs.fetchFromGitHub {
    owner = "NVIDIA";
    repo = "DLSS";
    rev = "v310.9.1";
    hash = "sha256-ObQldo66x8fEbRWn2B/YyA/++6aIO8+Z2xnwSieRkUM=";
  };
in
pkgs.stdenv.mkDerivation rec {
  pname = "bbport";
  version = "0.51";

  src = pkgs.fetchFromGitHub {
    owner = "deadinside28";
    repo = "bloodborne_pc";
    rev = "0.51";
    hash = "sha256-s9+8z58OABSLLgJjBe07cjFTbjZuMS2p5eZ2H8t5gKA=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
    gcc
    git
    pkg-config
    python3
    glslang
    spirv-cross
    makeWrapper
    copyDesktopItems
    unzip
    mesa
    libdrm
  ];

  buildInputs = with pkgs; [
    sdl3
    vulkan-headers
    vulkan-loader
    alsa-lib
    libpulseaudio
    libX11
    libXext
    libXcursor
    libXfixes
    libXi
    libxrender
    libxrandr
    libxscrnsaver
    libXtst
    libdrm
    mesa
    libXau
    libjack2
    libXdmcp
    ffmpeg-headless
    boost
    fmt
    magic-enum
    robin-map
    xxhash
    vulkan-memory-allocator
    xbyak
    zydis
    spirv-headers
    miniz
    libxcb
    xorgproto
    wayland
    libxkbcommon
    protobuf
    nlohmann_json
    openssl
    zlib
    pipewire
    python3Packages.python
  ];

  dontConfigure = true;
  dontFixup = true;

buildPhase = ''
    runHook preBuild

    export PKG_CONFIG_PATH="${pkgs.mesa}/lib/pkgconfig:${pkgs.libdrm}/lib/pkgconfig:$PKG_CONFIG_PATH"
    export DLSS_SDK_ROOT="${dlssSdk}"

    if [ -f "build.sh" ]; then
      patchShebangs build.sh
      bash build.sh
    else
      echo "Error: build.sh not found."
      exit 1
    fi

    mkdir -p out/gpu out/dlss
    find build -name "libbbgpu.so" -exec cp {} out/gpu/ \; 2>/dev/null || true
    find build -name "libbbport_dlss.so" -exec cp {} out/gpu/ \; 2>/dev/null || true
    find . -name "libbbport_dlss.so" -exec cp {} out/gpu/ \; 2>/dev/null || true
    find build -name "bb-probe" -exec cp {} out/ \; 2>/dev/null || true

    # Automatically copy NVIDIA's runtime NGX library into both out/ and out/dlss/
    find "${dlssSdk}" -name "libnvidia-ngx-dlss.so*" -exec cp {} out/ \; 2>/dev/null || true
    find "${dlssSdk}" -name "libnvidia-ngx-dlss.so*" -exec cp {} out/dlss/ \; 2>/dev/null || true

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/bbport/bin
    cp -r out scripts patches docs tools launcher run.sh $out/opt/bbport/ 2>/dev/null || true
    
    if [ -f "$out/opt/bbport/out/bb-probe" ]; then
        ln -s ../out/bb-probe $out/opt/bbport/bin/bb-probe
    fi

    mkdir -p $out/bin

    cat << 'EOF' > $out/bin/bbport-launcher.sh
    #!/usr/bin/env bash
    set -euo pipefail

    WRITABLE_DIR="$HOME/.local/share/bbport"
    STATIC_DIR="@out@/opt/bbport"

    mkdir -p "$WRITABLE_DIR"
    for item in out scripts patches docs tools launcher run.sh bin dlss; do
        if [ -e "$STATIC_DIR/$item" ] && [ ! -e "$WRITABLE_DIR/$item" ]; then
            cp -r "$STATIC_DIR/$item" "$WRITABLE_DIR/"
        fi
    done

    chmod -R +w "$WRITABLE_DIR"
    [ -f "$WRITABLE_DIR/run.sh" ] && chmod +x "$WRITABLE_DIR/run.sh"
    find "$WRITABLE_DIR/tools" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
    find "$WRITABLE_DIR/bin" -type f -exec chmod +x {} + 2>/dev/null || true

    export BB_DATA_DIR="$WRITABLE_DIR"
    cd "$WRITABLE_DIR"
    if [ -f "./run.sh" ]; then
        exec ./run.sh "$@"
    else
        exec bb-probe "$@"
    fi
    EOF

    substituteAllInPlace $out/bin/bbport-launcher.sh
    chmod +x $out/bin/bbport-launcher.sh

    local libPath="${pkgs.lib.makeLibraryPath [
      pkgs.vulkan-loader
      pkgs.libglvnd
      pkgs.mesa
      pkgs.sdl3
      pkgs.libpulseaudio
      pkgs.wayland
      pkgs.libxkbcommon
      pkgs.libX11
      pkgs.libXext
      pkgs.libXcursor
      pkgs.libXfixes
      pkgs.libXi
      pkgs.libxrender
      pkgs.libxrandr
      pkgs.libxscrnsaver
      pkgs.libXtst
      pkgs.libdrm
      pkgs.mesa
      pkgs.libXau
      pkgs.libjack2
      pkgs.libXdmcp
      pkgs.openssl
      pkgs.zlib
      pkgs.pipewire
    ]}"

    makeWrapper $out/bin/bbport-launcher.sh $out/bin/bbport-run \
      --prefix LD_LIBRARY_PATH : "$libPath:$out/opt/bbport/out/gpu:$out/opt/bbport/out" \
      --set BB_PREBUILT "1"

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Native Linux port for Bloodborne (PS4) optimized for NixOS with DLSS support";
    homepage = "https://github.com/deadinside28/bloodborne_pc";
    license = licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "bbport-run";
  };
}