# fedora-bootstrap

Personal Fedora bootstrap script.

## Run from GitHub

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/inhoolee/fedora-bootstrap/main/bootstrap.sh)"
```

If your default branch is `master`, use this instead:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/inhoolee/fedora-bootstrap/master/bootstrap.sh)"
```

## What it does

- Refreshes DNF metadata.
- Sets GNOME dark mode.
- Renames Korean home directories to English names when present:
  `바탕화면` to `Desktop`, `문서` to `Documents`, and `다운로드` to `Downloads`.
- Deletes other top-level Korean-named home directories only when they are empty.
- Adds basic DNF settings.
- Enables RPM Fusion free and nonfree repositories.
- Installs common CLI tools and developer utilities.
- Installs modern CLI tools including `bat`, `btop`, `duf`, `dust`, `eza`, `git-delta`,
  `tealdeer`, `yq`, and `zoxide`.
- Adds Bash aliases for modern replacements such as `cat`, `top`, `diff`, `df`, `du`,
  `ls`, `grep`, and initializes `zoxide`.
- Enables Flathub.
- Updates installed packages.

## Dry run

```bash
DRY_RUN=1 bash bootstrap.sh
```
