#!/usr/bin/env python3
#
# Nautilus Permanent Delete Extension
#
# Adds a permanent delete context menu item and a Shift+Delete shortcut for
# Nautilus. The extension uses its own confirmation and progress dialogs.

import fnmatch
import gettext
import gi
import locale
import os
import time

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")

from gi.repository import Gdk, Gio, GLib, GObject, Gtk, Nautilus


DOMAIN = "nautilus-permanent-delete-extension"
EXTENSION_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(EXTENSION_DIR, DOMAIN)
LOCALE_DIR = os.path.join(DATA_DIR, "translations")

SYSTEM_BLACKLIST_PATHS_FILE = os.path.join(
    DATA_DIR,
    "system_blacklist_paths.conf",
)
SYSTEM_WHITELIST_PATHS_FILE = os.path.join(
    DATA_DIR,
    "system_whitelist_paths.conf",
)
USER_BLACKLIST_PATHS_FILE = os.path.join(
    os.path.expanduser("~"),
    ".config",
    DOMAIN,
    "user_blacklist_paths.conf",
)
USER_WHITELIST_PATHS_FILE = os.path.join(
    os.path.expanduser("~"),
    ".config",
    DOMAIN,
    "user_whitelist_paths.conf",
)

try:
    locale.setlocale(locale.LC_ALL, "")
except locale.Error:
    try:
        locale.setlocale(locale.LC_ALL, "C.UTF-8")
    except locale.Error:
        locale.setlocale(locale.LC_ALL, "C")

translation = gettext.translation(
    DOMAIN,
    localedir=LOCALE_DIR,
    fallback=True,
)

_ = translation.gettext
ngettext = translation.ngettext

FILE_OVERHEAD_BYTES = 256 * 1024
DIR_OVERHEAD_BYTES = 64 * 1024


class NautilusPermanentDeleteExtension(GObject.GObject, Nautilus.MenuProvider):
    ACTION_NAME = "permanent-delete-extension"
    ACTION_FULL_NAME = "app." + ACTION_NAME

    def __init__(self):
        GObject.GObject.__init__(self)

        self.home_dir = os.path.expanduser("~")

        self.blacklist_paths, self.blacklist_patterns = self._build_path_rules([
            SYSTEM_BLACKLIST_PATHS_FILE,
            USER_BLACKLIST_PATHS_FILE,
        ])
        self.whitelist_paths, self.whitelist_patterns = self._build_path_rules([
            SYSTEM_WHITELIST_PATHS_FILE,
            USER_WHITELIST_PATHS_FILE,
        ])

        self.selected_files = []
        self.delete_plan = []

        self.cancel_requested = False

        self.current_plan_index = 0
        self.current_file_index = 0
        self.current_dir_index = 0

        self.deleted_files_total = 0
        self.deleted_dirs_total = 0
        self.deleted_bytes = 0
        self.deleted_weight = 0

        self.total_files = 0
        self.total_dirs = 0
        self.total_bytes = 0
        self.total_weight = 0

        self.delete_started_at = None
        self.delete_errors = []

        self.confirm_dialog = None
        self.progress_dialog = None
        self.progress_label = None
        self.progress_bar = None

        self.safety_check_button = None
        self.safety_delete_button = None

        self._register_shortcut()

    def _is_glob_pattern(self, path):
        return any(char in path for char in ["*", "?", "["])

    def _build_path_rules(self, filenames):
        raw_entries = []

        for filename in filenames:
            raw_entries.extend(self._load_path_rules_from_file(filename))

        paths = set()
        patterns = set()

        for entry in raw_entries:
            normalized = self._normalize_path(entry)

            if self._is_glob_pattern(entry):
                patterns.add(normalized)
            else:
                paths.add(normalized)

        return paths, patterns

    def _load_path_rules_from_file(self, filename):
        entries = []

        if not os.path.isfile(filename):
            return entries

        try:
            with open(filename, "r", encoding="utf-8") as file:
                for line in file:
                    line = line.strip()

                    if not line or line.startswith("#"):
                        continue

                    entries.append(line)

        except OSError as error:
            print(_("Failed to read path rules file: %s: %s") % (
                filename,
                error,
            ))

        return entries

    def _normalize_path(self, path):
        path = os.path.expanduser(path.strip())
        path = os.path.abspath(path)

        return os.path.normpath(path)

    def _match_rule(self, path, rule):
        path = self._normalize_path(path)
        rule = self._normalize_path(rule)

        if rule.endswith("/**"):
            base = rule[:-3]

            # Match the base path and everything below it.
            return path == base or path.startswith(base + os.sep)

        if rule.endswith("/*"):
            base = rule[:-2]

            # Match the base path and its direct children.
            if path == base:
                return True

            if not path.startswith(base + os.sep):
                return False

            remainder = path[len(base) + 1:]

            return os.sep not in remainder

        return fnmatch.fnmatch(path, rule)

    def _matches_path_rules(self, path, paths, patterns):
        normalized = self._normalize_path(path)

        if normalized in paths:
            return True

        for pattern in patterns:
            if self._match_rule(path, pattern):
                return True

        return False

    def _requires_extra_confirmation(self, path):
        if self._matches_path_rules(
            path,
            self.whitelist_paths,
            self.whitelist_patterns,
        ):
            return False

        return self._matches_path_rules(
            path,
            self.blacklist_paths,
            self.blacklist_patterns,
        )

    def _is_whitelisted_path(self, path):
        return self._matches_path_rules(
            path,
            self.whitelist_paths,
            self.whitelist_patterns,
        )

    def _register_shortcut(self):
        app = Gio.Application.get_default()
        if app is None:
            return

        if app.lookup_action(self.ACTION_NAME) is not None:
            return

        action = Gio.SimpleAction.new(self.ACTION_NAME, None)
        action.connect("activate", self._on_shortcut)
        app.add_action(action)
        app.set_accels_for_action(self.ACTION_FULL_NAME, ["<Shift>Delete"])

    def _display_path(self, path):
        if path == self.home_dir:
            return "~"

        if path.startswith(self.home_dir + os.sep):
            return "~" + path[len(self.home_dir):]

        return path

    def get_file_items(self, files):
        self.selected_files = [
            file_info
            for file_info in files
            if file_info.get_uri().startswith("file://")
        ]

        if not self.selected_files:
            return []

        if not self._all_selected_roots_can_be_deleted():
            return []

        item = Nautilus.MenuItem(
            name="NautilusPermanentDeleteExtension::delete_permanently",
            label=_("Delete Permanently"),
            tip=_("Delete selected items permanently"),
        )
        item.connect("activate", self._on_menu_item)

        return [item]

    def _on_shortcut(self, action, parameter):
        self._show_confirm_dialog()

    def _on_menu_item(self, menu_item):
        self._show_confirm_dialog()

    def _get_active_window(self):
        app = Gio.Application.get_default()
        if app is None:
            return None

        if hasattr(app, "get_active_window"):
            return app.get_active_window()

        return None

    def _path_from_file(self, nautilus_file):
        location = nautilus_file.get_location()
        if location is None:
            return None

        return location.get_path()

    def _file_entry(self, path):
        size = 0

        try:
            size = os.path.getsize(path)
        except OSError:
            pass

        return {
            "path": path,
            "size": size,
            "weight": FILE_OVERHEAD_BYTES + size,
        }

    def _dir_entry(self, path):
        return {
            "path": path,
            "weight": DIR_OVERHEAD_BYTES,
        }

    def _build_delete_plan(self):
        plan = []
        total_files = 0
        total_dirs = 0
        total_bytes = 0
        total_weight = 0

        for nautilus_file in self.selected_files:
            path = self._path_from_file(nautilus_file)
            if not path:
                continue

            entry = {
                "root": path,
                "files": [],
                "dirs": [],
                "bytes": 0,
                "weight": 0,
            }

            if os.path.isfile(path) or os.path.islink(path):
                file_entry = self._file_entry(path)
                entry["files"].append(file_entry)
                entry["bytes"] += file_entry["size"]
                entry["weight"] += file_entry["weight"]

            elif os.path.isdir(path):
                # Delete files before directories.
                for root, dirs, files in os.walk(path, topdown=False, followlinks=False):
                    for filename in files:
                        file_path = os.path.join(root, filename)
                        file_entry = self._file_entry(file_path)

                        entry["files"].append(file_entry)
                        entry["bytes"] += file_entry["size"]
                        entry["weight"] += file_entry["weight"]

                    for dirname in dirs:
                        dir_entry = self._dir_entry(os.path.join(root, dirname))
                        entry["dirs"].append(dir_entry)
                        entry["weight"] += dir_entry["weight"]

                root_dir_entry = self._dir_entry(path)
                entry["dirs"].append(root_dir_entry)
                entry["weight"] += root_dir_entry["weight"]

            plan.append(entry)

            total_files += len(entry["files"])
            total_dirs += len(entry["dirs"])
            total_bytes += entry["bytes"]
            total_weight += entry["weight"]

        return plan, total_files, total_dirs, total_bytes, total_weight

    def _selected_blacklisted_paths(self):
        blacklisted = []

        for entry in self.delete_plan:
            root = entry["root"]

            if self._requires_extra_confirmation(root):
                blacklisted.append(root)

        return blacklisted

    def _all_selected_paths_are_whitelisted(self):
        if not self.delete_plan:
            return False

        for entry in self.delete_plan:
            if not self._is_whitelisted_path(entry["root"]):
                return False

        return True

    def _can_delete_selected_root(self, path):
        if not os.path.lexists(path):
            return False

        parent = os.path.dirname(path) or os.sep

        if not os.access(parent, os.W_OK | os.X_OK):
            return False

        try:
            parent_stat = os.stat(parent)
            path_stat = os.lstat(path)
        except OSError:
            return False

        if os.geteuid() == 0:
            return True

        if parent_stat.st_mode & 0o1000:
            return os.geteuid() in (path_stat.st_uid, parent_stat.st_uid)

        return True

    def _all_selected_roots_can_be_deleted(self):
        for file_info in self.selected_files:
            path = self._path_from_file(file_info)

            if not path:
                return False

            if not self._can_delete_selected_root(path):
                return False

        return True

    def _icon_for_path(self, path):
        try:
            gfile = Gio.File.new_for_path(path)
            info = gfile.query_info(
                "standard::icon",
                Gio.FileQueryInfoFlags.NONE,
                None,
            )
            icon = info.get_icon()

            if icon is not None:
                return icon

        except Exception:
            pass

        if os.path.isdir(path) and not os.path.islink(path):
            return Gio.ThemedIcon.new("folder")

        return Gio.ThemedIcon.new("text-x-generic")

    def _create_selected_items_list(self, selected_paths):
        list_box = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=10,
        )

        for path in selected_paths:
            row = Gtk.Box(
                orientation=Gtk.Orientation.HORIZONTAL,
                spacing=12,
            )

            icon = Gtk.Image.new_from_gicon(self._icon_for_path(path))
            icon.set_pixel_size(36)

            text_box = Gtk.Box(
                orientation=Gtk.Orientation.VERTICAL,
                spacing=2,
            )

            name_label = Gtk.Label(label=os.path.basename(path) or path)
            name_label.set_xalign(0)
            name_label.set_hexpand(True)
            name_label.set_wrap(True)
            name_label.set_selectable(True)

            path_label = Gtk.Label(label=self._display_path(path))
            path_label.set_xalign(0)
            path_label.set_hexpand(True)
            path_label.set_wrap(True)
            path_label.set_selectable(True)
            path_label.add_css_class("dim-label")

            text_box.append(name_label)
            text_box.append(path_label)

            row.append(icon)
            row.append(text_box)

            list_box.append(row)

        return list_box

    def _description_text_for_selection(self):
        selected_count = len(self.delete_plan)
        selected_dirs, selected_files = self._selected_root_counts()

        if selected_count == 1:
            if selected_dirs == 1:
                return _("The following folder will be permanently deleted:")

            return _("The following file will be permanently deleted:")

        if selected_dirs > 0 and selected_files > 0:
            return _("The following files and folders will be permanently deleted:")

        if selected_dirs > 0:
            return _("The following folders will be permanently deleted:")

        return _("The following files will be permanently deleted:")

    def _selected_root_counts(self):
        selected_dirs = 0
        selected_files = 0

        for entry in self.delete_plan:
            root = entry["root"]

            if os.path.isdir(root) and not os.path.islink(root):
                selected_dirs += 1
            else:
                selected_files += 1

        return selected_dirs, selected_files

    def _delete_dialog_title(self):
        selected_count = len(self.delete_plan)
        selected_dirs, selected_files = self._selected_root_counts()

        if selected_count == 1:
            if selected_dirs == 1:
                return _("Delete Folder Permanently?")

            return _("Delete File Permanently?")

        if selected_dirs > 0 and selected_files > 0:
            return _("Delete %(folders)d folders and %(files)d files Permanently?") % {
                "folders": selected_dirs,
                "files": selected_files,
            }

        if selected_dirs > 0:
            return ngettext(
                "Delete %d folder Permanently?",
                "Delete %d folders Permanently?",
                selected_dirs,
            ) % selected_dirs

        return ngettext(
            "Delete %d file Permanently?",
            "Delete %d files Permanently?",
            selected_files,
        ) % selected_files

    def _stats_text(self):
        stats_parts = []

        if self.total_dirs > 0:
            stats_parts.append(
                ngettext("%d folder", "%d folders", self.total_dirs)
                % self.total_dirs
            )

        stats_parts.append(
            ngettext("%d file", "%d files", self.total_files)
            % self.total_files
        )

        stats_parts.append(_("Size: %s") % GLib.format_size(self.total_bytes))

        return "   ·   ".join(stats_parts)

    def _show_confirm_dialog(self):
        if not self.selected_files:
            return

        if not self._all_selected_roots_can_be_deleted():
            return

        (
            self.delete_plan,
            self.total_files,
            self.total_dirs,
            self.total_bytes,
            self.total_weight,
        ) = self._build_delete_plan()

        if not self.delete_plan:
            return

        require_extra_confirmation = bool(self._selected_blacklisted_paths())

        if self._all_selected_paths_are_whitelisted():
            self._start_deletion()
            return

        self._show_delete_dialog(require_extra_confirmation)

    def _show_delete_dialog(self, require_extra_confirmation=False):
        selected_paths = [entry["root"] for entry in self.delete_plan]
        parent = self._get_active_window()
        dialog_title = self._delete_dialog_title()

        self.confirm_dialog = Gtk.Dialog(
            title=dialog_title,
            transient_for=parent,
            modal=True,
        )
        self.confirm_dialog.set_destroy_with_parent(True)

        key_controller = Gtk.EventControllerKey()
        key_controller.connect("key-pressed", self._on_confirm_key_pressed)
        self.confirm_dialog.add_controller(key_controller)

        content_area = self.confirm_dialog.get_content_area()
        content_area.set_spacing(16)
        content_area.set_margin_top(18)
        content_area.set_margin_bottom(18)
        content_area.set_margin_start(18)
        content_area.set_margin_end(18)

        title = Gtk.Label(label=dialog_title)
        title.add_css_class("title-2")
        title.set_xalign(0)

        description = Gtk.Label(label=self._description_text_for_selection())
        description.set_wrap(True)
        description.set_xalign(0)

        selected_items_list = self._create_selected_items_list(selected_paths)

        stats_label = Gtk.Label(label=self._stats_text())
        stats_label.set_xalign(0)
        stats_label.set_selectable(True)

        content_area.append(title)
        content_area.append(description)
        content_area.append(selected_items_list)
        content_area.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))
        content_area.append(stats_label)

        if require_extra_confirmation:
            self._append_extra_confirmation(content_area)

        self.confirm_dialog.add_button(_("_Cancel"), Gtk.ResponseType.CANCEL)
        self.confirm_dialog.add_button(_("Delete _Permanently"), Gtk.ResponseType.OK)

        cancel_button = self.confirm_dialog.get_widget_for_response(Gtk.ResponseType.CANCEL)
        delete_button = self.confirm_dialog.get_widget_for_response(Gtk.ResponseType.OK)

        if cancel_button is not None:
            cancel_button.set_use_underline(True)

        if delete_button is not None:
            delete_button.set_use_underline(True)
            delete_button.add_css_class("destructive-action")
            delete_button.set_sensitive(not require_extra_confirmation)

        if require_extra_confirmation:
            self.safety_delete_button = delete_button
            self.confirm_dialog.set_default_response(Gtk.ResponseType.CANCEL)

        else:
            self.safety_check_button = None
            self.safety_delete_button = None

            if delete_button is not None:
                delete_button.grab_focus()

            self.confirm_dialog.set_default_response(Gtk.ResponseType.OK)

        self.confirm_dialog.connect("response", self._on_confirm_response)
        self.confirm_dialog.present()

        if require_extra_confirmation and self.safety_check_button is not None:
            self.safety_check_button.grab_focus()

    def _append_extra_confirmation(self, content_area):
        warning_box = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL,
            spacing=8,
        )

        # Use the regular themed icon instead of a symbolic icon.
        warning_icon = Gtk.Image.new_from_icon_name("dialog-warning")
        warning_icon.set_pixel_size(24)

        warning_label = Gtk.Label(
            label=_("Warning: Deletion requires additional confirmation.")
        )
        warning_label.set_wrap(True)
        warning_label.set_xalign(0)
        warning_label.set_hexpand(True)

        warning_box.append(warning_icon)
        warning_box.append(warning_label)

        self.safety_check_button = Gtk.CheckButton(
            label=_("I understand the risk.")
        )
        self.safety_check_button.connect("toggled", self._on_safety_check_toggled)

        content_area.append(warning_box)
        content_area.append(self.safety_check_button)

    def _start_deletion(self):
        self._reset_progress()
        self.delete_started_at = time.monotonic()
        self._show_progress_window()

        GLib.idle_add(self._delete_next_step)

    def _on_safety_check_toggled(self, check_button):
        active = check_button.get_active()

        if self.safety_delete_button is not None:
            self.safety_delete_button.set_sensitive(active)

            if active:
                self.safety_delete_button.grab_focus()

    def _on_confirm_key_pressed(self, controller, keyval, keycode, state):
        if keyval == Gdk.KEY_Escape:
            self._on_confirm_cancel_clicked(None)
            return True

        return False

    def _on_confirm_cancel_clicked(self, button):
        if self.confirm_dialog:
            self.confirm_dialog.response(Gtk.ResponseType.CANCEL)

    def _on_confirm_delete_clicked(self, button):
        if self.confirm_dialog:
            self.confirm_dialog.response(Gtk.ResponseType.OK)

    def _on_confirm_response(self, dialog, response):
        if self.confirm_dialog:
            self.confirm_dialog.close()
            self.confirm_dialog = None

        self.safety_check_button = None
        self.safety_delete_button = None

        if response != Gtk.ResponseType.OK:
            return

        self._start_deletion()

    def _reset_progress(self):
        self.cancel_requested = False

        self.current_plan_index = 0
        self.current_file_index = 0
        self.current_dir_index = 0

        self.deleted_files_total = 0
        self.deleted_dirs_total = 0
        self.deleted_bytes = 0
        self.deleted_weight = 0

        self.delete_started_at = None
        self.delete_errors = []

    def _show_progress_window(self):
        parent = self._get_active_window()

        self.progress_dialog = Gtk.Dialog(
            title=_("Deleting Files"),
            transient_for=parent,
            modal=True,
        )
        self.progress_dialog.set_destroy_with_parent(True)
        self.progress_dialog.set_default_size(620, 230)

        key_controller = Gtk.EventControllerKey()
        key_controller.connect("key-pressed", self._on_progress_key_pressed)
        self.progress_dialog.add_controller(key_controller)

        content_area = self.progress_dialog.get_content_area()
        content_area.set_spacing(12)
        content_area.set_margin_top(18)
        content_area.set_margin_bottom(18)
        content_area.set_margin_start(18)
        content_area.set_margin_end(18)

        self.progress_label = Gtk.Label()
        self.progress_label.set_wrap(True)
        self.progress_label.set_xalign(0)
        self.progress_label.set_selectable(True)

        self.progress_bar = Gtk.ProgressBar()

        content_area.append(self.progress_label)
        content_area.append(self.progress_bar)

        self.progress_dialog.add_button(_("_Cancel"), Gtk.ResponseType.CANCEL)

        cancel_button = self.progress_dialog.get_widget_for_response(Gtk.ResponseType.CANCEL)
        if cancel_button is not None:
            cancel_button.set_use_underline(True)

        self.progress_dialog.connect("response", self._on_progress_response)
        self.progress_dialog.present()

    def _on_progress_key_pressed(self, controller, keyval, keycode, state):
        if keyval == Gdk.KEY_Escape:
            self._on_progress_cancel_clicked(None)
            return True

        return False

    def _on_progress_cancel_clicked(self, button):
        if self.progress_dialog:
            self.progress_dialog.response(Gtk.ResponseType.CANCEL)

    def _on_progress_response(self, dialog, response):
        if response == Gtk.ResponseType.CANCEL:
            self.cancel_requested = True

            if self.progress_label:
                self.progress_label.set_text(_("Canceling..."))

    def _record_delete_error(self, path, error):
        self.delete_errors.append((path, str(error)))

    def _show_delete_errors_dialog(self):
        if not self.delete_errors:
            return

        parent = self._get_active_window()

        dialog = Gtk.Dialog(
            title=_("Some Items Could Not Be Deleted"),
            transient_for=parent,
            modal=True,
        )
        dialog.set_destroy_with_parent(True)

        content_area = dialog.get_content_area()
        content_area.set_spacing(12)
        content_area.set_margin_top(18)
        content_area.set_margin_bottom(18)
        content_area.set_margin_start(18)
        content_area.set_margin_end(18)

        title = Gtk.Label(label=_("Some Items Could Not Be Deleted"))
        title.add_css_class("title-2")
        title.set_xalign(0)

        description = Gtk.Label(
            label=_("Some items could not be deleted because an error occurred.")
        )
        description.set_wrap(True)
        description.set_xalign(0)

        error_list = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=6,
        )

        for path, error in self.delete_errors[:10]:
            label = Gtk.Label(
                label="%s\n%s" % (self._display_path(path), error)
            )
            label.set_xalign(0)
            label.set_wrap(True)
            label.set_selectable(True)
            error_list.append(label)

        if len(self.delete_errors) > 10:
            label = Gtk.Label(
                label=_("%d more errors were not shown.") % (
                    len(self.delete_errors) - 10
                )
            )
            label.set_xalign(0)
            error_list.append(label)

        content_area.append(title)
        content_area.append(description)
        content_area.append(error_list)

        dialog.add_button(_("_Close"), Gtk.ResponseType.CLOSE)
        dialog.connect("response", lambda current_dialog, response: current_dialog.close())
        dialog.present()

    def _delete_file_entry(self, file_entry):
        Gio.File.new_for_path(file_entry["path"]).delete(None)

    def _delete_dir_entry(self, dir_entry):
        Gio.File.new_for_path(dir_entry["path"]).delete(None)

    def _delete_next_step(self):
        if self.cancel_requested:
            self._finish_progress(_("Deletion canceled."))
            return False

        if self.current_plan_index >= len(self.delete_plan):
            self._finish_progress(_("Deletion finished."))
            return False

        entry = self.delete_plan[self.current_plan_index]
        files = entry["files"]
        dirs = entry["dirs"]

        if self.current_file_index < len(files):
            file_entry = files[self.current_file_index]
            self.current_file_index += 1

            self._update_progress(entry["root"], file_entry["path"])

            try:
                self._delete_file_entry(file_entry)
                self.deleted_files_total += 1
                self.deleted_bytes += file_entry["size"]
                self.deleted_weight += file_entry["weight"]

            except Exception as error:
                self._record_delete_error(file_entry["path"], error)
                print(_("Failed to delete file: %s: %s") % (file_entry["path"], error))

            GLib.idle_add(self._delete_next_step)
            return False

        if self.current_dir_index < len(dirs):
            dir_entry = dirs[self.current_dir_index]
            self.current_dir_index += 1

            self._update_progress(entry["root"], dir_entry["path"])

            try:
                self._delete_dir_entry(dir_entry)
                self.deleted_dirs_total += 1
                self.deleted_weight += dir_entry["weight"]

            except Exception as error:
                self._record_delete_error(dir_entry["path"], error)
                print(_("Failed to delete folder: %s: %s") % (dir_entry["path"], error))

            GLib.idle_add(self._delete_next_step)
            return False

        self.current_plan_index += 1
        self.current_file_index = 0
        self.current_dir_index = 0

        GLib.idle_add(self._delete_next_step)
        return False

    def _estimate_remaining_seconds(self):
        if self.delete_started_at is None:
            return None

        if self.deleted_weight <= 0 or self.total_weight <= 0:
            return None

        fraction = min(self.deleted_weight / self.total_weight, 1.0)

        if fraction <= 0.0:
            return None

        elapsed = time.monotonic() - self.delete_started_at
        total_estimated = elapsed / fraction

        return max(total_estimated - elapsed, 0.0)

    def _update_progress(self, root, current_path):
        fraction = min(
            self.deleted_weight / max(self.total_weight, 1),
            1.0,
        )

        lines = [
            _("Deleting:"),
            self._display_path(root),
            "",
            _("Files: %(done)d / %(total)d") % {
                "done": self.deleted_files_total,
                "total": self.total_files,
            },
            _("Folders: %(done)d / %(total)d") % {
                "done": self.deleted_dirs_total,
                "total": self.total_dirs,
            },
            _("Size: %(done)s / %(total)s") % {
                "done": GLib.format_size(self.deleted_bytes),
                "total": GLib.format_size(self.total_bytes),
            },
        ]

        eta = self._estimate_remaining_seconds()
        if eta is not None:
            lines.append(_("Estimated time remaining: %d s") % int(eta))

        lines.extend(["", self._display_path(current_path)])

        if self.progress_bar:
            self.progress_bar.set_fraction(fraction)

        if self.progress_label:
            self.progress_label.set_text("\n".join(lines))

    def _finish_progress(self, message):
        if self.progress_bar:
            self.progress_bar.set_fraction(1.0)

        if self.progress_dialog:
            self.progress_dialog.close()
            self.progress_dialog = None

        if self.delete_errors:
            GLib.idle_add(self._show_delete_errors_dialog)

        return False
