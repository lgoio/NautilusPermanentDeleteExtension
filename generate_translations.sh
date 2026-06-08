#!/bin/bash
set -euo pipefail

# Generate gettext translations for Nautilus Permanent Delete Extension.
#
# This script:
#   1. Extracts strings from nautilus_permanent_delete_extension.py into a POT file.
#   2. Creates/updates PO files for all supported languages.
#   3. Fills known translations for the extension strings.
#   4. Compiles MO files.
#
# Requirements:
#   sudo apt install gettext

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOMAIN="nautilus-permanent-delete-extension"
PYTHON_FILE="$SCRIPT_DIR/nautilus_permanent_delete_extension.py"
TRANSLATIONS_DIR="$SCRIPT_DIR/translations"
POT_FILE="$TRANSLATIONS_DIR/$DOMAIN.pot"

if [ ! -f "$PYTHON_FILE" ]; then
  echo "Error: Python source file not found: $PYTHON_FILE" >&2
  exit 1
fi

LANGUAGES=(
  ar ca cs de el es eu fa fi fr hu it ja nl oc pl pt_BR ru sk tr uk zh_CN
)

mkdir -p "$TRANSLATIONS_DIR"

echo "Generating POT file..."
xgettext \
  --language=Python \
  --from-code=UTF-8 \
  --keyword=_ \
  --keyword=ngettext:1,2 \
  --output="$POT_FILE" \
  "$PYTHON_FILE"

python3 <<'PY'
import os
import re
import subprocess
from pathlib import Path

script_dir = Path(__file__).resolve().parent
domain = "nautilus-permanent-delete-extension"
translations_dir = script_dir / "translations"
pot_file = translations_dir / f"{domain}.pot"

languages = [
    "ar", "ca", "cs", "de", "el", "es", "eu", "fa", "fi", "fr", "hu", "it",
    "ja", "nl", "oc", "pl", "pt_BR", "ru", "sk", "tr", "uk", "zh_CN",
]

plural_forms = {
    "ar": "nplurals=6; plural=n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 && n%100<=99 ? 4 : 5;",
    "ca": "nplurals=2; plural=(n != 1);",
    "cs": "nplurals=3; plural=(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2;",
    "de": "nplurals=2; plural=(n != 1);",
    "el": "nplurals=2; plural=(n != 1);",
    "es": "nplurals=2; plural=(n != 1);",
    "eu": "nplurals=2; plural=(n != 1);",
    "fa": "nplurals=2; plural=(n > 1);",
    "fi": "nplurals=2; plural=(n != 1);",
    "fr": "nplurals=2; plural=(n > 1);",
    "hu": "nplurals=2; plural=(n != 1);",
    "it": "nplurals=2; plural=(n != 1);",
    "ja": "nplurals=1; plural=0;",
    "nl": "nplurals=2; plural=(n != 1);",
    "oc": "nplurals=2; plural=(n > 1);",
    "pl": "nplurals=3; plural=(n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<12 || n%100>14) ? 1 : 2);",
    "pt_BR": "nplurals=2; plural=(n > 1);",
    "ru": "nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<12 || n%100>14) ? 1 : 2);",
    "sk": "nplurals=3; plural=(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2;",
    "tr": "nplurals=2; plural=(n > 1);",
    "uk": "nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<12 || n%100>14) ? 1 : 2);",
    "zh_CN": "nplurals=1; plural=0;",
}

# Best-effort translations for every msgid currently used by the extension.
# Review before publishing if you need perfect native-language quality.
translations = {
    "Delete Permanently": {
        "ar": "احذف نهائيًا", "ca": "Suprimeix permanentment", "cs": "Trvale smazat",
        "de": "Dauerhaft löschen", "el": "Οριστική διαγραφή", "es": "Eliminar permanentemente",
        "eu": "Ezabatu betiko", "fa": "حذف دائمی", "fi": "Poista pysyvästi",
        "fr": "Supprimer définitivement", "hu": "Végleges törlés", "it": "Elimina definitivamente",
        "ja": "完全に削除", "nl": "Permanent verwijderen", "oc": "Suprimir definitivament",
        "pl": "Usuń trwale", "pt_BR": "Excluir permanentemente", "ru": "Удалить безвозвратно",
        "sk": "Natrvalo odstrániť", "tr": "Kalıcı olarak sil", "uk": "Видалити назавжди",
        "zh_CN": "永久删除",
    },
    "Delete selected items permanently": {
        "ar": "احذف العناصر المحددة نهائيًا", "ca": "Suprimeix permanentment els elements seleccionats",
        "cs": "Trvale smazat vybrané položky", "de": "Ausgewählte Elemente dauerhaft löschen",
        "el": "Οριστική διαγραφή των επιλεγμένων στοιχείων", "es": "Eliminar permanentemente los elementos seleccionados",
        "eu": "Ezabatu hautatutako elementuak betiko", "fa": "موارد انتخاب‌شده را برای همیشه حذف کن",
        "fi": "Poista valitut kohteet pysyvästi", "fr": "Supprimer définitivement les éléments sélectionnés",
        "hu": "A kijelölt elemek végleges törlése", "it": "Elimina definitivamente gli elementi selezionati",
        "ja": "選択した項目を完全に削除", "nl": "Geselecteerde items permanent verwijderen",
        "oc": "Suprimir definitivament los elements seleccionats", "pl": "Usuń zaznaczone elementy trwale",
        "pt_BR": "Excluir permanentemente os itens selecionados", "ru": "Удалить выбранные элементы безвозвратно",
        "sk": "Natrvalo odstrániť vybrané položky", "tr": "Seçili öğeleri kalıcı olarak sil",
        "uk": "Видалити вибрані елементи назавжди", "zh_CN": "永久删除所选项目",
    },
    "The following folder will be permanently deleted:": {
        "ar": "سيتم حذف المجلد التالي نهائيًا:", "ca": "Se suprimirà permanentment la carpeta següent:",
        "cs": "Následující složka bude trvale smazána:", "de": "Der folgende Ordner wird dauerhaft gelöscht:",
        "el": "Ο ακόλουθος φάκελος θα διαγραφεί οριστικά:", "es": "La siguiente carpeta se eliminará permanentemente:",
        "eu": "Honako karpeta betiko ezabatuko da:", "fa": "پوشهٔ زیر برای همیشه حذف خواهد شد:",
        "fi": "Seuraava kansio poistetaan pysyvästi:", "fr": "Le dossier suivant sera supprimé définitivement :",
        "hu": "A következő mappa véglegesen törölve lesz:", "it": "La seguente cartella verrà eliminata definitivamente:",
        "ja": "次のフォルダーは完全に削除されます:", "nl": "De volgende map wordt permanent verwijderd:",
        "oc": "Lo repertòri seguent serà suprimit definitivament :", "pl": "Następujący folder zostanie trwale usunięty:",
        "pt_BR": "A seguinte pasta será excluída permanentemente:", "ru": "Следующая папка будет удалена безвозвратно:",
        "sk": "Nasledujúci priečinok bude natrvalo odstránený:", "tr": "Aşağıdaki klasör kalıcı olarak silinecek:",
        "uk": "Наступну теку буде видалено назавжди:", "zh_CN": "以下文件夹将被永久删除：",
    },
    "The following file will be permanently deleted:": {
        "ar": "سيتم حذف الملف التالي نهائيًا:", "ca": "Se suprimirà permanentment el fitxer següent:",
        "cs": "Následující soubor bude trvale smazán:", "de": "Die folgende Datei wird dauerhaft gelöscht:",
        "el": "Το ακόλουθο αρχείο θα διαγραφεί οριστικά:", "es": "El siguiente archivo se eliminará permanentemente:",
        "eu": "Honako fitxategia betiko ezabatuko da:", "fa": "فایل زیر برای همیشه حذف خواهد شد:",
        "fi": "Seuraava tiedosto poistetaan pysyvästi:", "fr": "Le fichier suivant sera supprimé définitivement :",
        "hu": "A következő fájl véglegesen törölve lesz:", "it": "Il seguente file verrà eliminato definitivamente:",
        "ja": "次のファイルは完全に削除されます:", "nl": "Het volgende bestand wordt permanent verwijderd:",
        "oc": "Lo fichièr seguent serà suprimit definitivament :", "pl": "Następujący plik zostanie trwale usunięty:",
        "pt_BR": "O seguinte arquivo será excluído permanentemente:", "ru": "Следующий файл будет удалён безвозвратно:",
        "sk": "Nasledujúci súbor bude natrvalo odstránený:", "tr": "Aşağıdaki dosya kalıcı olarak silinecek:",
        "uk": "Наступний файл буде видалено назавжди:", "zh_CN": "以下文件将被永久删除：",
    },
    "The following files and folders will be permanently deleted:": {
        "ar": "سيتم حذف الملفات والمجلدات التالية نهائيًا:", "ca": "Se suprimiran permanentment els fitxers i carpetes següents:",
        "cs": "Následující soubory a složky budou trvale smazány:", "de": "Die folgenden Dateien und Ordner werden dauerhaft gelöscht:",
        "el": "Τα ακόλουθα αρχεία και φάκελοι θα διαγραφούν οριστικά:", "es": "Los siguientes archivos y carpetas se eliminarán permanentemente:",
        "eu": "Honako fitxategiak eta karpetak betiko ezabatuko dira:", "fa": "فایل‌ها و پوشه‌های زیر برای همیشه حذف خواهند شد:",
        "fi": "Seuraavat tiedostot ja kansiot poistetaan pysyvästi:", "fr": "Les fichiers et dossiers suivants seront supprimés définitivement :",
        "hu": "A következő fájlok és mappák véglegesen törölve lesznek:", "it": "I seguenti file e cartelle verranno eliminati definitivamente:",
        "ja": "次のファイルとフォルダーは完全に削除されます:", "nl": "De volgende bestanden en mappen worden permanent verwijderd:",
        "oc": "Los fichièrs e repertòris seguents seràn suprimits definitivament :", "pl": "Następujące pliki i foldery zostaną trwale usunięte:",
        "pt_BR": "Os seguintes arquivos e pastas serão excluídos permanentemente:", "ru": "Следующие файлы и папки будут удалены безвозвратно:",
        "sk": "Nasledujúce súbory a priečinky budú natrvalo odstránené:", "tr": "Aşağıdaki dosyalar ve klasörler kalıcı olarak silinecek:",
        "uk": "Наступні файли й теки буде видалено назавжди:", "zh_CN": "以下文件和文件夹将被永久删除：",
    },
    "The following folders will be permanently deleted:": {
        "ar": "سيتم حذف المجلدات التالية نهائيًا:", "ca": "Se suprimiran permanentment les carpetes següents:",
        "cs": "Následující složky budou trvale smazány:", "de": "Die folgenden Ordner werden dauerhaft gelöscht:",
        "el": "Οι ακόλουθοι φάκελοι θα διαγραφούν οριστικά:", "es": "Las siguientes carpetas se eliminarán permanentemente:",
        "eu": "Honako karpetak betiko ezabatuko dira:", "fa": "پوشه‌های زیر برای همیشه حذف خواهند شد:",
        "fi": "Seuraavat kansiot poistetaan pysyvästi:", "fr": "Les dossiers suivants seront supprimés définitivement :",
        "hu": "A következő mappák véglegesen törölve lesznek:", "it": "Le seguenti cartelle verranno eliminate definitivamente:",
        "ja": "次のフォルダーは完全に削除されます:", "nl": "De volgende mappen worden permanent verwijderd:",
        "oc": "Los repertòris seguents seràn suprimits definitivament :", "pl": "Następujące foldery zostaną trwale usunięte:",
        "pt_BR": "As seguintes pastas serão excluídas permanentemente:", "ru": "Следующие папки будут удалены безвозвратно:",
        "sk": "Nasledujúce priečinky budú natrvalo odstránené:", "tr": "Aşağıdaki klasörler kalıcı olarak silinecek:",
        "uk": "Наступні теки буде видалено назавжди:", "zh_CN": "以下文件夹将被永久删除：",
    },
    "The following files will be permanently deleted:": {
        "ar": "سيتم حذف الملفات التالية نهائيًا:", "ca": "Se suprimiran permanentment els fitxers següents:",
        "cs": "Následující soubory budou trvale smazány:", "de": "Die folgenden Dateien werden dauerhaft gelöscht:",
        "el": "Τα ακόλουθα αρχεία θα διαγραφούν οριστικά:", "es": "Los siguientes archivos se eliminarán permanentemente:",
        "eu": "Honako fitxategiak betiko ezabatuko dira:", "fa": "فایل‌های زیر برای همیشه حذف خواهند شد:",
        "fi": "Seuraavat tiedostot poistetaan pysyvästi:", "fr": "Les fichiers suivants seront supprimés définitivement :",
        "hu": "A következő fájlok véglegesen törölve lesznek:", "it": "I seguenti file verranno eliminati definitivamente:",
        "ja": "次のファイルは完全に削除されます:", "nl": "De volgende bestanden worden permanent verwijderd:",
        "oc": "Los fichièrs seguents seràn suprimits definitivament :", "pl": "Następujące pliki zostaną trwale usunięte:",
        "pt_BR": "Os seguintes arquivos serão excluídos permanentemente:", "ru": "Следующие файлы будут удалены безвозвратно:",
        "sk": "Nasledujúce súbory budú natrvalo odstránené:", "tr": "Aşağıdaki dosyalar kalıcı olarak silinecek:",
        "uk": "Наступні файли буде видалено назавжди:", "zh_CN": "以下文件将被永久删除：",
    },
    "Delete Permanently?": {
        "ar": "حذف نهائي؟", "ca": "Voleu suprimir permanentment?", "cs": "Trvale smazat?",
        "de": "Dauerhaft löschen?", "el": "Οριστική διαγραφή;", "es": "¿Eliminar permanentemente?",
        "eu": "Betiko ezabatu?", "fa": "برای همیشه حذف شود؟", "fi": "Poistetaanko pysyvästi?",
        "fr": "Supprimer définitivement ?", "hu": "Végleges törlés?", "it": "Eliminare definitivamente?",
        "ja": "完全に削除しますか?", "nl": "Permanent verwijderen?", "oc": "Suprimir definitivament ?",
        "pl": "Usunąć trwale?", "pt_BR": "Excluir permanentemente?", "ru": "Удалить безвозвратно?",
        "sk": "Natrvalo odstrániť?", "tr": "Kalıcı olarak silinsin mi?", "uk": "Видалити назавжди?",
        "zh_CN": "永久删除？",
    },
    "Size: %s": {
        "ar": "الحجم: %s", "ca": "Mida: %s", "cs": "Velikost: %s", "de": "Größe: %s",
        "el": "Μέγεθος: %s", "es": "Tamaño: %s", "eu": "Tamaina: %s", "fa": "اندازه: %s",
        "fi": "Koko: %s", "fr": "Taille : %s", "hu": "Méret: %s", "it": "Dimensione: %s",
        "ja": "サイズ: %s", "nl": "Grootte: %s", "oc": "Talha : %s", "pl": "Rozmiar: %s",
        "pt_BR": "Tamanho: %s", "ru": "Размер: %s", "sk": "Veľkosť: %s", "tr": "Boyut: %s",
        "uk": "Розмір: %s", "zh_CN": "大小：%s",
    },
    "_Cancel": {
        "ar": "_إلغاء", "ca": "_Cancel·la", "cs": "_Zrušit", "de": "_Abbrechen",
        "el": "_Ακύρωση", "es": "_Cancelar", "eu": "_Utzi", "fa": "_لغو",
        "fi": "_Peru", "fr": "_Annuler", "hu": "_Mégse", "it": "_Annulla",
        "ja": "_キャンセル", "nl": "_Annuleren", "oc": "_Anullar", "pl": "_Anuluj",
        "pt_BR": "_Cancelar", "ru": "_Отмена", "sk": "_Zrušiť", "tr": "_İptal",
        "uk": "_Скасувати", "zh_CN": "_取消",
    },
    "Delete _Permanently": {
        "ar": "احذف _نهائيًا", "ca": "Suprimeix _permanentment", "cs": "Smazat _trvale",
        "de": "_Dauerhaft löschen", "el": "Διαγραφή _οριστικά", "es": "Eliminar _permanentemente",
        "eu": "Ezabatu _betiko", "fa": "حذف _دائمی", "fi": "Poista _pysyvästi",
        "fr": "Supprimer _définitivement", "hu": "_Végleges törlés", "it": "Elimina _definitivamente",
        "ja": "_完全に削除", "nl": "_Permanent verwijderen", "oc": "Suprimir _definitivament",
        "pl": "Usuń _trwale", "pt_BR": "Excluir _permanentemente", "ru": "Удалить _безвозвратно",
        "sk": "Odstrániť _natrvalo", "tr": "_Kalıcı olarak sil", "uk": "Видалити _назавжди",
        "zh_CN": "永久删除(_P)",
    },
    "Deleting Files": {
        "ar": "جارٍ حذف الملفات", "ca": "S'estan suprimint fitxers", "cs": "Mazání souborů",
        "de": "Dateien werden gelöscht", "el": "Διαγραφή αρχείων", "es": "Eliminando archivos",
        "eu": "Fitxategiak ezabatzen", "fa": "در حال حذف فایل‌ها", "fi": "Poistetaan tiedostoja",
        "fr": "Suppression des fichiers", "hu": "Fájlok törlése", "it": "Eliminazione dei file",
        "ja": "ファイルを削除しています", "nl": "Bestanden verwijderen", "oc": "Supression dels fichièrs",
        "pl": "Usuwanie plików", "pt_BR": "Excluindo arquivos", "ru": "Удаление файлов",
        "sk": "Odstraňovanie súborov", "tr": "Dosyalar siliniyor", "uk": "Видалення файлів",
        "zh_CN": "正在删除文件",
    },
    "Canceling...": {
        "ar": "جارٍ الإلغاء...", "ca": "S'està cancel·lant...", "cs": "Ruší se...",
        "de": "Wird abgebrochen …", "el": "Ακύρωση...", "es": "Cancelando...",
        "eu": "Bertan behera uzten...", "fa": "در حال لغو...", "fi": "Perutaan...",
        "fr": "Annulation…", "hu": "Megszakítás...", "it": "Annullamento...",
        "ja": "キャンセルしています...", "nl": "Annuleren...", "oc": "Anullacion...",
        "pl": "Anulowanie...", "pt_BR": "Cancelando...", "ru": "Отмена...",
        "sk": "Ruší sa...", "tr": "İptal ediliyor...", "uk": "Скасування...",
        "zh_CN": "正在取消...",
    },
    "Deletion canceled.": {
        "ar": "تم إلغاء الحذف.", "ca": "S'ha cancel·lat la supressió.", "cs": "Mazání bylo zrušeno.",
        "de": "Löschen abgebrochen.", "el": "Η διαγραφή ακυρώθηκε.", "es": "Eliminación cancelada.",
        "eu": "Ezabatzea bertan behera utzi da.", "fa": "حذف لغو شد.", "fi": "Poisto peruttiin.",
        "fr": "Suppression annulée.", "hu": "Törlés megszakítva.", "it": "Eliminazione annullata.",
        "ja": "削除をキャンセルしました。", "nl": "Verwijderen geannuleerd.", "oc": "Supression anullada.",
        "pl": "Usuwanie anulowane.", "pt_BR": "Exclusão cancelada.", "ru": "Удаление отменено.",
        "sk": "Odstraňovanie bolo zrušené.", "tr": "Silme iptal edildi.", "uk": "Видалення скасовано.",
        "zh_CN": "删除已取消。",
    },
    "Deletion finished.": {
        "ar": "اكتمل الحذف.", "ca": "Supressió finalitzada.", "cs": "Mazání dokončeno.",
        "de": "Löschen abgeschlossen.", "el": "Η διαγραφή ολοκληρώθηκε.", "es": "Eliminación finalizada.",
        "eu": "Ezabatzea amaitu da.", "fa": "حذف کامل شد.", "fi": "Poisto valmis.",
        "fr": "Suppression terminée.", "hu": "Törlés befejezve.", "it": "Eliminazione completata.",
        "ja": "削除が完了しました。", "nl": "Verwijderen voltooid.", "oc": "Supression acabada.",
        "pl": "Usuwanie zakończone.", "pt_BR": "Exclusão concluída.", "ru": "Удаление завершено.",
        "sk": "Odstraňovanie dokončené.", "tr": "Silme tamamlandı.", "uk": "Видалення завершено.",
        "zh_CN": "删除完成。",
    },
    "Deleting:": {
        "ar": "جارٍ حذف:", "ca": "S'està suprimint:", "cs": "Maže se:", "de": "Löschen:",
        "el": "Διαγραφή:", "es": "Eliminando:", "eu": "Ezabatzen:", "fa": "در حال حذف:",
        "fi": "Poistetaan:", "fr": "Suppression :", "hu": "Törlés:", "it": "Eliminazione:",
        "ja": "削除中:", "nl": "Verwijderen:", "oc": "Supression :", "pl": "Usuwanie:",
        "pt_BR": "Excluindo:", "ru": "Удаление:", "sk": "Odstraňuje sa:", "tr": "Siliniyor:",
        "uk": "Видалення:", "zh_CN": "正在删除：",
    },
    "Files: %(done)d / %(total)d": {
        "ar": "الملفات: %(done)d / %(total)d", "ca": "Fitxers: %(done)d / %(total)d",
        "cs": "Soubory: %(done)d / %(total)d", "de": "Dateien: %(done)d / %(total)d",
        "el": "Αρχεία: %(done)d / %(total)d", "es": "Archivos: %(done)d / %(total)d",
        "eu": "Fitxategiak: %(done)d / %(total)d", "fa": "فایل‌ها: %(done)d / %(total)d",
        "fi": "Tiedostot: %(done)d / %(total)d", "fr": "Fichiers : %(done)d / %(total)d",
        "hu": "Fájlok: %(done)d / %(total)d", "it": "File: %(done)d / %(total)d",
        "ja": "ファイル: %(done)d / %(total)d", "nl": "Bestanden: %(done)d / %(total)d",
        "oc": "Fichièrs : %(done)d / %(total)d", "pl": "Pliki: %(done)d / %(total)d",
        "pt_BR": "Arquivos: %(done)d / %(total)d", "ru": "Файлы: %(done)d / %(total)d",
        "sk": "Súbory: %(done)d / %(total)d", "tr": "Dosyalar: %(done)d / %(total)d",
        "uk": "Файли: %(done)d / %(total)d", "zh_CN": "文件：%(done)d / %(total)d",
    },
    "Folders: %(done)d / %(total)d": {
        "ar": "المجلدات: %(done)d / %(total)d", "ca": "Carpetes: %(done)d / %(total)d",
        "cs": "Složky: %(done)d / %(total)d", "de": "Ordner: %(done)d / %(total)d",
        "el": "Φάκελοι: %(done)d / %(total)d", "es": "Carpetas: %(done)d / %(total)d",
        "eu": "Karpetak: %(done)d / %(total)d", "fa": "پوشه‌ها: %(done)d / %(total)d",
        "fi": "Kansiot: %(done)d / %(total)d", "fr": "Dossiers : %(done)d / %(total)d",
        "hu": "Mappák: %(done)d / %(total)d", "it": "Cartelle: %(done)d / %(total)d",
        "ja": "フォルダー: %(done)d / %(total)d", "nl": "Mappen: %(done)d / %(total)d",
        "oc": "Repertòris : %(done)d / %(total)d", "pl": "Foldery: %(done)d / %(total)d",
        "pt_BR": "Pastas: %(done)d / %(total)d", "ru": "Папки: %(done)d / %(total)d",
        "sk": "Priečinky: %(done)d / %(total)d", "tr": "Klasörler: %(done)d / %(total)d",
        "uk": "Теки: %(done)d / %(total)d", "zh_CN": "文件夹：%(done)d / %(total)d",
    },
    "Size: %(done)s / %(total)s": {
        "ar": "الحجم: %(done)s / %(total)s", "ca": "Mida: %(done)s / %(total)s",
        "cs": "Velikost: %(done)s / %(total)s", "de": "Größe: %(done)s / %(total)s",
        "el": "Μέγεθος: %(done)s / %(total)s", "es": "Tamaño: %(done)s / %(total)s",
        "eu": "Tamaina: %(done)s / %(total)s", "fa": "اندازه: %(done)s / %(total)s",
        "fi": "Koko: %(done)s / %(total)s", "fr": "Taille : %(done)s / %(total)s",
        "hu": "Méret: %(done)s / %(total)s", "it": "Dimensione: %(done)s / %(total)s",
        "ja": "サイズ: %(done)s / %(total)s", "nl": "Grootte: %(done)s / %(total)s",
        "oc": "Talha : %(done)s / %(total)s", "pl": "Rozmiar: %(done)s / %(total)s",
        "pt_BR": "Tamanho: %(done)s / %(total)s", "ru": "Размер: %(done)s / %(total)s",
        "sk": "Veľkosť: %(done)s / %(total)s", "tr": "Boyut: %(done)s / %(total)s",
        "uk": "Розмір: %(done)s / %(total)s", "zh_CN": "大小：%(done)s / %(total)s",
    },
    "Estimated time remaining: %d s": {
        "ar": "الوقت المتبقي المقدر: %d ث", "ca": "Temps restant estimat: %d s",
        "cs": "Odhadovaný zbývající čas: %d s", "de": "Geschätzte verbleibende Zeit: %d s",
        "el": "Εκτιμώμενος χρόνος που απομένει: %d δ", "es": "Tiempo restante estimado: %d s",
        "eu": "Geratzen den denbora estimatua: %d s", "fa": "زمان باقی‌ماندهٔ تخمینی: %d ثانیه",
        "fi": "Arvioitu jäljellä oleva aika: %d s", "fr": "Temps restant estimé : %d s",
        "hu": "Becsült hátralévő idő: %d s", "it": "Tempo rimanente stimato: %d s",
        "ja": "推定残り時間: %d 秒", "nl": "Geschatte resterende tijd: %d s",
        "oc": "Temps restant estimat : %d s", "pl": "Szacowany pozostały czas: %d s",
        "pt_BR": "Tempo restante estimado: %d s", "ru": "Оставшееся время: %d с",
        "sk": "Odhadovaný zostávajúci čas: %d s", "tr": "Tahmini kalan süre: %d sn",
        "uk": "Орієнтовний час, що залишився: %d с", "zh_CN": "预计剩余时间：%d 秒",
    },
}

# Additional strings used by blacklist/whitelist and permission warnings.
translations.update({'Critical Delete Warning': {'ar': 'تحذير حذف خطير',
                             'ca': 'Avís crític de supressió',
                             'cs': 'Kritické varování při mazání',
                             'de': 'Kritische Löschwarnung',
                             'el': 'Κρίσιμη προειδοποίηση διαγραφής',
                             'es': 'Advertencia crítica de eliminación',
                             'eu': 'Ezabatzeko abisu kritikoa',
                             'fa': 'هشدار مهم حذف',
                             'fi': 'Kriittinen poistovaroitus',
                             'fr': 'Avertissement critique de suppression',
                             'hu': 'Kritikus törlési figyelmeztetés',
                             'it': 'Avviso critico di eliminazione',
                             'ja': '重大な削除警告',
                             'nl': 'Kritieke verwijderingswaarschuwing',
                             'oc': 'Avertiment critic de supression',
                             'pl': 'Krytyczne ostrzeżenie o usuwaniu',
                             'pt_BR': 'Aviso crítico de exclusão',
                             'ru': 'Критическое предупреждение об удалении',
                             'sk': 'Kritické upozornenie pri odstraňovaní',
                             'tr': 'Kritik silme uyarısı',
                             'uk': 'Критичне попередження про видалення',
                             'zh_CN': '严重删除警告'},
 'This item requires extra confirmation before deletion.': {'ar': 'يتطلب هذا العنصر تأكيدًا إضافيًا قبل الحذف.',
                                                            'ca': 'Aquest element requereix una confirmació addicional '
                                                                  'abans de suprimir-lo.',
                                                            'cs': 'Tato položka vyžaduje před smazáním dodatečné '
                                                                  'potvrzení.',
                                                            'de': 'Dieses Element erfordert vor dem Löschen eine '
                                                                  'zusätzliche Bestätigung.',
                                                            'el': 'Αυτό το στοιχείο απαιτεί πρόσθετη επιβεβαίωση πριν '
                                                                  'από τη διαγραφή.',
                                                            'es': 'Este elemento requiere confirmación adicional antes '
                                                                  'de eliminarse.',
                                                            'eu': 'Elementu honek berrespen gehigarria behar du '
                                                                  'ezabatu aurretik.',
                                                            'fa': 'این مورد پیش از حذف به تأیید اضافی نیاز دارد.',
                                                            'fi': 'Tämä kohde vaatii lisävahvistuksen ennen '
                                                                  'poistamista.',
                                                            'fr': 'Cet élément nécessite une confirmation '
                                                                  'supplémentaire avant suppression.',
                                                            'hu': 'Ez az elem törlés előtt további megerősítést '
                                                                  'igényel.',
                                                            'it': 'Questo elemento richiede una conferma aggiuntiva '
                                                                  "prima dell'eliminazione.",
                                                            'ja': 'この項目を削除するには追加の確認が必要です。',
                                                            'nl': 'Dit item vereist extra bevestiging voordat het '
                                                                  'wordt verwijderd.',
                                                            'oc': 'Aqueste element necessita una confirmacion '
                                                                  'suplementària abans la supression.',
                                                            'pl': 'Ten element wymaga dodatkowego potwierdzenia przed '
                                                                  'usunięciem.',
                                                            'pt_BR': 'Este item requer confirmação adicional antes da '
                                                                     'exclusão.',
                                                            'ru': 'Для этого элемента требуется дополнительное '
                                                                  'подтверждение перед удалением.',
                                                            'sk': 'Táto položka vyžaduje pred odstránením dodatočné '
                                                                  'potvrdenie.',
                                                            'tr': 'Bu öğeyi silmeden önce ek onay gerekir.',
                                                            'uk': 'Цей елемент потребує додаткового підтвердження '
                                                                  'перед видаленням.',
                                                            'zh_CN': '删除此项目前需要额外确认。'},
 'It matches a delete warning rule. Delete it only if you are sure.': {'ar': 'يطابق قاعدة تحذير حذف. احذفه فقط إذا كنت '
                                                                             'متأكدًا.',
                                                                       'ca': "Coincideix amb una regla d'avís de "
                                                                             "supressió. Suprimiu-lo només si n'esteu "
                                                                             'segur.',
                                                                       'cs': 'Odpovídá pravidlu varování při mazání. '
                                                                             'Smažte jej pouze, pokud jste si jistí.',
                                                                       'de': 'Es entspricht einer Löschwarnregel. '
                                                                             'Lösche es nur, wenn du sicher bist.',
                                                                       'el': 'Ταιριάζει με κανόνα προειδοποίησης '
                                                                             'διαγραφής. Διαγράψτε το μόνο αν είστε '
                                                                             'σίγουροι.',
                                                                       'es': 'Coincide con una regla de advertencia de '
                                                                             'eliminación. Elimínelo solo si está '
                                                                             'seguro.',
                                                                       'eu': 'Ezabatzeko abisu-arau batekin bat dator. '
                                                                             'Ezabatu ziur bazaude bakarrik.',
                                                                       'fa': 'با یک قانون هشدار حذف مطابقت دارد. فقط '
                                                                             'اگر مطمئن هستید آن را حذف کنید.',
                                                                       'fi': 'Se vastaa poistovaroitussääntöä. Poista '
                                                                             'vain, jos olet varma.',
                                                                       'fr': 'Il correspond à une règle '
                                                                             "d'avertissement de suppression. "
                                                                             'Supprimez-le seulement si vous êtes sûr.',
                                                                       'hu': 'Megfelel egy törlési figyelmeztetési '
                                                                             'szabálynak. Csak akkor törölje, ha '
                                                                             'biztos benne.',
                                                                       'it': 'Corrisponde a una regola di avviso di '
                                                                             'eliminazione. Eliminalo solo se sei '
                                                                             'sicuro.',
                                                                       'ja': '削除警告ルールに一致しています。確実な場合のみ削除してください。',
                                                                       'nl': 'Het komt overeen met een '
                                                                             'verwijderingswaarschuwingsregel. '
                                                                             'Verwijder het alleen als u zeker bent.',
                                                                       'oc': "Correspond a una règla d'avertiment de "
                                                                             'supression. Suprimissètz-lo sonque se '
                                                                             'sètz segur.',
                                                                       'pl': 'Pasuje do reguły ostrzegania o usuwaniu. '
                                                                             'Usuń tylko, jeśli masz pewność.',
                                                                       'pt_BR': 'Ele corresponde a uma regra de aviso '
                                                                                'de exclusão. Exclua somente se tiver '
                                                                                'certeza.',
                                                                       'ru': 'Он соответствует правилу предупреждения '
                                                                             'об удалении. Удаляйте только если '
                                                                             'уверены.',
                                                                       'sk': 'Zodpovedá pravidlu upozornenia na '
                                                                             'odstránenie. Odstráňte ho iba vtedy, ak '
                                                                             'ste si istí.',
                                                                       'tr': 'Bir silme uyarı kuralıyla eşleşiyor. '
                                                                             'Yalnızca eminseniz silin.',
                                                                       'uk': 'Він відповідає правилу попередження про '
                                                                             'видалення. Видаляйте лише якщо впевнені.',
                                                                       'zh_CN': '它匹配删除警告规则。仅在确定时删除。'},
 'I understand the risk.': {'ar': 'أفهم المخاطر.',
                            'ca': 'Entenc el risc.',
                            'cs': 'Rozumím riziku.',
                            'de': 'Ich verstehe das Risiko.',
                            'el': 'Κατανοώ τον κίνδυνο.',
                            'es': 'Entiendo el riesgo.',
                            'eu': 'Arriskua ulertzen dut.',
                            'fa': 'خطر را درک می\u200cکنم.',
                            'fi': 'Ymmärrän riskin.',
                            'fr': 'Je comprends le risque.',
                            'hu': 'Megértem a kockázatot.',
                            'it': 'Comprendo il rischio.',
                            'ja': 'リスクを理解しています。',
                            'nl': 'Ik begrijp het risico.',
                            'oc': 'Compreni lo risc.',
                            'pl': 'Rozumiem ryzyko.',
                            'pt_BR': 'Entendo o risco.',
                            'ru': 'Я понимаю риск.',
                            'sk': 'Rozumiem riziku.',
                            'tr': 'Riski anlıyorum.',
                            'uk': 'Я розумію ризик.',
                            'zh_CN': '我了解风险。'},
 'Permission Warning': {'ar': 'تحذير أذونات',
                        'ca': 'Avís de permisos',
                        'cs': 'Varování oprávnění',
                        'de': 'Berechtigungswarnung',
                        'el': 'Προειδοποίηση δικαιωμάτων',
                        'es': 'Advertencia de permisos',
                        'eu': 'Baimenen abisua',
                        'fa': 'هشدار مجوز',
                        'fi': 'Käyttöoikeusvaroitus',
                        'fr': "Avertissement d'autorisation",
                        'hu': 'Jogosultsági figyelmeztetés',
                        'it': 'Avviso sui permessi',
                        'ja': '権限の警告',
                        'nl': 'Machtigingswaarschuwing',
                        'oc': "Avertiment d'autorizacion",
                        'pl': 'Ostrzeżenie o uprawnieniach',
                        'pt_BR': 'Aviso de permissão',
                        'ru': 'Предупреждение о правах доступа',
                        'sk': 'Upozornenie na oprávnenia',
                        'tr': 'İzin uyarısı',
                        'uk': 'Попередження про права доступу',
                        'zh_CN': '权限警告'},
 'Some selected items may not be deletable.': {'ar': 'قد لا يمكن حذف بعض العناصر المحددة.',
                                               'ca': 'És possible que alguns elements seleccionats no es puguin '
                                                     'suprimir.',
                                               'cs': 'Některé vybrané položky nemusí být možné smazat.',
                                               'de': 'Einige ausgewählte Elemente können möglicherweise nicht gelöscht '
                                                     'werden.',
                                               'el': 'Ορισμένα επιλεγμένα στοιχεία ενδέχεται να μην μπορούν να '
                                                     'διαγραφούν.',
                                               'es': 'Es posible que algunos elementos seleccionados no se puedan '
                                                     'eliminar.',
                                               'eu': 'Baliteke hautatutako elementu batzuk ezabatu ezin izatea.',
                                               'fa': 'ممکن است برخی موارد انتخاب\u200cشده قابل حذف نباشند.',
                                               'fi': 'Joitakin valittuja kohteita ei ehkä voi poistaa.',
                                               'fr': 'Certains éléments sélectionnés ne peuvent peut-être pas être '
                                                     'supprimés.',
                                               'hu': 'Előfordulhat, hogy néhány kijelölt elem nem törölhető.',
                                               'it': 'Alcuni elementi selezionati potrebbero non essere eliminabili.',
                                               'ja': '選択した項目の一部は削除できない可能性があります。',
                                               'nl': 'Sommige geselecteerde items kunnen mogelijk niet worden '
                                                     'verwijderd.',
                                               'oc': "D'unes elements seleccionats pòdon èsser impossibles de "
                                                     'suprimir.',
                                               'pl': 'Niektórych zaznaczonych elementów może nie dać się usunąć.',
                                               'pt_BR': 'Alguns itens selecionados talvez não possam ser excluídos.',
                                               'ru': 'Некоторые выбранные элементы могут быть недоступны для удаления.',
                                               'sk': 'Niektoré vybrané položky možno nebude možné odstrániť.',
                                               'tr': 'Seçili bazı öğeler silinemeyebilir.',
                                               'uk': 'Деякі вибрані елементи може бути неможливо видалити.',
                                               'zh_CN': '某些选定项目可能无法删除。'},
 'You may not have permission to delete these items. The operation may fail.': {'ar': 'قد لا تملك إذنًا لحذف هذه '
                                                                                      'العناصر. قد تفشل العملية.',
                                                                                'ca': 'Potser no teniu permís per '
                                                                                      'suprimir aquests elements. '
                                                                                      "L'operació pot fallar.",
                                                                                'cs': 'Možná nemáte oprávnění tyto '
                                                                                      'položky smazat. Operace může '
                                                                                      'selhat.',
                                                                                'de': 'Du hast möglicherweise keine '
                                                                                      'Berechtigung, diese Elemente zu '
                                                                                      'löschen. Der Vorgang kann '
                                                                                      'fehlschlagen.',
                                                                                'el': 'Ενδέχεται να μην έχετε δικαίωμα '
                                                                                      'να διαγράψετε αυτά τα στοιχεία. '
                                                                                      'Η λειτουργία μπορεί να '
                                                                                      'αποτύχει.',
                                                                                'es': 'Puede que no tenga permiso para '
                                                                                      'eliminar estos elementos. La '
                                                                                      'operación puede fallar.',
                                                                                'eu': 'Baliteke elementu hauek '
                                                                                      'ezabatzeko baimenik ez izatea. '
                                                                                      'Eragiketak huts egin dezake.',
                                                                                'fa': 'ممکن است اجازه حذف این موارد را '
                                                                                      'نداشته باشید. عملیات ممکن است '
                                                                                      'شکست بخورد.',
                                                                                'fi': 'Sinulla ei ehkä ole oikeuksia '
                                                                                      'poistaa näitä kohteita. '
                                                                                      'Toiminto voi epäonnistua.',
                                                                                'fr': "Vous n'avez peut-être pas "
                                                                                      "l'autorisation de supprimer ces "
                                                                                      "éléments. L'opération peut "
                                                                                      'échouer.',
                                                                                'hu': 'Lehet, hogy nincs jogosultsága '
                                                                                      'ezeknek az elemeknek a '
                                                                                      'törlésére. A művelet sikertelen '
                                                                                      'lehet.',
                                                                                'it': 'Potresti non avere il permesso '
                                                                                      'di eliminare questi elementi. '
                                                                                      "L'operazione potrebbe non "
                                                                                      'riuscire.',
                                                                                'ja': 'これらの項目を削除する権限がない可能性があります。操作は失敗する場合があります。',
                                                                                'nl': 'U hebt mogelijk geen '
                                                                                      'toestemming om deze items te '
                                                                                      'verwijderen. De bewerking kan '
                                                                                      'mislukken.',
                                                                                'oc': "Benlèu avètz pas l'autorizacion "
                                                                                      'de suprimir aquestes elements. '
                                                                                      "L'operacion pòt fracassar.",
                                                                                'pl': 'Możesz nie mieć uprawnień do '
                                                                                      'usunięcia tych elementów. '
                                                                                      'Operacja może się nie powieść.',
                                                                                'pt_BR': 'Talvez você não tenha '
                                                                                         'permissão para excluir estes '
                                                                                         'itens. A operação pode '
                                                                                         'falhar.',
                                                                                'ru': 'У вас может не быть прав на '
                                                                                      'удаление этих элементов. '
                                                                                      'Операция может завершиться '
                                                                                      'ошибкой.',
                                                                                'sk': 'Možno nemáte oprávnenie '
                                                                                      'odstrániť tieto položky. '
                                                                                      'Operácia môže zlyhať.',
                                                                                'tr': 'Bu öğeleri silme izniniz '
                                                                                      'olmayabilir. İşlem başarısız '
                                                                                      'olabilir.',
                                                                                'uk': 'Можливо, у вас немає прав для '
                                                                                      'видалення цих елементів. '
                                                                                      'Операція може завершитися '
                                                                                      'помилкою.',
                                                                                'zh_CN': '你可能没有删除这些项目的权限。操作可能会失败。'},
 'Try to delete anyway.': {'ar': 'حاول الحذف على أي حال.',
                           'ca': 'Intenta suprimir-ho igualment.',
                           'cs': 'Přesto se pokusit smazat.',
                           'de': 'Trotzdem versuchen zu löschen.',
                           'el': "Προσπάθεια διαγραφής παρ' όλα αυτά.",
                           'es': 'Intentar eliminar de todos modos.',
                           'eu': 'Saiatu hala ere ezabatzen.',
                           'fa': 'با این حال حذف را امتحان کن.',
                           'fi': 'Yritä silti poistaa.',
                           'fr': 'Essayer de supprimer quand même.',
                           'hu': 'Törlés megpróbálása így is.',
                           'it': 'Prova comunque a eliminare.',
                           'ja': 'それでも削除を試みる。',
                           'nl': 'Toch proberen te verwijderen.',
                           'oc': 'Ensajar de suprimir çaquelà.',
                           'pl': 'Spróbuj mimo to usunąć.',
                           'pt_BR': 'Tentar excluir mesmo assim.',
                           'ru': 'Все равно попытаться удалить.',
                           'sk': 'Aj tak sa pokúsiť odstrániť.',
                           'tr': 'Yine de silmeyi dene.',
                           'uk': 'Усе одно спробувати видалити.',
                           'zh_CN': '仍然尝试删除。'}})


# Additional strings used by the unified warning flow and console messages.
translations.update({'Warning: Deletion requires additional confirmation.': {'ar': 'تحذير: يتطلب الحذف تأكيدًا إضافيًا.',
                                                         'ca': 'Avís: la supressió requereix una confirmació '
                                                               'addicional.',
                                                         'cs': 'Varování: odstranění vyžaduje dodatečné potvrzení.',
                                                         'de': 'Warnung: Das Löschen erfordert eine zusätzliche '
                                                               'Bestätigung.',
                                                         'el': 'Προειδοποίηση: η διαγραφή απαιτεί πρόσθετη '
                                                               'επιβεβαίωση.',
                                                         'es': 'Advertencia: la eliminación requiere confirmación '
                                                               'adicional.',
                                                         'eu': 'Abisua: ezabatzeko berrespen gehigarria behar da.',
                                                         'fa': 'هشدار: حذف به تأیید اضافی نیاز دارد.',
                                                         'fi': 'Varoitus: poistaminen vaatii lisävahvistuksen.',
                                                         'fr': 'Avertissement : la suppression nécessite une '
                                                               'confirmation supplémentaire.',
                                                         'hu': 'Figyelmeztetés: a törlés további megerősítést igényel.',
                                                         'it': "Avviso: l'eliminazione richiede una conferma "
                                                               'aggiuntiva.',
                                                         'ja': '警告: 削除には追加の確認が必要です。',
                                                         'nl': 'Waarschuwing: verwijderen vereist extra bevestiging.',
                                                         'oc': 'Avertiment : la supression necessita una confirmacion '
                                                               'suplementària.',
                                                         'pl': 'Ostrzeżenie: usunięcie wymaga dodatkowego '
                                                               'potwierdzenia.',
                                                         'pt_BR': 'Aviso: a exclusão requer confirmação adicional.',
                                                         'ru': 'Предупреждение: удаление требует дополнительного '
                                                               'подтверждения.',
                                                         'sk': 'Upozornenie: odstránenie vyžaduje dodatočné '
                                                               'potvrdenie.',
                                                         'tr': 'Uyarı: silme işlemi ek onay gerektirir.',
                                                         'uk': 'Попередження: видалення потребує додаткового '
                                                               'підтвердження.',
                                                         'zh_CN': '警告：删除需要额外确认。'},
 'I understand the risk.': {'ar': 'أفهم المخاطر.',
                            'ca': 'Entenc el risc.',
                            'cs': 'Rozumím riziku.',
                            'de': 'Ich verstehe das Risiko.',
                            'el': 'Κατανοώ τον κίνδυνο.',
                            'es': 'Entiendo el riesgo.',
                            'eu': 'Arriskua ulertzen dut.',
                            'fa': 'خطر را درک می\u200cکنم.',
                            'fi': 'Ymmärrän riskin.',
                            'fr': 'Je comprends le risque.',
                            'hu': 'Megértem a kockázatot.',
                            'it': 'Comprendo il rischio.',
                            'ja': 'リスクを理解しています。',
                            'nl': 'Ik begrijp het risico.',
                            'oc': 'Compreni lo risc.',
                            'pl': 'Rozumiem ryzyko.',
                            'pt_BR': 'Entendo o risco.',
                            'ru': 'Я понимаю риск.',
                            'sk': 'Rozumiem riziku.',
                            'tr': 'Riski anlıyorum.',
                            'uk': 'Я розумію ризик.',
                            'zh_CN': '我了解风险。'},
 'Failed to read path rules file: %s: %s': {'ar': 'فشل في قراءة ملف قواعد المسار: %s: %s',
                                            'ca': "No s'ha pogut llegir el fitxer de regles de camins: %s: %s",
                                            'cs': 'Nepodařilo se přečíst soubor pravidel cest: %s: %s',
                                            'de': 'Pfadregeldatei konnte nicht gelesen werden: %s: %s',
                                            'el': 'Αποτυχία ανάγνωσης αρχείου κανόνων διαδρομών: %s: %s',
                                            'es': 'No se pudo leer el archivo de reglas de rutas: %s: %s',
                                            'eu': 'Ezin izan da bide-arauen fitxategia irakurri: %s: %s',
                                            'fa': 'خواندن فایل قوانین مسیر ناموفق بود: %s: %s',
                                            'fi': 'Polkusääntötiedoston lukeminen epäonnistui: %s: %s',
                                            'fr': 'Impossible de lire le fichier de règles de chemins : %s : %s',
                                            'hu': 'Nem sikerült olvasni az útvonyszabály-fájlt: %s: %s',
                                            'it': 'Impossibile leggere il file delle regole dei percorsi: %s: %s',
                                            'ja': 'パスルールファイルを読み取れませんでした: %s: %s',
                                            'nl': 'Kan padregelbestand niet lezen: %s: %s',
                                            'oc': 'Impossible de legir lo fichièr de règlas de camins : %s : %s',
                                            'pl': 'Nie udało się odczytać pliku reguł ścieżek: %s: %s',
                                            'pt_BR': 'Falha ao ler o arquivo de regras de caminhos: %s: %s',
                                            'ru': 'Не удалось прочитать файл правил путей: %s: %s',
                                            'sk': 'Nepodarilo sa prečítať súbor pravidiel ciest: %s: %s',
                                            'tr': 'Yol kuralları dosyası okunamadı: %s: %s',
                                            'uk': 'Не вдалося прочитати файл правил шляхів: %s: %s',
                                            'zh_CN': '无法读取路径规则文件：%s：%s'},
 'Failed to delete file: %s: %s': {'ar': 'فشل حذف الملف: %s: %s',
                                   'ca': "No s'ha pogut suprimir el fitxer: %s: %s",
                                   'cs': 'Nepodařilo se smazat soubor: %s: %s',
                                   'de': 'Datei konnte nicht gelöscht werden: %s: %s',
                                   'el': 'Αποτυχία διαγραφής αρχείου: %s: %s',
                                   'es': 'No se pudo eliminar el archivo: %s: %s',
                                   'eu': 'Ezin izan da fitxategia ezabatu: %s: %s',
                                   'fa': 'حذف فایل ناموفق بود: %s: %s',
                                   'fi': 'Tiedoston poistaminen epäonnistui: %s: %s',
                                   'fr': 'Impossible de supprimer le fichier : %s : %s',
                                   'hu': 'Nem sikerült törölni a fájlt: %s: %s',
                                   'it': 'Impossibile eliminare il file: %s: %s',
                                   'ja': 'ファイルを削除できませんでした: %s: %s',
                                   'nl': 'Kan bestand niet verwijderen: %s: %s',
                                   'oc': 'Impossible de suprimir lo fichièr : %s : %s',
                                   'pl': 'Nie udało się usunąć pliku: %s: %s',
                                   'pt_BR': 'Falha ao excluir arquivo: %s: %s',
                                   'ru': 'Не удалось удалить файл: %s: %s',
                                   'sk': 'Nepodarilo sa odstrániť súbor: %s: %s',
                                   'tr': 'Dosya silinemedi: %s: %s',
                                   'uk': 'Не вдалося видалити файл: %s: %s',
                                   'zh_CN': '无法删除文件：%s：%s'},
 'Failed to delete folder: %s: %s': {'ar': 'فشل حذف المجلد: %s: %s',
                                     'ca': "No s'ha pogut suprimir la carpeta: %s: %s",
                                     'cs': 'Nepodařilo se smazat složku: %s: %s',
                                     'de': 'Ordner konnte nicht gelöscht werden: %s: %s',
                                     'el': 'Αποτυχία διαγραφής φακέλου: %s: %s',
                                     'es': 'No se pudo eliminar la carpeta: %s: %s',
                                     'eu': 'Ezin izan da karpeta ezabatu: %s: %s',
                                     'fa': 'حذف پوشه ناموفق بود: %s: %s',
                                     'fi': 'Kansion poistaminen epäonnistui: %s: %s',
                                     'fr': 'Impossible de supprimer le dossier : %s : %s',
                                     'hu': 'Nem sikerült törölni a mappát: %s: %s',
                                     'it': 'Impossibile eliminare la cartella: %s: %s',
                                     'ja': 'フォルダーを削除できませんでした: %s: %s',
                                     'nl': 'Kan map niet verwijderen: %s: %s',
                                     'oc': 'Impossible de suprimir lo repertòri : %s : %s',
                                     'pl': 'Nie udało się usunąć folderu: %s: %s',
                                     'pt_BR': 'Falha ao excluir pasta: %s: %s',
                                     'ru': 'Не удалось удалить папку: %s: %s',
                                     'sk': 'Nepodarilo sa odstrániť priečinok: %s: %s',
                                     'tr': 'Klasör silinemedi: %s: %s',
                                     'uk': 'Не вдалося видалити теку: %s: %s',
                                     'zh_CN': '无法删除文件夹：%s：%s'}})


# Additional strings used by the unified warning flow, dynamic dialog titles and console messages.
translations.update({'Warning: Deletion requires additional confirmation.': {'ar': 'تحذير: يتطلب الحذف تأكيدًا إضافيًا.',
                                                         'ca': 'Avís: la supressió requereix una confirmació '
                                                               'addicional.',
                                                         'cs': 'Varování: odstranění vyžaduje dodatečné potvrzení.',
                                                         'de': 'Warnung: Das Löschen erfordert eine zusätzliche '
                                                               'Bestätigung.',
                                                         'el': 'Προειδοποίηση: η διαγραφή απαιτεί πρόσθετη '
                                                               'επιβεβαίωση.',
                                                         'es': 'Advertencia: la eliminación requiere confirmación '
                                                               'adicional.',
                                                         'eu': 'Abisua: ezabatzeko berrespen gehigarria behar da.',
                                                         'fa': 'هشدار: حذف به تأیید اضافی نیاز دارد.',
                                                         'fi': 'Varoitus: poistaminen vaatii lisävahvistuksen.',
                                                         'fr': 'Avertissement : la suppression nécessite une '
                                                               'confirmation supplémentaire.',
                                                         'hu': 'Figyelmeztetés: a törlés további megerősítést igényel.',
                                                         'it': "Avviso: l'eliminazione richiede una conferma "
                                                               'aggiuntiva.',
                                                         'ja': '警告: 削除には追加の確認が必要です。',
                                                         'nl': 'Waarschuwing: verwijderen vereist extra bevestiging.',
                                                         'oc': 'Avertiment : la supression necessita una confirmacion '
                                                               'suplementària.',
                                                         'pl': 'Ostrzeżenie: usunięcie wymaga dodatkowego '
                                                               'potwierdzenia.',
                                                         'pt_BR': 'Aviso: a exclusão requer confirmação adicional.',
                                                         'ru': 'Предупреждение: удаление требует дополнительного '
                                                               'подтверждения.',
                                                         'sk': 'Upozornenie: odstránenie vyžaduje dodatočné '
                                                               'potvrdenie.',
                                                         'tr': 'Uyarı: silme işlemi ek onay gerektirir.',
                                                         'uk': 'Попередження: видалення потребує додаткового '
                                                               'підтвердження.',
                                                         'zh_CN': '警告：删除需要额外确认。'},
 'I understand the risk.': {'ar': 'أفهم المخاطر.',
                            'ca': 'Entenc el risc.',
                            'cs': 'Rozumím riziku.',
                            'de': 'Ich verstehe das Risiko.',
                            'el': 'Κατανοώ τον κίνδυνο.',
                            'es': 'Entiendo el riesgo.',
                            'eu': 'Arriskua ulertzen dut.',
                            'fa': 'خطر را درک می\u200cکنم.',
                            'fi': 'Ymmärrän riskin.',
                            'fr': 'Je comprends le risque.',
                            'hu': 'Megértem a kockázatot.',
                            'it': 'Comprendo il rischio.',
                            'ja': 'リスクを理解しています。',
                            'nl': 'Ik begrijp het risico.',
                            'oc': 'Compreni lo risc.',
                            'pl': 'Rozumiem ryzyko.',
                            'pt_BR': 'Entendo o risco.',
                            'ru': 'Я понимаю риск.',
                            'sk': 'Rozumiem riziku.',
                            'tr': 'Riski anlıyorum.',
                            'uk': 'Я розумію ризик.',
                            'zh_CN': '我了解风险。'},
 'Delete File Permanently?': {'ar': 'حذف الملف نهائيًا؟',
                              'ca': 'Voleu suprimir el fitxer permanentment?',
                              'cs': 'Trvale smazat soubor?',
                              'de': 'Datei dauerhaft löschen?',
                              'el': 'Οριστική διαγραφή αρχείου;',
                              'es': '¿Eliminar el archivo permanentemente?',
                              'eu': 'Fitxategia betiko ezabatu?',
                              'fa': 'فایل برای همیشه حذف شود؟',
                              'fi': 'Poistetaanko tiedosto pysyvästi?',
                              'fr': 'Supprimer le fichier définitivement ?',
                              'hu': 'Fájl végleges törlése?',
                              'it': 'Eliminare definitivamente il file?',
                              'ja': 'ファイルを完全に削除しますか?',
                              'nl': 'Bestand permanent verwijderen?',
                              'oc': 'Suprimir lo fichièr definitivament ?',
                              'pl': 'Usunąć plik trwale?',
                              'pt_BR': 'Excluir arquivo permanentemente?',
                              'ru': 'Удалить файл безвозвратно?',
                              'sk': 'Natrvalo odstrániť súbor?',
                              'tr': 'Dosya kalıcı olarak silinsin mi?',
                              'uk': 'Видалити файл назавжди?',
                              'zh_CN': '永久删除文件？'},
 'Delete Folder Permanently?': {'ar': 'حذف المجلد نهائيًا؟',
                                'ca': 'Voleu suprimir la carpeta permanentment?',
                                'cs': 'Trvale smazat složku?',
                                'de': 'Ordner dauerhaft löschen?',
                                'el': 'Οριστική διαγραφή φακέλου;',
                                'es': '¿Eliminar la carpeta permanentemente?',
                                'eu': 'Karpeta betiko ezabatu?',
                                'fa': 'پوشه برای همیشه حذف شود؟',
                                'fi': 'Poistetaanko kansio pysyvästi?',
                                'fr': 'Supprimer le dossier définitivement ?',
                                'hu': 'Mappa végleges törlése?',
                                'it': 'Eliminare definitivamente la cartella?',
                                'ja': 'フォルダーを完全に削除しますか?',
                                'nl': 'Map permanent verwijderen?',
                                'oc': 'Suprimir lo repertòri definitivament ?',
                                'pl': 'Usunąć folder trwale?',
                                'pt_BR': 'Excluir pasta permanentemente?',
                                'ru': 'Удалить папку безвозвратно?',
                                'sk': 'Natrvalo odstrániť priečinok?',
                                'tr': 'Klasör kalıcı olarak silinsin mi?',
                                'uk': 'Видалити теку назавжди?',
                                'zh_CN': '永久删除文件夹？'},
 'Delete %(folders)d folders and %(files)d files Permanently?': {'ar': 'حذف %(folders)d مجلدات و%(files)d ملفات '
                                                                       'نهائيًا؟',
                                                                 'ca': 'Voleu suprimir permanentment %(folders)d '
                                                                       'carpetes i %(files)d fitxers?',
                                                                 'cs': 'Trvale smazat %(folders)d složek a %(files)d '
                                                                       'souborů?',
                                                                 'de': '%(folders)d Ordner und %(files)d Dateien '
                                                                       'dauerhaft löschen?',
                                                                 'el': 'Οριστική διαγραφή %(folders)d φακέλων και '
                                                                       '%(files)d αρχείων;',
                                                                 'es': '¿Eliminar permanentemente %(folders)d carpetas '
                                                                       'y %(files)d archivos?',
                                                                 'eu': '%(folders)d karpeta eta %(files)d fitxategi '
                                                                       'betiko ezabatu?',
                                                                 'fa': '%(folders)d پوشه و %(files)d فایل برای همیشه '
                                                                       'حذف شوند؟',
                                                                 'fi': 'Poistetaanko %(folders)d kansiota ja %(files)d '
                                                                       'tiedostoa pysyvästi?',
                                                                 'fr': 'Supprimer définitivement %(folders)d dossiers '
                                                                       'et %(files)d fichiers ?',
                                                                 'hu': '%(folders)d mappa és %(files)d fájl végleges '
                                                                       'törlése?',
                                                                 'it': 'Eliminare definitivamente %(folders)d cartelle '
                                                                       'e %(files)d file?',
                                                                 'ja': '%(folders)d 個のフォルダーと %(files)d '
                                                                       '個のファイルを完全に削除しますか?',
                                                                 'nl': '%(folders)d mappen en %(files)d bestanden '
                                                                       'permanent verwijderen?',
                                                                 'oc': 'Suprimir definitivament %(folders)d repertòris '
                                                                       'e %(files)d fichièrs ?',
                                                                 'pl': 'Usunąć trwale %(folders)d folderów i %(files)d '
                                                                       'plików?',
                                                                 'pt_BR': 'Excluir permanentemente %(folders)d pastas '
                                                                          'e %(files)d arquivos?',
                                                                 'ru': 'Удалить безвозвратно %(folders)d папок и '
                                                                       '%(files)d файлов?',
                                                                 'sk': 'Natrvalo odstrániť %(folders)d priečinkov a '
                                                                       '%(files)d súborov?',
                                                                 'tr': '%(folders)d klasör ve %(files)d dosya kalıcı '
                                                                       'olarak silinsin mi?',
                                                                 'uk': 'Видалити назавжди %(folders)d тек і %(files)d '
                                                                       'файлів?',
                                                                 'zh_CN': '永久删除 %(folders)d 个文件夹和 %(files)d 个文件？'},
 'Failed to read path rules file: %s: %s': {'de': 'Pfadregeldatei konnte nicht gelesen werden: %s: %s'},
 'Failed to delete file: %s: %s': {'de': 'Datei konnte nicht gelöscht werden: %s: %s'},
 'Failed to delete folder: %s: %s': {'de': 'Ordner konnte nicht gelöscht werden: %s: %s'}})


# Additional strings used by the runtime error dialog.
translations.update({'Some Items Could Not Be Deleted': {'ar': 'تعذر حذف بعض العناصر',
                                     'ca': "No s'han pogut suprimir alguns elements",
                                     'cs': 'Některé položky se nepodařilo smazat',
                                     'de': 'Einige Elemente konnten nicht gelöscht werden',
                                     'el': 'Δεν ήταν δυνατή η διαγραφή ορισμένων στοιχείων',
                                     'es': 'No se pudieron eliminar algunos elementos',
                                     'eu': 'Ezin izan dira elementu batzuk ezabatu',
                                     'fa': 'برخی موارد حذف نشدند',
                                     'fi': 'Joitakin kohteita ei voitu poistaa',
                                     'fr': "Certains éléments n'ont pas pu être supprimés",
                                     'hu': 'Néhány elemet nem sikerült törölni',
                                     'it': 'Impossibile eliminare alcuni elementi',
                                     'ja': '一部の項目を削除できませんでした',
                                     'nl': 'Sommige items konden niet worden verwijderd',
                                     'oc': "D'unes elements se son pas poguts suprimir",
                                     'pl': 'Nie udało się usunąć niektórych elementów',
                                     'pt_BR': 'Alguns itens não puderam ser excluídos',
                                     'ru': 'Некоторые элементы не удалось удалить',
                                     'sk': 'Niektoré položky sa nepodarilo odstrániť',
                                     'tr': 'Bazı öğeler silinemedi',
                                     'uk': 'Не вдалося видалити деякі елементи',
                                     'zh_CN': '某些项目无法删除'},
 'Some items could not be deleted because an error occurred.': {'ar': 'تعذر حذف بعض العناصر بسبب حدوث خطأ.',
                                                                'ca': "No s'han pogut suprimir alguns elements perquè "
                                                                      "s'ha produït un error.",
                                                                'cs': 'Některé položky se nepodařilo smazat, protože '
                                                                      'došlo k chybě.',
                                                                'de': 'Einige Elemente konnten nicht gelöscht werden, '
                                                                      'weil ein Fehler aufgetreten ist.',
                                                                'el': 'Δεν ήταν δυνατή η διαγραφή ορισμένων στοιχείων '
                                                                      'επειδή παρουσιάστηκε σφάλμα.',
                                                                'es': 'No se pudieron eliminar algunos elementos '
                                                                      'porque se produjo un error.',
                                                                'eu': 'Ezin izan dira elementu batzuk ezabatu errore '
                                                                      'bat gertatu delako.',
                                                                'fa': 'برخی موارد به دلیل رخ دادن خطا حذف نشدند.',
                                                                'fi': 'Joitakin kohteita ei voitu poistaa virheen '
                                                                      'vuoksi.',
                                                                'fr': "Certains éléments n'ont pas pu être supprimés "
                                                                      "car une erreur s'est produite.",
                                                                'hu': 'Néhány elemet nem sikerült törölni, mert hiba '
                                                                      'történt.',
                                                                'it': 'Impossibile eliminare alcuni elementi perché si '
                                                                      'è verificato un errore.',
                                                                'ja': 'エラーが発生したため、一部の項目を削除できませんでした。',
                                                                'nl': 'Sommige items konden niet worden verwijderd '
                                                                      'omdat er een fout is opgetreden.',
                                                                'oc': "D'unes elements se son pas poguts suprimir "
                                                                      "perque una error s'es producha.",
                                                                'pl': 'Nie udało się usunąć niektórych elementów, '
                                                                      'ponieważ wystąpił błąd.',
                                                                'pt_BR': 'Alguns itens não puderam ser excluídos '
                                                                         'porque ocorreu um erro.',
                                                                'ru': 'Некоторые элементы не удалось удалить из-за '
                                                                      'ошибки.',
                                                                'sk': 'Niektoré položky sa nepodarilo odstrániť, '
                                                                      'pretože sa vyskytla chyba.',
                                                                'tr': 'Bir hata oluştuğu için bazı öğeler silinemedi.',
                                                                'uk': 'Не вдалося видалити деякі елементи, оскільки '
                                                                      'сталася помилка.',
                                                                'zh_CN': '由于发生错误，某些项目无法删除。'},
 '%d more errors were not shown.': {'ar': 'لم يتم عرض %d أخطاء أخرى.',
                                    'ca': "No s'han mostrat %d errors més.",
                                    'cs': '%d dalších chyb nebylo zobrazeno.',
                                    'de': '%d weitere Fehler wurden nicht angezeigt.',
                                    'el': 'Δεν εμφανίστηκαν %d ακόμη σφάλματα.',
                                    'es': 'No se mostraron %d errores más.',
                                    'eu': 'Beste %d errore ez dira erakutsi.',
                                    'fa': '%d خطای دیگر نمایش داده نشد.',
                                    'fi': '%d muuta virhettä ei näytetty.',
                                    'fr': "%d autres erreurs n'ont pas été affichées.",
                                    'hu': '%d további hiba nem lett megjelenítve.',
                                    'it': '%d altri errori non sono stati mostrati.',
                                    'ja': 'さらに %d 件のエラーは表示されていません。',
                                    'nl': '%d andere fouten zijn niet weergegeven.',
                                    'oc': '%d autras errors son pas estadas afichadas.',
                                    'pl': 'Nie pokazano %d kolejnych błędów.',
                                    'pt_BR': '%d erros adicionais não foram mostrados.',
                                    'ru': 'Ещё %d ошибок не показано.',
                                    'sk': '%d ďalších chýb nebolo zobrazených.',
                                    'tr': '%d hata daha gösterilmedi.',
                                    'uk': 'Ще %d помилок не показано.',
                                    'zh_CN': '还有 %d 个错误未显示。'},
 '_Close': {'ar': '_إغلاق',
            'ca': '_Tanca',
            'cs': '_Zavřít',
            'de': '_Schließen',
            'el': '_Κλείσιμο',
            'es': '_Cerrar',
            'eu': '_Itxi',
            'fa': '_بستن',
            'fi': '_Sulje',
            'fr': '_Fermer',
            'hu': '_Bezárás',
            'it': '_Chiudi',
            'ja': '_閉じる',
            'nl': '_Sluiten',
            'oc': '_Tampar',
            'pl': '_Zamknij',
            'pt_BR': '_Fechar',
            'ru': '_Закрыть',
            'sk': '_Zavrieť',
            'tr': '_Kapat',
            'uk': '_Закрити',
            'zh_CN': '_关闭'}})

plural_translations = {
    "%d folder": {
        "ar": ["%d مجلد", "%d مجلد", "%d مجلدان", "%d مجلدات", "%d مجلدًا", "%d مجلد"],
        "ca": ["%d carpeta", "%d carpetes"],
        "cs": ["%d složka", "%d složky", "%d složek"],
        "de": ["%d Ordner", "%d Ordner"],
        "el": ["%d φάκελος", "%d φάκελοι"],
        "es": ["%d carpeta", "%d carpetas"],
        "eu": ["%d karpeta", "%d karpeta"],
        "fa": ["%d پوشه", "%d پوشه"],
        "fi": ["%d kansio", "%d kansiota"],
        "fr": ["%d dossier", "%d dossiers"],
        "hu": ["%d mappa", "%d mappa"],
        "it": ["%d cartella", "%d cartelle"],
        "ja": ["%d フォルダー"],
        "nl": ["%d map", "%d mappen"],
        "oc": ["%d repertòri", "%d repertòris"],
        "pl": ["%d folder", "%d foldery", "%d folderów"],
        "pt_BR": ["%d pasta", "%d pastas"],
        "ru": ["%d папка", "%d папки", "%d папок"],
        "sk": ["%d priečinok", "%d priečinky", "%d priečinkov"],
        "tr": ["%d klasör", "%d klasör"],
        "uk": ["%d тека", "%d теки", "%d тек"],
        "zh_CN": ["%d 个文件夹"],
    },
    "%d file": {
        "ar": ["%d ملف", "%d ملف", "%d ملفان", "%d ملفات", "%d ملفًا", "%d ملف"],
        "ca": ["%d fitxer", "%d fitxers"],
        "cs": ["%d soubor", "%d soubory", "%d souborů"],
        "de": ["%d Datei", "%d Dateien"],
        "el": ["%d αρχείο", "%d αρχεία"],
        "es": ["%d archivo", "%d archivos"],
        "eu": ["%d fitxategi", "%d fitxategi"],
        "fa": ["%d فایل", "%d فایل"],
        "fi": ["%d tiedosto", "%d tiedostoa"],
        "fr": ["%d fichier", "%d fichiers"],
        "hu": ["%d fájl", "%d fájl"],
        "it": ["%d file", "%d file"],
        "ja": ["%d ファイル"],
        "nl": ["%d bestand", "%d bestanden"],
        "oc": ["%d fichièr", "%d fichièrs"],
        "pl": ["%d plik", "%d pliki", "%d plików"],
        "pt_BR": ["%d arquivo", "%d arquivos"],
        "ru": ["%d файл", "%d файла", "%d файлов"],
        "sk": ["%d súbor", "%d súbory", "%d súborov"],
        "tr": ["%d dosya", "%d dosya"],
        "uk": ["%d файл", "%d файли", "%d файлів"],
        "zh_CN": ["%d 个文件"],
    },
}

# Dynamic dialog title plurals.
plural_translations.update({'Delete %d folder Permanently?': {'ar': ['حذف %d مجلد نهائيًا؟',
                                          'حذف %d مجلد نهائيًا؟',
                                          'حذف مجلدين نهائيًا؟',
                                          'حذف %d مجلدات نهائيًا؟',
                                          'حذف %d مجلدًا نهائيًا؟',
                                          'حذف %d مجلد نهائيًا؟'],
                                   'ca': ['Voleu suprimir %d carpeta permanentment?',
                                          'Voleu suprimir %d carpetes permanentment?'],
                                   'cs': ['Trvale smazat %d složku?',
                                          'Trvale smazat %d složky?',
                                          'Trvale smazat %d složek?'],
                                   'de': ['%d Ordner dauerhaft löschen?', '%d Ordner dauerhaft löschen?'],
                                   'el': ['Οριστική διαγραφή %d φακέλου;', 'Οριστική διαγραφή %d φακέλων;'],
                                   'es': ['¿Eliminar %d carpeta permanentemente?',
                                          '¿Eliminar %d carpetas permanentemente?'],
                                   'eu': ['%d karpeta betiko ezabatu?', '%d karpeta betiko ezabatu?'],
                                   'fa': ['%d پوشه برای همیشه حذف شود؟', '%d پوشه برای همیشه حذف شوند؟'],
                                   'fi': ['Poistetaanko %d kansio pysyvästi?', 'Poistetaanko %d kansiota pysyvästi?'],
                                   'fr': ['Supprimer définitivement %d dossier ?',
                                          'Supprimer définitivement %d dossiers ?'],
                                   'hu': ['%d mappa végleges törlése?', '%d mappa végleges törlése?'],
                                   'it': ['Eliminare definitivamente %d cartella?',
                                          'Eliminare definitivamente %d cartelle?'],
                                   'ja': ['%d 個のフォルダーを完全に削除しますか?'],
                                   'nl': ['%d map permanent verwijderen?', '%d mappen permanent verwijderen?'],
                                   'oc': ['Suprimir definitivament %d repertòri ?',
                                          'Suprimir definitivament %d repertòris ?'],
                                   'pl': ['Usunąć trwale %d folder?',
                                          'Usunąć trwale %d foldery?',
                                          'Usunąć trwale %d folderów?'],
                                   'pt_BR': ['Excluir %d pasta permanentemente?', 'Excluir %d pastas permanentemente?'],
                                   'ru': ['Удалить безвозвратно %d папку?',
                                          'Удалить безвозвратно %d папки?',
                                          'Удалить безвозвратно %d папок?'],
                                   'sk': ['Natrvalo odstrániť %d priečinok?',
                                          'Natrvalo odstrániť %d priečinky?',
                                          'Natrvalo odstrániť %d priečinkov?'],
                                   'tr': ['%d klasör kalıcı olarak silinsin mi?',
                                          '%d klasör kalıcı olarak silinsin mi?'],
                                   'uk': ['Видалити назавжди %d теку?',
                                          'Видалити назавжди %d теки?',
                                          'Видалити назавжди %d тек?'],
                                   'zh_CN': ['永久删除 %d 个文件夹？']},
 'Delete %d file Permanently?': {'ar': ['حذف %d ملف نهائيًا؟',
                                        'حذف %d ملف نهائيًا؟',
                                        'حذف ملفين نهائيًا؟',
                                        'حذف %d ملفات نهائيًا؟',
                                        'حذف %d ملفًا نهائيًا؟',
                                        'حذف %d ملف نهائيًا؟'],
                                 'ca': ['Voleu suprimir %d fitxer permanentment?',
                                        'Voleu suprimir %d fitxers permanentment?'],
                                 'cs': ['Trvale smazat %d soubor?',
                                        'Trvale smazat %d soubory?',
                                        'Trvale smazat %d souborů?'],
                                 'de': ['%d Datei dauerhaft löschen?', '%d Dateien dauerhaft löschen?'],
                                 'el': ['Οριστική διαγραφή %d αρχείου;', 'Οριστική διαγραφή %d αρχείων;'],
                                 'es': ['¿Eliminar %d archivo permanentemente?',
                                        '¿Eliminar %d archivos permanentemente?'],
                                 'eu': ['%d fitxategi betiko ezabatu?', '%d fitxategi betiko ezabatu?'],
                                 'fa': ['%d فایل برای همیشه حذف شود؟', '%d فایل برای همیشه حذف شوند؟'],
                                 'fi': ['Poistetaanko %d tiedosto pysyvästi?', 'Poistetaanko %d tiedostoa pysyvästi?'],
                                 'fr': ['Supprimer définitivement %d fichier ?',
                                        'Supprimer définitivement %d fichiers ?'],
                                 'hu': ['%d fájl végleges törlése?', '%d fájl végleges törlése?'],
                                 'it': ['Eliminare definitivamente %d file?', 'Eliminare definitivamente %d file?'],
                                 'ja': ['%d 個のファイルを完全に削除しますか?'],
                                 'nl': ['%d bestand permanent verwijderen?', '%d bestanden permanent verwijderen?'],
                                 'oc': ['Suprimir definitivament %d fichièr ?',
                                        'Suprimir definitivament %d fichièrs ?'],
                                 'pl': ['Usunąć trwale %d plik?',
                                        'Usunąć trwale %d pliki?',
                                        'Usunąć trwale %d plików?'],
                                 'pt_BR': ['Excluir %d arquivo permanentemente?',
                                           'Excluir %d arquivos permanentemente?'],
                                 'ru': ['Удалить безвозвратно %d файл?',
                                        'Удалить безвозвратно %d файла?',
                                        'Удалить безвозвратно %d файлов?'],
                                 'sk': ['Natrvalo odstrániť %d súbor?',
                                        'Natrvalo odstrániť %d súbory?',
                                        'Natrvalo odstrániť %d súborov?'],
                                 'tr': ['%d dosya kalıcı olarak silinsin mi?', '%d dosya kalıcı olarak silinsin mi?'],
                                 'uk': ['Видалити назавжди %d файл?',
                                        'Видалити назавжди %d файли?',
                                        'Видалити назавжди %d файлів?'],
                                 'zh_CN': ['永久删除 %d 个文件？']}})


def po_escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")

def parse_pot_entries(path: Path):
    text = path.read_text(encoding="utf-8")
    chunks = re.split(r"\n\s*\n", text)
    entries = []

    for chunk in chunks:
        if 'msgid "' not in chunk:
            continue
        if chunk.startswith('msgid ""') or '\nmsgid ""' in chunk:
            continue

        msgid_match = re.search(r'^msgid "((?:[^"\\]|\\.)*)"', chunk, re.M)
        if not msgid_match:
            continue

        msgid = bytes(msgid_match.group(1), "utf-8").decode("unicode_escape")

        plural_match = re.search(r'^msgid_plural "((?:[^"\\]|\\.)*)"', chunk, re.M)
        plural = None
        if plural_match:
            plural = bytes(plural_match.group(1), "utf-8").decode("unicode_escape")

        flags = []
        for m in re.finditer(r'^#, (.*)$', chunk, re.M):
            flags.append(m.group(1))

        refs = []
        for m in re.finditer(r'^#: (.*)$', chunk, re.M):
            refs.append(m.group(1))

        entries.append({
            "msgid": msgid,
            "plural": plural,
            "flags": flags,
            "refs": refs,
        })

    return entries

def write_po(lang: str, entries):
    lc_dir = translations_dir / lang / "LC_MESSAGES"
    lc_dir.mkdir(parents=True, exist_ok=True)

    po_path = lc_dir / f"{domain}.po"
    mo_path = lc_dir / f"{domain}.mo"

    with po_path.open("w", encoding="utf-8") as f:
        f.write('msgid ""\n')
        f.write('msgstr ""\n')
        f.write(f'"Project-Id-Version: {domain}\\n"\n')
        f.write('"Report-Msgid-Bugs-To: \\n"\n')
        f.write('"POT-Creation-Date: \\n"\n')
        f.write('"PO-Revision-Date: \\n"\n')
        f.write('"Last-Translator: Automatically generated\\n"\n')
        f.write('"Language-Team: \\n"\n')
        f.write(f'"Language: {lang}\\n"\n')
        f.write('"MIME-Version: 1.0\\n"\n')
        f.write('"Content-Type: text/plain; charset=UTF-8\\n"\n')
        f.write('"Content-Transfer-Encoding: 8bit\\n"\n')
        f.write(f'"Plural-Forms: {plural_forms[lang]}\\n"\n')

        nplurals = int(re.search(r"nplurals=(\d+)", plural_forms[lang]).group(1))

        for entry in entries:
            msgid = entry["msgid"]
            plural = entry["plural"]

            f.write("\n")
            for ref in entry["refs"]:
                f.write(f"#: {ref}\n")
            for flag in entry["flags"]:
                f.write(f"#, {flag}\n")

            if plural is None:
                msgstr = translations.get(msgid, {}).get(lang, "")
                f.write(f'msgid "{po_escape(msgid)}"\n')
                f.write(f'msgstr "{po_escape(msgstr)}"\n')
            else:
                base = plural_translations.get(msgid, {}).get(lang)
                if base is None:
                    base = [""] * nplurals
                if len(base) < nplurals:
                    base = base + [base[-1] if base else ""] * (nplurals - len(base))

                f.write(f'msgid "{po_escape(msgid)}"\n')
                f.write(f'msgid_plural "{po_escape(plural)}"\n')
                for i in range(nplurals):
                    f.write(f'msgstr[{i}] "{po_escape(base[i])}"\n')

    subprocess.run(["msgfmt", str(po_path), "-o", str(mo_path)], check=True)
    print(f"Wrote {po_path.relative_to(script_dir)}")
    print(f"Wrote {mo_path.relative_to(script_dir)}")

entries = parse_pot_entries(pot_file)

for lang in languages:
    write_po(lang, entries)
PY

echo
echo "Done."

