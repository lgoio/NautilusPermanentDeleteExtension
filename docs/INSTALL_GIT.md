# Git Installation

## Requirements

Ubuntu:

```bash
sudo apt install python3-nautilus gettext
```

## Clone Repository

```bash
git clone https://github.com/lgoio/NautilusPermanentDeleteExtension.git

cd NautilusPermanentDeleteExtension
```

## Install

```bash
make install
```

The installer can optionally restart Nautilus.

## Update

```bash
git pull

make install
```


## Uninstall

```bash
make uninstall
```

