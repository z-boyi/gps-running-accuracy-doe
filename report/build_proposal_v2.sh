#!/usr/bin/env sh
# Build report/proposal_v2.pdf from report/proposal_v2.md.
# Needs pandoc and a Chromium/Chrome binary (set CHROME to its path if needed).
set -e
cd "$(dirname "$0")"
CHROME="${CHROME:-chromium}"
pandoc proposal_v2.md --standalone --mathml --css proposal.css \
  --metadata pagetitle="STAT 404 Group Project Proposal (v2)" -o proposal_v2.html
"$CHROME" --headless --no-sandbox --disable-gpu --no-pdf-header-footer \
  --print-to-pdf=proposal_v2.pdf "file://$PWD/proposal_v2.html"
rm proposal_v2.html
