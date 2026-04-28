#!/usr/bin/env bash
# ============================================================
# setup_contribution_branches.sh
#
# Creates four "contribution/" branches on GitHub, each
# showing the exact files one team member added during the
# dev-branch phase (commit 864ad8d), attributed to them.
#
# Each branch is an orphan (no inherited history) so that
# GitHub shows only that developer's single commit — giving
# a clean, correct contribution history per person.
#
# Run this script from the root of your local clone:
#   bash setup_contribution_branches.sh
#
# Requirements: git, access to push to the origin remote.
# ============================================================

set -euo pipefail

SQUASH_COMMIT="864ad8d"        # the squash that merged all dev branches

echo "==> Ensuring full history is available..."
git fetch --unshallow origin 2>/dev/null || true
git fetch origin

# Remember which branch we started on so we can return to it
ORIGINAL_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo 'main')"

# ------------------------------------------------------------------
# Helper: create one contribution branch as an orphan
# Usage: make_branch <branch_name> <author_name> <author_email> \
#                    <commit_message> <file1> [<file2> ...]
# ------------------------------------------------------------------
make_branch() {
  local branch="$1"
  local author_name="$2"
  local author_email="$3"
  local commit_msg="$4"
  shift 4
  local files=("$@")

  echo ""
  echo "==> Creating branch: $branch"

  # Delete branch locally if it already exists
  git branch -D "$branch" 2>/dev/null || true

  # Create an orphan branch — no parent commits, so history is clean
  git checkout --orphan "$branch"

  # Remove everything from the index (orphan inherits the working tree)
  git rm -rf --cached . 2>/dev/null || true

  # Create parent directories and restore each file from the squash commit
  for f in "${files[@]}"; do
    mkdir -p "$(dirname "$f")"
    git show "${SQUASH_COMMIT}:${f}" > "$f"
    git add "$f"
  done

  # Commit with the correct author (noreply email links to the GitHub profile)
  GIT_AUTHOR_NAME="$author_name" \
  GIT_AUTHOR_EMAIL="$author_email" \
  GIT_COMMITTER_NAME="$author_name" \
  GIT_COMMITTER_EMAIL="$author_email" \
  git -c commit.gpgsign=false \
      commit -m "$commit_msg"

  echo "    Pushing $branch to origin..."
  git push --force origin "$branch"
  echo "    Done: https://github.com/Pujani980/Smart-Study-Assistant-/tree/$branch"
}

# ------------------------------------------------------------------
# 1. Gayanthi (Madhubhashinii) — Notes Library page
# ------------------------------------------------------------------
make_branch \
  "contribution/gayanthi" \
  "Madhubhashinii" \
  "180200862+Madhubhashinii@users.noreply.github.com" \
  "feat: add notes library page

Contribution by Madhubhashinii (Gayanthi) — dev-gayanthi branch
- Implemented full notes library page with Firestore integration
- Search, filter, view, edit and delete notes UI" \
  "lib/pages/notes_library_page.dart"

# ------------------------------------------------------------------
# 2. Achini (IMALSHAA) — Statistics module
# ------------------------------------------------------------------
make_branch \
  "contribution/achini" \
  "IMALSHAA" \
  "172722358+IMALSHAA@users.noreply.github.com" \
  "feat: add statistics module

Contribution by IMALSHAA (Achini) — dev_achini branch
- Implemented statistics model, page, and service
- Added statistics service unit tests" \
  "lib/models/statistics_model.dart" \
  "lib/pages/statistics_page.dart" \
  "lib/services/statistics_service.dart" \
  "test/statistics_service_test.dart"

# ------------------------------------------------------------------
# 3. Dilmi (Dshehara) — AI summarisation service + summarizer page
# ------------------------------------------------------------------
make_branch \
  "contribution/dilmi" \
  "Dshehara" \
  "172895322+Dshehara@users.noreply.github.com" \
  "feat: add AI summarisation service and summarizer page

Contribution by Dshehara (Dilmi) — dev_dilmi branch
- Implemented AI summarisation service (Gemini API)
- Implemented summarizer page UI" \
  "lib/services/ai_service.dart" \
  "lib/pages/summarizer_page.dart"

# ------------------------------------------------------------------
# 4. Pujani (Pujani980) — Home page, note model, firebase service
# ------------------------------------------------------------------
make_branch \
  "contribution/pujani" \
  "Pujani980" \
  "173042339+Pujani980@users.noreply.github.com" \
  "feat: add home page dashboard, note model and firebase service

Contribution by Pujani980 — dev_pujani branch
- Implemented home page dashboard UI
- Added Note model with Firestore integration
- Added Firebase service
- Updated pubspec.yaml with required dependencies" \
  "lib/models/note_model.dart" \
  "lib/pages/home_page.dart" \
  "lib/services/firebase_service.dart" \
  "pubspec.yaml"

# Go back to the original branch
git checkout "$ORIGINAL_BRANCH"

echo ""
echo "============================================================"
echo " All 4 contribution branches created and pushed!"
echo ""
echo "  contribution/gayanthi  -> Madhubhashinii (Gayanthi)"
echo "  contribution/achini    -> IMALSHAA (Achini)"
echo "  contribution/dilmi     -> Dshehara (Dilmi)"
echo "  contribution/pujani    -> Pujani980 (Pujani)"
echo ""
echo " main branch is untouched — all history is preserved."
echo "============================================================"
