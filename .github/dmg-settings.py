from pathlib import Path

application = defines.get("app", "Kiwix.app")  # noqa: F821
background = defines.get("bg", "bg.png")  # noqa: F821
appname = Path(application).name
# Volume format (see hdiutil create -help)
format = defines.get("format", "ULMO")  # noqa: F821
# Compression level (if relevant)
# compression_level = 9
# Volume size
size = defines.get("size", None)  # noqa: F821
# Files to include
files = [application]
# Symlinks to create
symlinks = {"Applications": "/Applications"}
# Files to hide the extension of
hide_extension = [ "Kiwix.app" ]
# Volume icon (reuse from app)
icon = Path(application).joinpath("Contents/Resources/AppIcon.icns")
# Where to put the icons
icon_locations = {appname: (146, 180), "Applications": (450, 181)}

background = background
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 180

# Window position in ((x, y), (w, h)) format
window_rect = ((200, 120), (600, 360))
default_view = "icon-view"
show_icon_preview = True
# Set these to True to force inclusion of icon/list view settings (otherwise
# we only include settings for the default view)
include_icon_view_settings = True
include_list_view_settings = True
# .. Icon view configuration ...................................................
arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
scroll_position = (0, 0)
label_pos = "bottom"  # or 'right'
text_size = 16
icon_size = 100
