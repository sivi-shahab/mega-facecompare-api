#!/usr/bin/env bash
# Checksum isi modul bersama java/common (semua file kecuali README.md dan .checksum).
#   scripts/common-checksum.sh            # cetak checksum
#   scripts/common-checksum.sh --update   # tulis ke java/common/.checksum
#   scripts/common-checksum.sh --check    # bandingkan dengan java/common/.checksum (CI)
# Nilai .checksum HARUS sama di mega-facecompare-admin dan mega-facecompare-api.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
sum="$(find java/common -type f ! -name README.md ! -name .checksum ! -path '*/target/*' -print0 \
  | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -c1-64)"
case "${1:-}" in
  --update) echo "$sum" > java/common/.checksum; echo "java/common/.checksum = $sum" ;;
  --check)
    want="$(cat java/common/.checksum)"
    [[ "$sum" == "$want" ]] || { echo "java/common berubah ($sum) tetapi .checksum = $want"; echo "Terapkan perubahan yang SAMA di repo pasangan, lalu scripts/common-checksum.sh --update di kedua repo."; exit 1; }
    echo "OK: java/common = $sum" ;;
  *) echo "$sum" ;;
esac
