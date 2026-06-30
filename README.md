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
- Adds basic DNF settings.
- Enables RPM Fusion free and nonfree repositories.
- Installs common CLI tools and developer utilities.
- Enables Flathub.
- Updates installed packages.

## Dry run

```bash
DRY_RUN=1 bash bootstrap.sh
```
