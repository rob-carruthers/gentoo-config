EAPI=8

inherit xdg

DESCRIPTION="Memphis98 icon theme"
HOMEPAGE="https://github.com/Stanton731/Memphis98"

SRC_URI="https://github.com/Stanton731/Memphis98/archive/2d7bb5122d9bcc84ced422943ab2abe3a80d0ac9.tar.gz -> ${P}.tar.gz"

LICENSE="unknown"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RDEPEND="
    x11-themes/hicolor-icon-theme
"

S="${WORKDIR}/Memphis98-2d7bb5122d9bcc84ced422943ab2abe3a80d0ac9"

src_install() {
    insinto /usr/share/icons/Memphis98
    doins -r .

    # fallback index.theme if missing upstream
    if ! test -f index.theme; then
        cat > index.theme <<'EOF'
[Icon Theme]
Name=Memphis98
Comment=Memphis98 Icon Theme
Directories=.

[.]
Size=48
Context=Applications
Type=Fixed
EOF
    fi

    doins index.theme
}
