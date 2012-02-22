#!/bin/sh

# Chromium launcher

# Authors:
#  Fabien Tassin <fta@sofaraway.org>
# License: GPLv2 or later

APPNAME=chromium
LIBDIR=/usr/lib/chromium
GDB=/usr/bin/gdb
CHROME_SANDBOX=/usr/lib/chrome_sandbox

usage () {
  echo "$APPNAME [-h|--help] [-g|--debug] [options] [URL]"
  echo
  echo "        -g or --debug           Start within $GDB"
  echo "        -h or --help            This help screen"
}

# FFmpeg needs to know where its libs are located
if [ "Z$LD_LIBRARY_PATH" != Z ] ; then
  LD_LIBRARY_PATH=$LIBDIR:$LD_LIBRARY_PATH
else
  LD_LIBRARY_PATH=$LIBDIR
fi
export LD_LIBRARY_PATH

# xdg-settings should in PATH
PATH=$PATH:$LIBDIR
export PATH

want_debug=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help | -help )
      usage
      exit 0 ;;
    -g | --debug )
      want_debug=1
      shift ;;
    -- ) # Stop option prcessing
      shift
      break ;;
    * )
      break ;;
  esac
done

# Setup the default profile if this is none
# Set the default theme as GTK+ with system window decoration
if [ ! -d ~/.config/chromium/Default ]; then
    mkdir -p ~/.config/chromium/Default
    cat <<EOF > ~/.config/chromium/Default/Preferences
{
   "browser": {
      "custom_chrome_frame": false
   },
   "extensions": {
      "theme": {
         "colors": {

         },
         "id": "",
         "images": {

         },
         "properties": {

         },
         "tints": {

         },
         "use_system": true
      }
   },
   "homepage": "http://russianfedora.ru/",
   "homepage_is_newtabpage": false,
   "session": {
      "restore_on_startup": 1
   },
   "webkit": {
      "webprefs": {
         "default_fixed_font_size": 13,
         "default_font_size": 16,
         "fixed_font_family": "Droid Sans Mono",
         "sansserif_font_family": "Droid Sans",
         "serif_font_family": "Droid Serif"
      }
   }
}
EOF
fi

if [ ! -u $CHROME_SANDBOX ] ; then
 SANDBOX="--no-sandbox"
fi
  

if [ $want_debug -eq 1 ] ; then
  if [ ! -x $GDB ] ; then
    echo "Sorry, can't find usable $GDB. Please install it."
    exit 1
  fi
  tmpfile=`mktemp /tmp/chromiumargs.XXXXXX` || { echo "Cannot create temporary file" >&2; exit 1; }
  trap " [ -f \"$tmpfile\" ] && /bin/rm -f -- \"$tmpfile\"" 0 1 2 3 13 15
  echo "set args ${1+"$@"}" > $tmpfile
  echo "# Env:"
  echo "#     LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
  echo "$GDB $LIBDIR/$APPNAME -x $tmpfile"
  $GDB "$LIBDIR/$APPNAME" -x $tmpfile
  exit $?
else
  exec $LIBDIR/$APPNAME $SANDBOX "--enable-experimental-extension-apis" "--enable-plugins" "--enable-extensions" "--enable-user-scripts" "--enable-printing" "--enable-sync" "--auto-ssl-client-auth" "$@"
fi

