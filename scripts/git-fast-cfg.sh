#!/bin/bash
set -euo pipefail

git config feature.manyFiles true &&
git update-index --index-version 4 &&
git config core.untrackedCache true &&
git update-index --really-refresh
