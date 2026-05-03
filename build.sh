#!/bin/sh
# Build rsync 3.2.7 natively on SCO OpenServer 5.0.7 with GCC 2.95.3.
#
# Run this script ON the SCO machine, in a writable directory. It will:
#   1. Download rsync-3.2.7.tar.gz from samba.org (or use a local copy)
#   2. Unpack, apply the C89 compatibility patch
#   3. Configure (with all optional deps disabled — they need newer libc)
#   4. Build with native GCC 2.95.3 and gmake
#   5. Strip the resulting `rsync` binary
#
# Output: ./rsync-3.2.7/rsync (about 420 KB stripped)
#
# Required: /usr/gnu/bin/{gcc,gmake,gtar} and /bin/{patch,sed,gunzip}
# Optional: wget or ftp to fetch the tarball; otherwise drop the source
#           tarball next to this script first.

set -e

# Allow this script to live anywhere; resolve relative to its location.
SCRIPT_DIR=$(cd "`dirname \"$0\"`" && pwd)
PATCH="$SCRIPT_DIR/rsync-3.2.7-sco.patch"

VERSION=3.2.7
TARBALL=rsync-${VERSION}.tar.gz
SRCDIR=rsync-${VERSION}

PATH=/usr/gnu/bin:/usr/ccs/bin:$PATH
export PATH

if [ ! -f "$TARBALL" ]; then
    echo "Fetching $TARBALL..."
    if which wget >/dev/null 2>&1; then
        wget --no-check-certificate "https://download.samba.org/pub/rsync/src/$TARBALL"
    elif which curl >/dev/null 2>&1; then
        curl -kLO "https://download.samba.org/pub/rsync/src/$TARBALL"
    else
        echo "ERROR: no wget or curl. Please drop $TARBALL next to this script." >&2
        exit 1
    fi
fi

if [ ! -d "$SRCDIR" ]; then
    echo "Unpacking $TARBALL..."
    gtar xzf "$TARBALL"
fi

echo "Applying SCO compatibility patch..."
cd "$SRCDIR"
if [ -f .sco_patched ]; then
    echo "  (already applied — skipping)"
else
    patch -p1 < "$PATCH"
    touch .sco_patched
fi

echo "Configuring..."
# All optional deps disabled — most depend on libraries SCO doesn't have
# or whose modern versions need a newer libc.
./configure \
  --disable-zstd \
  --disable-lz4 \
  --disable-xxhash \
  --disable-openssl \
  --disable-iconv \
  --disable-iconv-open \
  --disable-acl-support \
  --disable-xattr-support \
  --disable-md2man \
  --disable-locale \
  --disable-ipv6 \
  --with-included-popt \
  --with-included-zlib

# Avoid autoconf re-run during make (the patched files have newer mtimes
# than configure.sh, which would otherwise trigger regeneration with the
# autoconf on SCO that's too old for rsync's configure.ac).
touch configure.sh aclocal.m4 config.h.in config.h Makefile

echo "Compiling..."
gmake

echo "Stripping..."
strip rsync || true

ls -l rsync
echo
echo "Built: $SRCDIR/rsync"
echo "Test it: ./rsync --version"
