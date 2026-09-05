{ pkgs, end-4-dots }:

# Build customized quickshell config by merging upstream with our patches
pkgs.runCommand "quickshell-config" { } ''
    # Copy base config from upstream GitHub repo
    cp -r ${end-4-dots}/dots/.config/quickshell $out
    chmod -R u+w $out

    # === PATCH SCRIPTS FOR NIXOS ===
    
    # 1. Fix GSettings and Theme paths for switchwall.sh (NixOS-safe approach)
    sed -i '2i export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.papirus-icon-theme}/share:${pkgs.catppuccin-gtk}/share:${pkgs.kdePackages.kio}/share:${pkgs.kdePackages.kservice}/share:${pkgs.kdePackages.ki18n}/share:$XDG_DATA_DIRS' $out/ii/scripts/colors/switchwall.sh
    sed -i '3i export PATH=${pkgs.kdePackages.kdialog}/bin:${pkgs.xdg-user-dirs}/bin:${pkgs.zenity}/bin:$PATH' $out/ii/scripts/colors/switchwall.sh
    sed -i '4i export QT_QPA_PLATFORMTHEME=kde\nexport KDE_SESSION_VERSION=6' $out/ii/scripts/colors/switchwall.sh
    
    # 2. Add --source-color-index 0 to matugen image calls.
    #    matugen 4.x shows an interactive color picker when given an image and
    #    no source-color-index; without a tty it fails with "IO error: not a
    #    terminal". Index 0 (dominant color) auto-selects without interaction.
    sed -i 's|matugen_args+=(image "\$imgpath")|matugen_args+=(image "\$imgpath" --source-color-index 0)|g' $out/ii/scripts/colors/switchwall.sh
    sed -i 's|matugen_args+=(image "\$thumbnail")|matugen_args+=(image "\$thumbnail" --source-color-index 0)|g' $out/ii/scripts/colors/switchwall.sh

    # 3a. Rewrite scheme_for_image.py to use Pillow+NumPy instead of cv2
    # (cv2/opencv is not available on NixOS without extra setup, but Pillow
    # and NumPy are already in PYTHONPATH from the session environment).
    cat > $out/ii/scripts/colors/scheme_for_image.py << 'PYEOF'
#!/usr/bin/env python3
# Rewritten for NixOS: uses PIL (available in PYTHONPATH) instead of cv2.
# numpy has a glibc version mismatch with the venv Python, so pure-Python
# statistics are used for the Hasler-Süsstrunk colorfulness metric.
import sys
import math
import statistics
from PIL import Image

def image_colorfulness(img):
    pixels = list(img.getdata())
    rg = [abs(r - g)             for r, g, b in pixels]
    yb = [abs(0.5*(r + g) - b)  for r, g, b in pixels]
    n = len(pixels)
    mean_rg = sum(rg) / n
    mean_yb = sum(yb) / n
    std_rg  = statistics.pstdev(rg)
    std_yb  = statistics.pstdev(yb)
    return math.sqrt(std_rg**2 + std_yb**2) + 0.3 * math.sqrt(mean_rg**2 + mean_yb**2)

def pick_scheme(colorfulness):
    return "scheme-neutral" if colorfulness < 40 else "scheme-tonal-spot"

def load_and_resize_image(img_path, max_dim=128):
    try:
        img = Image.open(img_path).convert("RGB")
    except Exception:
        return None
    w, h = img.size
    if max(w, h) > max_dim:
        scale = max_dim / max(w, h)
        img = img.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.LANCZOS)
    return img

def main():
    colorfulness_mode = False
    args = sys.argv[1:]
    if "--colorfulness" in args:
        colorfulness_mode = True
        args.remove("--colorfulness")
    if len(args) < 1:
        print("scheme-tonal-spot")
        sys.exit(1)
    img = load_and_resize_image(args[0])
    if img is None:
        print("scheme-tonal-spot")
        sys.exit(1)
    colorfulness = image_colorfulness(img)
    if colorfulness_mode:
        print(f"{colorfulness}")
    else:
        print(pick_scheme(colorfulness))

if __name__ == "__main__":
    main()
PYEOF

    # 3. Fix kill usage in applycolor.sh
    sed -i 's/kill -SIGUSR1 $(pidof kitty)/pkill -SIGUSR1 kitty || true/g' $out/ii/scripts/colors/applycolor.sh
    
    # 4. Silence Python warnings in generate_colors_material.py
    sed -i '1i import warnings; warnings.filterwarnings("ignore")' $out/ii/scripts/colors/generate_colors_material.py

    # Create symlink qs -> . inside ii to allow resolving qs.* modules
    # This enables 'qs.*' imports to work correctly
    ln -s . $out/ii/qs
    
    # === OVERLAY QMLDIR FILES ===
    # Generate qmldir files for proper QML module resolution
    
    # Modules qmldir - defines all available modules
    cat > $out/ii/modules/qmldir << 'EOF'
  module qs.modules

  # Common modules
  common 1.0 common/
  crosshair 1.0 crosshair/

  # II-specific modules  
  ii.background 1.0 background/
  ii.bar 1.0 bar/
  ii.cheatsheet 1.0 cheatsheet/
  ii.dock 1.0 dock/
  ii.lock 1.0 lock/
  ii.mediaControls 1.0 mediaControls/
  ii.notificationPopup 1.0 notificationPopup/
  ii.onScreenDisplay 1.0 onScreenDisplay/
  ii.onScreenKeyboard 1.0 onScreenKeyboard/
  ii.overlay 1.0 overlay/
  ii.overview 1.0 overview/
  ii.polkit 1.0 polkit/
  ii.regionSelector 1.0 regionSelector/
  ii.screenCorners 1.0 screenCorners/
  ii.sessionScreen 1.0 sessionScreen/
  ii.sidebarLeft 1.0 sidebarLeft/
  ii.sidebarRight 1.0 sidebarRight/
  ii.verticalBar 1.0 verticalBar/
  ii.wallpaperSelector 1.0 wallpaperSelector/
EOF

    # Services qmldir - defines all singleton services
    cat > $out/ii/services/qmldir << 'EOF'
  module qs.services

  # Singleton services (files with pragma Singleton)
  singleton Ai 1.0 Ai.qml
  singleton AppSearch 1.0 AppSearch.qml
  singleton Audio 1.0 Audio.qml
  singleton Battery 1.0 Battery.qml
  singleton BluetoothStatus 1.0 BluetoothStatus.qml
  singleton Booru 1.0 Booru.qml
  singleton Brightness 1.0 Brightness.qml
  singleton Cliphist 1.0 Cliphist.qml
  singleton ConflictKiller 1.0 ConflictKiller.qml
  singleton DateTime 1.0 DateTime.qml
  singleton EasyEffects 1.0 EasyEffects.qml
  singleton Emojis 1.0 Emojis.qml
  singleton FirstRunExperience 1.0 FirstRunExperience.qml
  singleton GlobalFocusGrab 1.0 GlobalFocusGrab.qml
  singleton HyprlandData 1.0 HyprlandData.qml
  singleton HyprlandKeybinds 1.0 HyprlandKeybinds.qml
  singleton HyprlandXkb 1.0 HyprlandXkb.qml
  singleton Hyprsunset 1.0 Hyprsunset.qml
  singleton Idle 1.0 Idle.qml
  singleton KeyringStorage 1.0 KeyringStorage.qml
  singleton LatexRenderer 1.0 LatexRenderer.qml
  singleton LauncherApps 1.0 LauncherApps.qml
  singleton LauncherSearch 1.0 LauncherSearch.qml
  singleton MaterialThemeLoader 1.0 MaterialThemeLoader.qml
  singleton MprisController 1.0 MprisController.qml
  singleton Network 1.0 Network.qml
  singleton Notifications 1.0 Notifications.qml
  singleton PolkitService 1.0 PolkitService.qml
  singleton Privacy 1.0 Privacy.qml
  singleton ResourceUsage 1.0 ResourceUsage.qml
  singleton SessionWarnings 1.0 SessionWarnings.qml
  singleton SettingsLauncher 1.0 SettingsLauncher.qml
  singleton SongRec 1.0 SongRec.qml
  singleton SystemInfo 1.0 SystemInfo.qml
  singleton TaskbarApps 1.0 TaskbarApps.qml
  singleton TimerService 1.0 TimerService.qml
  singleton Todo 1.0 Todo.qml
  singleton Translation 1.0 Translation.qml
  singleton TrayService 1.0 TrayService.qml
  singleton Updates 1.0 Updates.qml
  singleton Wallpapers 1.0 Wallpapers.qml
  singleton Weather 1.0 Weather.qml
  singleton Ydotool 1.0 Ydotool.qml
  singleton GoogleCloud 1.0 GoogleCloud.qml
  singleton HyprlandAntiFlashbangShader 1.0 HyprlandAntiFlashbangShader.qml
  singleton HyprlandConfig 1.0 HyprlandConfig.qml

  # Non-singleton types
  BooruResponseData 1.0 BooruResponseData.qml
EOF

    # Shapes qmldir - for material design shapes module
    if [ -d "$out/ii/modules/common/widgets/shapes" ]; then
      cat > $out/ii/modules/common/widgets/shapes/qmldir << 'EOF'
  module qs.modules.common.widgets.shapes
  ShapeCanvas 1.0 ShapeCanvas.qml

  # Subdirectories
  geometry 1.0 geometry/
  graphics 1.0 graphics/
  shapes 1.0 shapes/
EOF
    fi

    # === PATCH SHELL.QML ===
    # Disable WaffleFamily (requires Kirigami which is not available in Qt6)
    cat > $out/ii/shell.qml << 'SHELLEOF'
  //@ pragma UseQApplication
  //@ pragma Env QS_NO_RELOAD_POPUP=1
  //@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
  //@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

  // Remove two slashes below and adjust the value to change the UI scale
  ////@ pragma Env QT_SCALE_FACTOR=1

  import "modules/common"
  import "services"
  import "panelFamilies"

  import QtQuick
  import QtQuick.Window
  import Quickshell
  import Quickshell.Io
  import Quickshell.Hyprland

  ShellRoot {
      id: root

      // Stuff for every panel family
      ReloadPopup {}

      Component.onCompleted: {
          MaterialThemeLoader.reapplyTheme()
          Hyprsunset.load()
          FirstRunExperience.load()
          ConflictKiller.load()
          Cliphist.refresh()
          Wallpapers.load()
          Updates.load()
      }


      // Panel families - Only load IllogicalImpulseFamily (WaffleFamily disabled due to missing Kirigami)
      property list<string> families: ["ii"]
      function cyclePanelFamily() {
          // Only one family available
          Config.options.panelFamily = "ii"
      }

      component PanelFamilyLoader: LazyLoader {
          required property string identifier
          property bool extraCondition: true
          active: Config.ready && Config.options.panelFamily === identifier && extraCondition
      }
      
      PanelFamilyLoader {
          identifier: "ii"
          component: IllogicalImpulseFamily {}
      }

      // WaffleFamily disabled: requires org.kde.kirigami which is not available in Qt6
  }
SHELLEOF

    # === CREATE SETTINGS LAUNCHER SERVICE ===
    cat > $out/ii/services/SettingsLauncher.qml << 'SERVICEEOF'
  pragma Singleton
  import QtQuick
  import Quickshell

  QtObject {
      function openSettings() {
          Quickshell.execDetached(["env", "-u", "QS_CONFIG_NAME", "quickshell", "--path", Quickshell.shellPath("settings.qml")]);
      }
  }
SERVICEEOF

    # === PATCH FILES TO USE SETTINGS LAUNCHER ===
    # Patch SidebarRightContent.qml to use SettingsLauncher instead of direct qs call
    if [ -f "$out/ii/modules/ii/sidebarRight/SidebarRightContent.qml" ]; then
      sed -i 's|Quickshell\.execDetached(\["qs", "-p", root\.settingsQmlPath\])|SettingsLauncher.openSettings()|g' \
        "$out/ii/modules/ii/sidebarRight/SidebarRightContent.qml"
    fi

    # === ROUTE APP LAUNCHES THROUGH UWSM ===
    # DesktopEntry.execute() (quickshell's own built-in launcher) spawns the
    # app as a direct child of quickshell itself, landing it in quickshell's
    # own cgroup instead of a proper per-app systemd scope. Apps launched
    # this way (search results, dock icons) can't be identified correctly by
    # xdg-desktop-portal's caller-verification, so any portal call they make
    # (e.g. FileChooser/OpenURI for "open containing folder") silently fails
    # — apps launched via Hyprland's own exec dispatcher (keybinds) or a
    # terminal aren't affected, since those get scoped correctly. `uwsm app
    # --` accepts a desktop-entry id directly and launches it in its own
    # scope, matching the working cases.
    if [ -f "$out/ii/modules/ii/dock/DockAppButton.qml" ]; then
      ${pkgs.perl}/bin/perl -i -pe \
        's/root\.desktopEntry\?\.execute\(\);/if (root.desktopEntry?.id !== undefined) { Quickshell.execDetached(["uwsm", "app", "--", root.desktopEntry.id]); } else { root.desktopEntry?.execute(); }/g' \
        "$out/ii/modules/ii/dock/DockAppButton.qml"
    fi

    if [ -f "$out/ii/modules/ii/overview/SearchItem.qml" ]; then
      ${pkgs.perl}/bin/perl -i -pe \
        's/onClicked: modelData\.execute\(\)/onClicked: { if (modelData.id !== undefined) { Quickshell.execDetached(["uwsm", "app", "--", modelData.id]); } else { modelData.execute(); } }/' \
        "$out/ii/modules/ii/overview/SearchItem.qml"
    fi
''
