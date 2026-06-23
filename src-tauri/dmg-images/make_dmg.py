#!/usr/bin/env python3
"""
make_dmg.py - DMG builder for Graveyard Slide, using dmgbuild as a
library (dmgbuild.build_dmg) rather than its CLI.

Why: the dmgbuild CLI (`dmgbuild -s settings.py ...`) was confirmed to
copy the background image into the DMG correctly, and set Finder's
background mode to "Picture" correctly, but failed to actually link
the image file into that picture setting (Finder showed "Picture"
selected but with no image chosen). Calling dmgbuild.build_dmg()
directly with a settings dict avoids this and is confirmed to work.

Usage:
    python3 make_dmg.py <path-to-app> <output-dmg-path>
"""
import os
import sys

import dmgbuild

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 make_dmg.py <path-to-app> <output-dmg-path>")
        sys.exit(1)

    app_path = os.path.abspath(sys.argv[1])
    output_path = os.path.abspath(sys.argv[2])
    app_name = os.path.basename(app_path)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    background_path = os.path.join(script_dir, "background.png")

    if not os.path.isdir(app_path):
        print(f"Error: app not found at {app_path}")
        sys.exit(1)
    if not os.path.isfile(background_path):
        print(f"Error: background not found at {background_path}")
        sys.exit(1)

    if os.path.exists(output_path):
        os.remove(output_path)

    settings = {
        "files": [app_path],
        "symlinks": {"Applications": "/Applications"},
        "icon_locations": {
            app_name: (180, 220),
            "Applications": (480, 220),
        },
        "background": background_path,
        "window_rect": ((100, 100), (660, 400)),
        "default_view": "icon-view",
        "show_status_bar": False,
        "show_tab_view": False,
        "show_toolbar": False,
        "show_pathbar": False,
        "show_sidebar": False,
        "icon_size": 80,
        "show_icon_preview": True,
        "text_size": 14,
        "format": "UDZO",
        "filesystem": "HFS+",
    }

    dmgbuild.build_dmg(
        filename=output_path,
        volume_name="Graveyard Slide",
        settings=settings,
    )

    print(f"Done: {output_path}")


if __name__ == "__main__":
    main()
