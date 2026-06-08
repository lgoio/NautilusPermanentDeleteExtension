# ZIP Installation

## Requirements

Ubuntu:

```bash
sudo apt install python3-nautilus unzip
```

## Download

```bash
wget https://github.com/lgoio/NautilusPermanentDeleteExtension/releases/download/0.1.0/nautilus-permanent-delete-extension-0.1.0.zip
```

## Install

```bash
unzip nautilus-permanent-delete-extension-0.1.0.zip

cd nautilus-permanent-delete-extension-0.1.0

mkdir -p ~/.local/share/nautilus-python/extensions

cp nautilus_permanent_delete_extension.py \
   ~/.local/share/nautilus-python/extensions/

cp -r nautilus-permanent-delete-extension \
   ~/.local/share/nautilus-python/extensions/

nautilus -q
```

## Uninstall

```bash
rm -f ~/.local/share/nautilus-python/extensions/nautilus_permanent_delete_extension.py

rm -rf ~/.local/share/nautilus-python/extensions/nautilus-permanent-delete-extension

rm -rf ~/.config/nautilus-permanent-delete-extension

nautilus -q
```
