#!/bin/zsh

# ============================================================
# Brewfile 동기화 확인 스크립트
# 현재 설치된 패키지와 Brewfile을 비교하여 drift를 감지합니다.
#
# 사용법: ./scripts/sync-brewfile.sh
# ============================================================

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

info()  { echo "\033[1;34m▸\033[0m $1"; }
ok()    { echo "\033[1;32m✓\033[0m $1"; }
warn()  { echo "\033[1;33m!\033[0m $1"; }
step()  { echo "\n\033[1;35m━━━ $1 ━━━\033[0m"; }

step "Brewfile 동기화 확인"

# 현재 설치된 패키지를 임시 Brewfile로 덤프
TEMP_BREWFILE="/tmp/Brewfile.current"
brew bundle dump --file="$TEMP_BREWFILE" --force 2>/dev/null

info "현재 Brewfile과 설치된 패키지를 비교합니다..."
echo ""

# Brewfile에 있지만 설치되지 않은 패키지
step "Brewfile에 있지만 미설치된 패키지"
brew bundle check --file="${DOTFILES_DIR}/Brewfile" 2>&1 | grep -v "^$" || ok "모두 설치됨"

echo ""

# 설치되어 있지만 Brewfile에 없는 패키지
step "설치되었지만 Brewfile에 없는 패키지"
comm -13 <(grep -E '^(brew|cask|mas)' "${DOTFILES_DIR}/Brewfile" | sort) \
         <(grep -E '^(brew|cask|mas)' "$TEMP_BREWFILE" | sort) || ok "추가 패키지 없음"

echo ""
info "Brewfile에 추가하려면:"
echo "  brew bundle dump --file=${DOTFILES_DIR}/Brewfile --force"
echo ""
info "Brewfile 기준으로 설치하려면:"
echo "  brew bundle --file=${DOTFILES_DIR}/Brewfile"

rm -f "$TEMP_BREWFILE"
