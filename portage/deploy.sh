#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)/"
GENTOO_HOST=$(hostname)
PORTAGE="/etc/portage"

if [[ ! -d "$REPO_DIR/hosts/$GENTOO_HOST" ]]; then
    echo "Error: no config found for host '$GENTOO_HOST' in $REPO_DIR/hosts/" >&2
    exit 1
fi

echo "Deploying portage config for host: $GENTOO_HOST"

# Remove any existing symlinks/files we're about to replace
# but leave anything we don't manage untouched
for target in \
    "$PORTAGE/package.use/base" \
    "$PORTAGE/package.use/host" \
    "$PORTAGE/package.accept_keywords/base" \
    "$PORTAGE/package.accept_keywords/host" \
    "$PORTAGE/package.mask/base" \
    "$PORTAGE/package.mask/host" \
    "$PORTAGE/package.env/base" \
    "$PORTAGE/package.env/host" \
    "$PORTAGE/env/base" \
    "$PORTAGE/env/host" \
    "$PORTAGE/savedconfig/base" \
    "$PORTAGE/savedconfig/host" \
    "$PORTAGE/sets"; do
    [[ -L "$target" ]] && rm "$target"
done

# Ensure portage subdirs exist as real directories
for dir in \
    "$PORTAGE/package.use" \
    "$PORTAGE/package.accept_keywords" \
    "$PORTAGE/package.mask" \
    "$PORTAGE/package.env" \
    "$PORTAGE/env"; do
    mkdir -p "$dir"
done

# Symlink base and host subdirs into each package.* dir
# Portage recurses into subdirectories automatically, so both
# base/ and host/ entries are read without any further sourcing
for category in package.use package.accept_keywords package.mask package.env; do
    [[ -d "$REPO_DIR/base/$category" ]] && \
        ln -sf "$REPO_DIR/base/$category" "$PORTAGE/$category/base"
    [[ -d "$REPO_DIR/hosts/$GENTOO_HOST/$category" ]] && \
        ln -sf "$REPO_DIR/hosts/$GENTOO_HOST/$category" "$PORTAGE/$category/host"
done

[[ -d "$REPO_DIR/base/env" ]] && \
    ln -sfn "$REPO_DIR/base/env" "$PORTAGE/env/base"

[[ -d "$REPO_DIR/hosts/$GENTOO_HOST/env" ]] && \
    ln -sfn "$REPO_DIR/hosts/$GENTOO_HOST/env" "$PORTAGE/env/host"

[[ -L "$PORTAGE/savedconfig" ]] && rm "$PORTAGE/savedconfig"
ln -sf "$REPO_DIR/hosts/$GENTOO_HOST/savedconfig" "$PORTAGE/savedconfig"

# Symlink sets dir — Portage reads /etc/portage/sets/ natively
ln -sf "$REPO_DIR/sets" "$PORTAGE/sets"

# Write make.conf — sources base first, then host overrides
# Overwrites the file each run so it stays in sync with the repo
cat > "$PORTAGE/make.conf" <<EOF
# Managed by deploy.sh — do not edit by hand
# Edit $REPO_DIR/base/make.conf or $REPO_DIR/hosts/$GENTOO_HOST/make.conf instead

source $REPO_DIR/base/make.conf
source $REPO_DIR/hosts/$GENTOO_HOST/make.conf
EOF

echo "Done. To sync packages, run:"
echo "  emerge --ask --newuse --deep --update @world"
echo "  emerge --ask --depclean"
