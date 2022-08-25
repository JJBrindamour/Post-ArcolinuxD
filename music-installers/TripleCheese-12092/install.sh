#! /bin/bash -e

# change to the script directory
cd $(dirname "$0")

# initialization
PRODUCT="TripleCheese"
if test -t 0 -a -t 1; then
    INTERACTIF=1
else
    INTERACTIF=0
fi
AS_ROOT=0
QUIET=0
VSTDIR="$HOME/.vst/u-he"
VST3DIR="$HOME/.vst3/u-he"
CLAPDIR="$HOME/.clap/u-he"
WITH_32=0
ARCH=$(uname -m)
NO_PRESETS=0

DIALOG=$PRODUCT/dialog

usage() {
    echo "usage: ./install.sh <options>..."
    echo -e "  --quiet        agree the license and install without asking questions"
    echo -e "  --vstdir=<path>    specify the vst directory. Default: $VSTDIR"
    echo -e "  --vst3dir=<path>   specify the vst directory. Default: $VST3DIR"
    echo -e "  --as-root          lets you run this script as root. You have to know what you're doing."
    if test $ARCH = x86_64; then
        echo -e "  --without-32         do not install 32bit version"
    fi
    exit
}

# parse arguments
until test $# -eq 0; do
    case "$1" in
    --quiet)
        QUIET=1
        ;;
    --vstdir=*)
        VSTDIR="${1/--vstdir=/}"
        VSTDIR="$(eval echo $VSTDIR)"
        ;;
    --vst3dir=*)
        VST3DIR="${1/--vst3dir=/}"
        VST3DIR="$(eval echo $VST3DIR)"
        ;;
    --help | -h)
        usage
        ;;
    --as-root)
        AS_ROOT=1
        ;;
    --with-32)
        WITH_32=1
        ;;
    --without-32)
        WITH_32=0
        ;;
    --no-presets)
        NO_PRESETS=1
        ;;
    --with-clap)
        WITH_CLAP=1
        ;;
    *)
        echo wrong argument "$1"
        usage
        ;;
    esac
    shift
done

# prevent root install
if test "$(whoami)" = root -a "$AS_ROOT" -eq 0; then
    if test "$INTERACTIF" -eq 1; then
        echo Please do not install as root.
    else
        "$DIALOG" message 'Installation error' 'Please do not install as root.' OK
    fi
    exit 1
fi

if ! "$DIALOG" true; then
    echo Please install missing libraries:
    ldd "$DIALOG"
    exit 1
fi

if test $QUIET -eq 0 -a -r "$PRODUCT/license.txt"; then
    if test $INTERACTIF -eq 1; then
        cat "$PRODUCT/license.txt"
        echo
        echo --------------------------------------------
        echo
        while true; do
            echo -n "Do you agree the license's terms? [y/n] "
            read answer
            case "$answer" in
            y | Y | yes | YES | Yes) break ;;
            n | N | no | NO | No) exit ;;
            esac
        done
    else
        answer=$("$DIALOG" license "$PRODUCT/license.txt")
        if test "$answer" != "yes"; then
            $DIALOG message "Installation aborted" "Installation aborted." OK
            exit
        fi
    fi
fi

if test "$NO_PRESETS" -eq 1; then
    find "$PRODUCT/Presets/$PRODUCT/" \
        \( -type f -a -iname '*.h2p' -a -not -iname 'initialize.h2p' -a -delete \) \
        -o \( -empty -a -delete \)
fi

mkdir -p "$HOME/.u-he/"
cp -R "$PRODUCT" "$HOME/.u-he/"
# cp LinuxChangeLog.txt "$HOME/.u-he/$PRODUCT/"

# symlink VST and VST3
mkdir -p "$VSTDIR"
mkdir -p "$VST3DIR/$PRODUCT.vst3/Contents/x86_64-linux/"
mkdir -p "$VST3DIR/$PRODUCT.vst3/Contents/i686-linux/"
mkdir -p "$VST3DIR/$PRODUCT.vst3/Contents/Resources/Documentation/"

ln -sf "$HOME/.u-he/$PRODUCT/"*.pdf "$VST3DIR/$PRODUCT.vst3/Contents/Resources/Documentation/"

if test $(uname -m) = x86_64; then
    ln -sf "$HOME/.u-he/$PRODUCT/$PRODUCT.64.so" "$VSTDIR/$PRODUCT.64.so"
    ln -sf "$HOME/.u-he/$PRODUCT/$PRODUCT.64.so" "$VST3DIR/$PRODUCT.vst3/Contents/x86_64-linux/$PRODUCT.so"

    # we don't do the avx build anymore..., let's cleanup the old things
    rm -f "$HOME/.u-he/$PRODUCT/$PRODUCT.64.avx.so"

    if test $WITH_32 = 1; then
        ln -sf "$HOME/.u-he/$PRODUCT/$PRODUCT.32.so" "$VSTDIR/$PRODUCT.32.so"
        ln -sf "$HOME/.u-he/$PRODUCT/$PRODUCT.32.so" "$VST3DIR/$PRODUCT.vst3/Contents/i686-linux/$PRODUCT.so"
    fi
else
    ln -sf "$HOME/.u-he/$PRODUCT/$PRODUCT.32.so" "$VSTDIR/$PRODUCT.32.so"
    ln -sf "$HOME/.u-he/$PRODUCT/$PRODUCT.32.so" "$VST3DIR/$PRODUCT.vst3/Contents/i686-linux/$PRODUCT.so"
fi

if test "$PRODUCT" = "ZebraHZ"; then
    ln -snf "$HOME/.u-he/Zebra2/Presets/Zebra2" "$HOME/.u-he/ZebraHZ/Presets/ZebraHZ/Zebra2"
fi

if [[ "$WITH_CLAP" = 1 ]]; then
    mkdir -p "$CLAPDIR"
    ln -sf "$HOME/.u-he/$PRODUCT/$PRODUCT.64.so" "$CLAPDIR/$PRODUCT.64.clap"
fi

cat <<EOF >"$HOME/.u-he/$PRODUCT/README-Linux.txt"
Dependencies
------------

You need xdg-open and trash-put to be in /usr/bin/.

Keyboard Modifiers
------------------

In certain cases, Alt+click will not be available to the plugin.
If you notice this happening, please try AtlGr+click instead.

How to uninstall
----------------

To uninstall simply remove the following files/folders:
$HOME/.u-he/$PRODUCT
$VSTDIR/$PRODUCT.*.so
$VST3DIR/$PRODUCT.vst3

Be sure to back up all your presets before removing any files!

Extra configuration
-------------------

# configure the realtime priority of the thread pool using the following environment variable:
export UHE_RT_PRIO=64

Troubleshouting
---------------

If you have an issue maybe your solution is somewhere on KVR:
https://www.kvraudio.com/forum/viewtopic.php?f=31&t=424953

 - Menu and dialogs are not shown
   -> Known issue under Gnome / Wayland
   -> Known issue under the MIR display server
   -> Try exporting GDK_BACKEND=x11, see https://www.kvraudio.com/forum/viewtopic.php?p=6998254#p6998254
EOF

if test $QUIET -eq 0; then
    if test $INTERACTIF -eq 0; then
        $DIALOG message "Installation succeed" "Installation succeed." OK
    else
        cat <<EOF

${PRODUCT}'s data were installed to ${HOME}/.u-he/${PRODUCT}
The VST has been installed in: ${VSTDIR}
The VST3 has been installed in: ${VST3DIR}/${PRODUCT}.vst3

Have fun with ${PRODUCT} and thank you for installing u-he software!
EOF
    fi
fi
