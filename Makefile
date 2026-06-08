PYTHON_FILE = nautilus_permanent_delete_extension.py
TRANSLATION_SCRIPT = generate_translations.sh
TRANSLATIONS_DIR = translations
METADATA_FILE = metadata.json
ZIP_README = docs/INSTALL_ZIP.md

SYSTEM_BLACKLIST_FILE = system_blacklist_paths.conf
SYSTEM_WHITELIST_FILE = system_whitelist_paths.conf
EXAMPLE_USER_BLACKLIST_FILE = example_user_blacklist_paths.conf
EXAMPLE_USER_WHITELIST_FILE = example_user_whitelist_paths.conf

NAME := $(shell python3 -c 'import json; print(json.load(open("$(METADATA_FILE)"))["name"])')
DOMAIN := $(shell python3 -c 'import json; print(json.load(open("$(METADATA_FILE)"))["gettext-domain"])')
UUID := $(shell python3 -c 'import json; print(json.load(open("$(METADATA_FILE)"))["uuid"])')
VERSION := $(shell python3 -c 'import json; print(json.load(open("$(METADATA_FILE)"))["version"])')

INSTALL_ROOT = $(HOME)/.local/share/nautilus-python/extensions
INSTALL_DATA_DIR = $(INSTALL_ROOT)/$(DOMAIN)

USER_CONFIG_DIR = $(HOME)/.config/$(DOMAIN)

BUILD_DIR = build
DIST_DIR = $(BUILD_DIR)/$(DOMAIN)-$(VERSION)
PACKAGE_NAME = $(DOMAIN)-$(VERSION).zip

.PHONY: all check generate-translations compile-locales install dev-install uninstall restart clean dist version

all: generate-translations compile-locales

version:
	@echo "$(VERSION)"

check:
	@test -f "$(PYTHON_FILE)" || (echo "Missing $(PYTHON_FILE)" && exit 1)
	@test -f "$(TRANSLATION_SCRIPT)" || (echo "Missing $(TRANSLATION_SCRIPT)" && exit 1)
	@test -f "$(METADATA_FILE)" || (echo "Missing $(METADATA_FILE)" && exit 1)
	@test -f "$(ZIP_README)" || (echo "Missing $(ZIP_README)" && exit 1)
	@test -f "$(SYSTEM_BLACKLIST_FILE)" || (echo "Missing $(SYSTEM_BLACKLIST_FILE)" && exit 1)
	@test -f "$(SYSTEM_WHITELIST_FILE)" || (echo "Missing $(SYSTEM_WHITELIST_FILE)" && exit 1)
	@test -f "$(EXAMPLE_USER_BLACKLIST_FILE)" || (echo "Missing $(EXAMPLE_USER_BLACKLIST_FILE)" && exit 1)
	@test -f "$(EXAMPLE_USER_WHITELIST_FILE)" || (echo "Missing $(EXAMPLE_USER_WHITELIST_FILE)" && exit 1)
	@test -d "$(TRANSLATIONS_DIR)" || mkdir -p "$(TRANSLATIONS_DIR)"

generate-translations: check
	chmod +x ./$(TRANSLATION_SCRIPT)
	./$(TRANSLATION_SCRIPT)

compile-locales:
	@find "$(TRANSLATIONS_DIR)" -name "*.po" | while IFS= read -r po_file; do \
		mo_file="$${po_file%.po}.mo"; \
		echo "Compiling $$po_file"; \
		msgfmt "$$po_file" -o "$$mo_file"; \
	done

install: all
	mkdir -p "$(INSTALL_ROOT)"
	rm -f "$(INSTALL_ROOT)/$(PYTHON_FILE)"
	rm -rf "$(INSTALL_DATA_DIR)"
	mkdir -p "$(INSTALL_DATA_DIR)"
	cp "$(PYTHON_FILE)" "$(INSTALL_ROOT)/"
	cp "$(METADATA_FILE)" "$(INSTALL_DATA_DIR)/"
	cp "$(SYSTEM_BLACKLIST_FILE)" "$(INSTALL_DATA_DIR)/"
	cp "$(SYSTEM_WHITELIST_FILE)" "$(INSTALL_DATA_DIR)/"
	cp "$(EXAMPLE_USER_BLACKLIST_FILE)" "$(INSTALL_DATA_DIR)/"
	cp "$(EXAMPLE_USER_WHITELIST_FILE)" "$(INSTALL_DATA_DIR)/"
	cp -r "$(TRANSLATIONS_DIR)" "$(INSTALL_DATA_DIR)/"

	@if pgrep -x nautilus >/dev/null; then \
		echo ""; \
		printf "Nautilus is running. Restart now to load the extension? [Y/n] "; \
		read answer; \
		case "$$answer" in \
			n|N) echo "Please restart Nautilus manually with: nautilus -q" ;; \
			*) nautilus -q; echo "Nautilus restarted." ;; \
		esac; \
	fi

dev-install: install

uninstall:
	rm -f "$(INSTALL_ROOT)/$(PYTHON_FILE)"
	rm -rf "$(INSTALL_DATA_DIR)"

	@if [ -d "$(USER_CONFIG_DIR)" ]; then \
		echo ""; \
		printf "Remove user configuration files too? [y/N] "; \
		read answer; \
		case "$$answer" in \
			y|Y) rm -rf "$(USER_CONFIG_DIR)"; echo "Removed $(USER_CONFIG_DIR)" ;; \
			*) echo "Keeping user configuration in $(USER_CONFIG_DIR)" ;; \
		esac; \
	fi

	@if pgrep -x nautilus >/dev/null; then \
		echo ""; \
		printf "Nautilus is running. Restart now to unload the extension? [Y/n] "; \
		read answer; \
		case "$$answer" in \
			n|N) echo "Please restart Nautilus manually with: nautilus -q" ;; \
			*) nautilus -q; echo "Nautilus restarted." ;; \
		esac; \
	fi

restart:
	nautilus -q

clean:
	find "$(TRANSLATIONS_DIR)" -name "*.mo" -delete
	rm -rf "$(BUILD_DIR)"
	rm -f "$(DOMAIN)-"*.zip

dist: all
	rm -rf "$(DIST_DIR)"
	mkdir -p "$(DIST_DIR)/$(DOMAIN)"
	cp "$(PYTHON_FILE)" "$(DIST_DIR)/"
	cp "$(ZIP_README)" "$(DIST_DIR)/README.md"
	cp "$(METADATA_FILE)" "$(DIST_DIR)/$(DOMAIN)/"
	cp "$(SYSTEM_BLACKLIST_FILE)" "$(DIST_DIR)/$(DOMAIN)/"
	cp "$(SYSTEM_WHITELIST_FILE)" "$(DIST_DIR)/$(DOMAIN)/"
	cp "$(EXAMPLE_USER_BLACKLIST_FILE)" "$(DIST_DIR)/$(DOMAIN)/"
	cp "$(EXAMPLE_USER_WHITELIST_FILE)" "$(DIST_DIR)/$(DOMAIN)/"
	cp -r "$(TRANSLATIONS_DIR)" "$(DIST_DIR)/$(DOMAIN)/"
	find "$(DIST_DIR)/$(DOMAIN)/$(TRANSLATIONS_DIR)" -name "*.po" -delete
	find "$(DIST_DIR)/$(DOMAIN)/$(TRANSLATIONS_DIR)" -name "*.pot" -delete
	cd "$(BUILD_DIR)" && zip -r "../$(PACKAGE_NAME)" "$(DOMAIN)-$(VERSION)"
	@echo "Created $(PACKAGE_NAME)"
