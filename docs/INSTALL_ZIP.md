# ZIP Installation

## Requirements

Ubuntu:

```bash
sudo apt install python3-nautilus
```

## Install

Extract the ZIP archive.

```bash
mkdir -p ~/.local/share/nautilus-python/extensions

cp nautilus_permanent_delete_extension.py \
   ~/.local/share/nautilus-python/extensions/

cp -r nautilus-permanent-delete-extension \
   ~/.local/share/nautilus-python/extensions/
```

Restart Nautilus:

```bash
nautilus -q
```

## Optional User Configuration

Create your own protected and allowed path rules:

```bash
mkdir -p ~/.config/nautilus-permanent-delete-extension

cp ~/.local/share/nautilus-python/extensions/nautilus-permanent-delete-extension/example_user_protected_paths.conf \
   ~/.config/nautilus-permanent-delete-extension/user_protected_paths.conf

cp ~/.local/share/nautilus-python/extensions/nautilus-permanent-delete-extension/example_user_allowed_paths.conf \
   ~/.config/nautilus-permanent-delete-extension/user_allowed_paths.conf
```

## Uninstall

```bash
rm -f ~/.local/share/nautilus-python/extensions/nautilus_permanent_delete_extension.py

rm -rf ~/.local/share/nautilus-python/extensions/nautilus-permanent-delete-extension

rm -rf ~/.config/nautilus-permanent-delete-extension

nautilus -q
```
