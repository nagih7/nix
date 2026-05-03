{
  pkgs ? import <nixpkgs> { },
}:

let
  pname = "coccoc-browser";
  version = "141.0.7390.132-1";

  coccoc-src = pkgs.stdenv.mkDerivation {
    name = "${pname}-source";
    src = pkgs.fetchurl {
      url = "https://browser-linux.coccoc.com/deb/pool/main/coccoc-browser-stable_${version}_amd64.deb";
      sha256 = "0diqr1jvxxmfl32aa8d643b45v8irxjv6hra89ms50bc9c71rsi1";
    };

    nativeBuildInputs = [ pkgs.dpkg ];

    unpackPhase = ''
      dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner
    '';

    installPhase = ''
      mkdir -p $out
      cp -r . $out
    '';
  };

in
pkgs.buildFHSEnv {
  name = "coccoc-browser";

  targetPkgs =
    pkgs: with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      curl
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      gtk4

      # Graphics & Hardware
      libdrm
      libgbm
      libglvnd
      libnotify
      libpulseaudio
      libuuid
      libxkbcommon
      mesa
      nspr
      nss
      pango
      pciutils
      pipewire
      snappy
      systemd
      udev
      vulkan-loader
      wayland
      xdg-utils

      # X11
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      xorg.libxcb
      xorg.libxshmfence

      # Fonts & Misc
      liberation_ttf
      wget
    ];

  multiPkgs =
    pkgs: with pkgs; [
      mesa
      libdrm
      libgbm
    ];

  runScript = ''
    #!${pkgs.bash}/bin/bash
    exec ${coccoc-src}/opt/coccoc/browser/browser \
      --disable-setuid-sandbox \
      --ozone-platform-hint=auto \
      --enable-features=WaylandWindowDecorations \
      "$@"
  '';

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${coccoc-src}/usr/share/applications/coccoc-browser.desktop $out/share/applications/

    substituteInPlace $out/share/applications/coccoc-browser.desktop \
      --replace-fail "/usr/bin/coccoc-browser-stable" "$out/bin/coccoc-browser"

    for size in 16 24 32 48 64 128 256; do
      src_icon="${coccoc-src}/opt/coccoc/browser/product_logo_$size.png"
      if [ -f "$src_icon" ]; then
        mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
        ln -sf "$src_icon" $out/share/icons/hicolor/''${size}x''${size}/apps/coccoc-browser.png
      fi
    done
  '';

  meta = {
    description = "Cốc Cốc Browser (FHS Environment)";
    homepage = "https://coccoc.com";
    license = pkgs.lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
