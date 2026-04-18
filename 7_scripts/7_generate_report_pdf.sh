#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

INPUT_MD="7_docs/7_report_final.md"
OUTPUT_PDF="7_docs/7_report.pdf"
TMP_ODT="/tmp/7_report.odt"

if [[ ! -f "${INPUT_MD}" ]]; then
  echo "Missing ${INPUT_MD}"
  exit 1
fi

if command -v pandoc >/dev/null 2>&1; then
  pandoc "${INPUT_MD}" -o "${OUTPUT_PDF}"
  echo "Generated ${OUTPUT_PDF} via pandoc"
  exit 0
fi

if command -v lowriter >/dev/null 2>&1; then
  cp "${INPUT_MD}" /tmp/7_report.txt
  lowriter --headless --convert-to odt --outdir /tmp /tmp/7_report.txt >/dev/null 2>&1 || true
  if [[ -f "${TMP_ODT}" ]]; then
    lowriter --headless --convert-to pdf --outdir "7_docs" "${TMP_ODT}" >/dev/null 2>&1 || true
    if [[ -f "7_docs/7_report.pdf" ]]; then
      echo "Generated ${OUTPUT_PDF} via lowriter"
      exit 0
    fi
  fi
fi

echo "Could not auto-generate PDF. Manual fallback: open ${INPUT_MD} and export to PDF from editor."
exit 1
