#!/usr/bin/env bash

set -euo pipefail

slides_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
html_path="${slides_dir}/slides.html"
pdf_path="${slides_dir}/slides.pdf"

if [[ ! -f "${html_path}" ]]; then
  echo "Cannot create slides.pdf: slides.html was not rendered." >&2
  exit 1
fi

browser_path=""
browser_candidates=(
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
  "/Applications/Chromium.app/Contents/MacOS/Chromium"
)

for candidate in "${browser_candidates[@]}"; do
  if [[ -x "${candidate}" ]]; then
    browser_path="${candidate}"
    break
  fi
done

if [[ -z "${browser_path}" ]]; then
  for command_name in google-chrome chromium chromium-browser; do
    if command -v "${command_name}" >/dev/null 2>&1; then
      browser_path="$(command -v "${command_name}")"
      break
    fi
  done
fi

if [[ -z "${browser_path}" ]]; then
  echo "Cannot create slides.pdf: Chrome, Edge, or Chromium was not found." >&2
  exit 1
fi

runtime_dir="$(mktemp -d "${TMPDIR:-/tmp}/quarto-slides-pdf.XXXXXX")"
cleanup() {
  rm -rf -- "${runtime_dir}"
}
trap cleanup EXIT

pdf_temp="${runtime_dir}/slides.pdf"
chrome_log="${runtime_dir}/chrome.log"

if ! "${browser_path}" \
  --headless \
  --disable-component-update \
  --disable-gpu \
  --disable-sync \
  --allow-file-access-from-files \
  --no-first-run \
  --no-pdf-header-footer \
  --run-all-compositor-stages-before-draw \
  --virtual-time-budget=10000 \
  --print-to-pdf="${pdf_temp}" \
  "file://${html_path}?print-pdf" \
  2>"${chrome_log}"; then
  cat "${chrome_log}" >&2
  exit 1
fi

if [[ ! -s "${pdf_temp}" ]]; then
  cat "${chrome_log}" >&2
  echo "Chrome completed without creating slides.pdf." >&2
  exit 1
fi

mv "${pdf_temp}" "${pdf_path}"
echo "PDF created: ${pdf_path}"
