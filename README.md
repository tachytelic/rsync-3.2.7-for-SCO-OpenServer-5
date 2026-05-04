# rsync 3.2.7 for SCO OpenServer 5

A working build of [rsync 3.2.7](https://rsync.samba.org/) (October 2022)
for **SCO OpenServer 5.0.7**.

```
$ ./rsync --version
rsync  version 3.2.7  protocol version 31
Copyright (C) 1996-2022 by Andrew Tridgell, Wayne Davison, and others.
```

Just want to run rsync on your SCO box? Skip to **[Install](#install)**.

## Why?

3.2.7 is the most recent rsync that compiles cleanly with the GCC
2.95.3 shipped on SCO, with only a handful of tiny C99→C89
compatibility patches. 3.3.0 and later use enough modern C that
GCC 2.95 can't keep up.

## Install

> **Fresh SCO box?** Install [curl with TLS](https://github.com/tachytelic/curl-7.88.1-for-SCO-OpenServer-5)
> first — that's the only file that needs to be transferred via `scp`/USB.
> After that, every release on tachytelic/* (including this one) fetches
> over HTTPS from GitHub.

Fetch the binary directly on the SCO box and put it on your `PATH`:

```sh
# On the SCO box (assumes curl-with-TLS is installed — see curl-sco):
curl -LO https://github.com/tachytelic/rsync-3.2.7-for-SCO-OpenServer-5/releases/download/v1.0.0/rsync
chmod +x rsync
mv rsync /usr/local/bin/rsync
rsync --version
```

The binary is about 420 KB, dynamically linked against the libraries
that ship on every SCO 5.0.7 install. No other dependencies.

## Try it

```sh
mkdir /tmp/src /tmp/dst
echo hello > /tmp/src/file1
echo world > /tmp/src/file2
./rsync -avh /tmp/src/ /tmp/dst/
diff -r /tmp/src /tmp/dst    # → no output: identical
```

## What works, what doesn't

**Works:**

- Local file synchronization (rsync -av source/ dest/)
- Remote sync over ssh (rsync -avz user@host:path/ ./)
- All standard transfer options: -a, -v, -h, -z, -P, --delete, etc.
- Hard links, symlinks, special files, mtimes
- Daemon mode (rsyncd)
- Socketpairs, atimes, batchfiles, inplace, append, stop-at

**Doesn't work** (compile-time disabled — these need libraries SCO doesn't have):

- ACLs and extended attributes (SCO has no XPG4 ACLs)
- iconv-based --iconv option
- IPv6 (SCO is IPv4-only)
- zstd / lz4 / xxhash (modern compression — use plain `-z` for zlib instead)
- OpenSSL-based MD5 (uses bundled MD5 instead — slightly slower)
- Locale handling (uses C locale always)

## Building from source

You probably don't need to do this — `prebuilt/rsync` is what
`build.sh` produces. But if you want to rebuild (different version,
different config flags), run `build.sh` **on the SCO box itself**.

This is a **native build, not a cross-build**. SCO's runtime loader
hides certain libc symbols (`__stat32`, `__fpstart`, …) from binaries
linked by GNU ld on Linux, which makes cross-compiling complex programs
like rsync impractical. Building natively with the SCO-supplied GCC
2.95.3 sidesteps the entire issue, because the SCO toolchain produces
binaries with the symbol-table layout the loader accepts.

### Requirements

On the SCO machine you'll need:

- `/usr/gnu/bin/gcc` (GCC 2.95.3 — this is what SCO ships)
- `/usr/gnu/bin/gmake`
- `/usr/gnu/bin/gtar`
- `/usr/bin/patch`
- `wget` or `curl` (to fetch the rsync source from samba.org), or you
  can drop the source tarball next to `build.sh` yourself

### Build

```sh
# Copy this whole directory to the SCO box, then:
cd rsync-sco
./build.sh
```

The script downloads `rsync-3.2.7.tar.gz`, applies
`rsync-3.2.7-sco.patch`, runs configure with all optional deps
disabled, builds, and strips. Output is `rsync-3.2.7/rsync`.

### What the patch does

`rsync-3.2.7-sco.patch` is a 1.7 KB unified diff that hoists four
mid-block declarations to the top of their containing functions in
`main.c` and `options.c`. GCC 2.95.3 is strict C89 and rejects C99's
"declarations after statements" rule. That's the entire compatibility
gap — rsync's code is otherwise pleasingly portable.

## Repository layout

```
prebuilt/
  rsync                       Stripped binary, ready to scp to SCO  ← start here

build.sh                      Native-build script (run on SCO)
rsync-3.2.7-sco.patch         C89-compat patch for rsync 3.2.7
```

## License

rsync itself is © Andrew Tridgell, Wayne Davison, and others, distributed
under the GNU GPLv3 — see [the upstream COPYING](https://github.com/RsyncProject/rsync/blob/master/COPYING).
The `rsync-3.2.7-sco.patch` and `build.sh` in this repository are
released under the MIT license — see [LICENSE](LICENSE).

The bundled `prebuilt/rsync` binary is rsync 3.2.7 built with the
included patch and is therefore covered by the GPLv3.

## See also

If you're keeping a SCO OpenServer 5 box alive, head over to
[my SCO OpenServer 5 binaries page](https://tachytelic.net/2017/07/sco-openserver-5-binaries/)
to find other compiled software for the SCO OpenServer (bash, tar,
wget, lzop, …) along with notes on running these systems day to day.
