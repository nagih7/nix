# ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗██████╗ ██╗   ██╗██╗     ███████╗
# ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║██╔══██╗██║   ██║██║     ██╔════╝
# ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║██║ █╗ ██║██████╔╝██║   ██║██║     █████╗
# ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║██║███╗██║██╔══██╗██║   ██║██║     ██╔══╝
# ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝╚███╔███╔╝██║  ██║╚██████╔╝███████╗███████╗
#  ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝
#------------------------------------------------------------------------------------

{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # ######## Workspace Rules ########
      workspace = [
        "special:special, gapsout:15"
      ];

      # ######## Window Rules V2 ########
      windowrulev2 = [
        # --- Disable Blur ---
        "noblur, class:^$, title:^$"
        # "noblur, class:.*"

        # --- Floating & Center (General) ---
        "float, title:^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|.*wants to save|.*wants to open)$"
        "center, title:^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|.*wants to save|.*wants to open)$"

        # --- Specific Sizes ---
        "size 60% 65%, title:^(Choose wallpaper)$"
        "float, class:^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde)$"
        "size 60% 65%, class:^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde)$"

        # --- System Tools (Pavucontrol, Network, Bluetooth) ---
        "float, class:^(pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|blueberry\\.py|guifetch|bluedevilwizard)$"
        "size 45% 45%, class:^(pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|Zotero)$"
        "center, class:^(pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor)$"
        "float, class:^(Zotero)$"

        # --- KDE Plasma Specifics ---
        "float, class:^(plasma-changeicons|kcm_.*|.*plasmawindowed.*)$"
        "move 999999 999999, class:^(plasma-changeicons)$"
        "noinitialfocus, class:^(plasma-changeicons)$"
        "float, title:^(.*Welcome|illogical-impulse Settings|.*Shell conflicts.*)$"
        "move 40 80, title:^(Copying — Dolphin)$"

        # --- Tiling Overrides ---
        "tile, class:^(dev\\.warp\\.Warp)$"

        # --- Picture-in-Picture (PiP) ---
        "float, title:^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
        "keepaspectratio, title:^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
        "move 73% 72%, title:^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
        "size 25% 25%, title:^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
        "pin, title:^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"

        # --- Tearing & Games ---
        "immediate, title:.*\\.exe"
        "immediate, title:.*minecraft.*"
        "immediate, class:^(steam_app).*"

        # --- Fix Jetbrains IDEs ---
        "noinitialfocus, class:^(jetbrains-.*)$, floating:1, title:^($|^\\s$|^win\\d+$)"

        # --- No shadow for tiled windows ---
        "noshadow, floating:0"

        # --- Force Tile for Browsers ---
        "tile, class:^(brave-browser)$"
        
        "workspace silent,class:^(net.sapples.LiveCaptions)$"
        "pin,class:^(net.sapples.LiveCaptions)$"
        "float, class:^(net.sapples.LiveCaptions)$"
        "noshadow, class:^(net.sapples.LiveCaptions)$"
        "noborder, class:^(net.sapples.LiveCaptions)$"
        "rounding 16, class:^(net.sapples.LiveCaptions)$"
        "opacity 1.0 0.85, class:^(net.sapples.LiveCaptions)$"

        "noinitialfocus, class:^(net.sapples.LiveCaptions)$"
        "stayfocused, class:^$"
      ];

      # ######## Layer Rules ########
      layerrule = [
        # --- General ---
        "xray, .*"
        "noanim, ^(walker|selection|overview|anyrun|indicator.*|osk|hyprpicker|noanim|gtk4-layer-shell)$"
        "blur, ^(logout_dialog)$" # Đã thêm lại cái này

        # --- Blur & Opacity (General) ---
        "blur, ^(gtk-layer-shell|launcher|notifications)$"
        "ignorealpha 0, ^(gtk-layer-shell)$"
        "ignorealpha 0.5, ^(launcher)$"
        "ignorealpha 0.69, ^(notifications)$"

        # --- AGS / Bar / Dock ---
        "blur, ^(session[0-9]*|bar[0-9]*|dock[0-9]*|overview[0-9]*|barcorner.*|cheatsheet[0-9]*|sideright[0-9]*|sideleft[0-9]*|indicator.*|osk[0-9]*)$"
        "ignorealpha 0.6, ^(bar[0-9]*|dock[0-9]*|overview[0-9]*|barcorner.*|cheatsheet[0-9]*|sideright[0-9]*|sideleft[0-9]*|indicator.*|osk[0-9]*)$"

        # --- AGS Animations ---
        "animation slide left, ^(sideleft.*)$"
        "animation slide right, ^(sideright.*)$"

        # ######## Quickshell Rules (Chi tiết từng dòng) ########

        # 1. General Quickshell
        "blurpopups, ^(quickshell:.*)$"
        "blur, ^(quickshell:.*)$"
        "ignorealpha 0.79, ^(quickshell:.*)$"

        # 2. Animations
        "animation slide, ^(quickshell:(bar|verticalBar|reloadPopup))$"
        "animation slide bottom, ^(quickshell:(cheatsheet|dock|osk))$"
        "animation popin 120%, ^(quickshell:screenCorners)$"
        "animation fade, ^(quickshell:notificationPopup)$"
        "animation slide top, ^(quickshell:wallpaperSelector)$"
        "animation slide right, ^(quickshell:sidebarRight)$"
        "animation slide left, ^(quickshell:sidebarLeft)$"

        # 3. No Animations
        "noanim, ^(quickshell:(actionCenter|lockWindowPusher|overlay|overview|polkit|regionSelector|screenshot|wNotificationCenter|wOnScreenDisplay|wStartMenu))$"

        # 4. Special Cases (Alpha & Overlay) - Đây là phần logic phức tạp bro cần
        "noanim, ^(quickshell:session)$"
        "blur, ^(quickshell:session)$"
        "ignorealpha 0, ^(quickshell:session)$" # Cái này quan trọng, set về 0

        "noanim, ^(quickshell:wTaskView)$"
        "ignorealpha 0, ^(quickshell:wTaskView)$" # Cái này cũng về 0

        "ignorealpha 1, ^(quickshell:(overlay|popup|mediaControls))$"
        "xray 0, ^(quickshell:popup)$" # Fix weird color

        # 5. Ordering
        "order -1, ^(quickshell:osk)$"
      ];
    };
  };
}
