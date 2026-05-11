#!/usr/bin/env python3
#
# Limine config generator.
#
# Very unsafe, much no testing.
#
# install to /etc/kernel/postinst.d

import re
from dataclasses import dataclass
from itertools import product
from pathlib import Path

CMDLINE_PATH = Path("/etc/cmdline")
BOOT = Path("/boot")
TIMEOUT = 2
OUT = Path("/boot/limine/limine.conf")


KernelVersion = tuple[int, int, int, str]


@dataclass(frozen=True, order=True)
class Kernel:
    version: KernelVersion
    path: Path
    initramfs: Path


def get_kernel_version(prefix: str, filename: str, suffix: str) -> KernelVersion | None:
    pattern = rf"^{prefix}-(\d+)\.(\d+)\.(\d+)(?:-(.*))?-{suffix}$"
    m = re.match(pattern, filename)
    if m is None:
        return None

    version = (int(m[1]), int(m[2]), int(m[3]), "" if m[4] is None else m[4])

    return version


def get_initramfs(
    initramfs_prefixes: tuple[str, ...],
    initramfs_suffixes: tuple[str, ...],
    version: KernelVersion,
    vendor_string: str,
) -> Path | None:
    version_str = f"{version[0]}.{version[1]}.{version[2]}"
    if version[3] != "":
        version_str += f"-{version[3]}"
    for prefix, suffix in product(initramfs_prefixes, initramfs_suffixes):
        p = Path(BOOT) / f"{prefix}-{version_str}-{vendor_string}{suffix}"
        if p.exists():
            return p

    return None


def get_kernels(
    allowed_prefixes: tuple[str, ...] = ("vmlinuz",),
    allowed_vendor_strings: tuple[str, ...] = ("gentoo-dist",),
    initramfs_prefixes: tuple[str, ...] = ("initramfs",),
    initramfs_suffixes: tuple[str, ...] = (".img",),
) -> tuple[Kernel, ...]:

    kernels: list[Kernel] = []
    for prefix, suffix in product(allowed_prefixes, allowed_vendor_strings):
        for file in BOOT.glob(f"{prefix}*{suffix}"):
            version = get_kernel_version(prefix, file.name, suffix)
            if version is None:
                continue
            initramfs = get_initramfs(initramfs_prefixes, initramfs_suffixes, version, suffix)
            if initramfs is None:
                continue
            kernels.append(Kernel(version, file, initramfs))

    return tuple(sorted(kernels, reverse=True))


def get_cmdline() -> str:
    """Retrieve a preset kernel cmdline from CMDLINE_PATH."""
    lines = CMDLINE_PATH.open().readlines()

    if len(lines) != 1:
        raise ValueError(f"{CMDLINE_PATH} not properly formatted.")

    return lines[0].strip()


def get_preamble() -> str:
    return f"""timeout: {TIMEOUT}
editor_enabled: yes
hash_mismatch_panic: no
graphics: yes
default_entry: 2
backdrop: 2F302F
interface_help_hidden: False

"""


def get_gentoo_entries() -> str | None:
    cmdline = get_cmdline()
    kernels = get_kernels()
    if len(kernels) == 0:
        return None

    output = ["/+Gentoo Linux"]

    for kernel in kernels:
        version = kernel.version
        output.append(f"    //{version[0]}.{version[1]}.{version[2]}")
        output.append(f"    protocol: linux\n    path: boot():/{kernel.path.name}")
        output.append(f"    cmdline: {cmdline}")
        output.append(f"    module_path: boot():/{kernel.initramfs.name}")
        output.append("\n")

    return "\n".join(output)


def get_extra_entries() -> str:
    return """
/Arch Linux Install Media
    protocol: linux
    path: boot():/archlinux/vmlinuz-linux
    cmdline: img_dev=/dev/disk/by-uuid/AAD1-D263 img_loop=/archlinux/archlinux-2025.07.01-x86_64.iso archisobasedir=arch iomem=relaxed copytoram
    module_path: boot():/initramfs-linux.img

/Windows 11
    protocol: efi
    path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
    """


def main():
    preamble = get_preamble()
    gentoo_entries = get_gentoo_entries()

    if gentoo_entries is None:
        raise ValueError("No valid kernels found; aborting.")

    extra_entries = get_extra_entries()

    config = preamble + gentoo_entries + extra_entries

    with open(OUT, "w") as f:
        f.writelines(config)


if __name__ == "__main__":
    main()
