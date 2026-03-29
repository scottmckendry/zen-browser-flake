{
  description = "Zen Browser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      version = "1.19.5b";
      download = {
        url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.xz";
        sha256 = "sha256:0x7s0jwgai7vadb0mcwyjvp9pgy93r6n8av9dkxvgas4sk0awsyd";
      };

      pkgs = import nixpkgs {
        inherit system;
      };

      runtimeLibs = with pkgs; [
        alsa-lib
        atk
        cairo
        cups
        dbus
        ffmpeg
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        libGL
        libGLU
        libevent
        libffi
        libglvnd
        libjpeg
        libnotify
        libpng
        libpulseaudio
        libstartup_notification
        libva
        libvpx
        libwebp
        libx11
        libxcb
        libxcomposite
        libxcursor
        libxdamage
        libxext
        libxfixes
        libxi
        libxkbcommon
        libxml2
        libxrandr
        libxscrnsaver
        mesa
        pango
        pciutils
        pipewire
        stdenv.cc.cc
        udev
        xcb-util-cursor
        zlib
      ];

      mkZen = pkgs.stdenv.mkDerivation {
        inherit version;
        pname = "zen-browser";

        src = builtins.fetchTarball {
          url = download.url;
          sha256 = download.sha256;
        };

        desktopSrc = ./.;

        phases = [
          "installPhase"
          "fixupPhase"
        ];

        nativeBuildInputs = [
          pkgs.makeWrapper
          pkgs.copyDesktopItems
          pkgs.wrapGAppsHook3
        ];

        installPhase = ''
          		  mkdir -p $out/bin && cp -r $src/* $out/bin
          		  install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop
          		  install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
          		'';

        fixupPhase = ''
          		  chmod 755 $out/bin/*
          		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen
          		  wrapProgram $out/bin/zen --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
                              --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
          		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen-bin
          		  wrapProgram $out/bin/zen-bin --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
                              --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
          		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/glxtest
          		  wrapProgram $out/bin/glxtest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
          		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/updater
          		  wrapProgram $out/bin/updater --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
          		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/vaapitest
          		  wrapProgram $out/bin/vaapitest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
          		'';

        meta.mainProgram = "zen";
      };
    in
    {
      packages."${system}" = {
        default = mkZen;
      };
    };
}
