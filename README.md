# Modular Gentoo config

## Setup

Begin following the normal Gentoo setup process, setting up filesystems and setting up the initial Portage repo.

When it comes to updating the base set, do the following:

### Dependencies

- Ensure you are within the chroot environment.
- `emerge -1av git eselect-repository` to bootstrap git and eselect-repository.
- `eselect repository enable guru`, as we use `chezmoi`.
- `emaint sync -r guru` to sync the GURU repo.

### Deployment

- Clone this repo to a directory of choice. You may want to create a user first.
- Set a hostname in the chrooted environment.
- Use an existing host/set in this repo, or copy/paste/adjust to a new host.
- `sudo deploy.sh` to set symlinks up in `/etc/portage`.
- `emerge -NuaDv world @${HOSTNAME}` to install sets configured for the host.
