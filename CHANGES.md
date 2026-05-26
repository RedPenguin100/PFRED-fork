# Fork changes (RedPenguin100/PFRED-fork)

Fork of [`pfred/pfred-docker`](https://github.com/pfred/pfred-docker). Upstream no longer
builds (Scientific Linux 6 is EOL and its mirrors are gone; source tarballs moved). These
are the changes that make it build and run in 2026, briefly.

## Dockerfile
- **SL6 repos → obsolete vault.** Upstream SL6 yum repos are dead. Repointed to the Yamagata
  obsolete mirror (`linux2.yz.yamagata-u.ac.jp/.../scientific/obsolete/6.10/`) with
  `gpgcheck=0`/`sslverify=0`, in both the builder and runtime stages.
- **Multi-stage build.** Split into a `builder` stage (compiles numpy 1.4.1, R 2.6.0, rpy
  1.0.2, and the R packages) and a slim `pfredenv` runtime stage that copies only
  `/home/pfred/bin`.
- **`printf` instead of heredoc** for writing the repo file — the legacy Docker builder
  crashes on heredocs.
- **Relocated/pinned source tarballs.** R/numpy/rpy from their archived URLs, and
  `pls`/`randomForest`/`e1071` from CRAN **`/Archive/`** (they leave the live index when
  deprecated); `wget --no-check-certificate` for the old TLS.
- **Added runtime libs** missing from upstream: `java-1.8.0-openjdk`, `libgfortran`, and the
  X/GL/alsa set.

## entrypoint.sh
- **Self-hosted dependencies.** The runtime download (`WEB=`) now points at this fork's
  `v1.0-alpha` release instead of upstream's, so the fork doesn't depend on the upstream
  repo staying alive. Assets are a 1:1 mirror.
- **Bowtie part count.** `BOWTIEL` is `a b c d` (4 parts) to match the actual release assets;
  upstream's `a b c d e` left a 5th `wget` failing on every startup.

## Line endings
- Added `.gitattributes` and normalized CRLF so the shell scripts run under Linux.

## Reproducibility note
The build still pulls from external mirrors (Yamagata vault, CRAN archive, SourceForge), so
a from-scratch rebuild can still rot. The robust artifact is the **already-built, initialized
image** — push it to a registry by digest and pull that, rather than rebuilding.
