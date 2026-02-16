#!/bin/zsh

# ============================================================
# 앱 설정 백업 스크립트
# VS Code 확장 목록 등을 백업합니다.
#
# 사용법: ./scripts/backup-apps.sh
# ============================================================

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

info()  { echo "\033[1;34m▸\033[0m $1"; }
ok()    { echo "\033[1;32m✓\033[0m $1"; }
warn()  { echo "\033[1;33m!\033[0m $1"; }

# --- VS Code 확장 목록 백업 ---
if command -v code &>/dev/null; then
    info "VS Code 확장 목록을 백업합니다..."
    code --list-extensions > "${DOTFILES_DIR}/vscode-extensions.txt"
    ok "vscode-extensions.txt 저장 ($(wc -l < "${DOTFILES_DIR}/vscode-extensions.txt" | tr -d ' ')개 확장)"
else
    warn "VS Code CLI(code)를 찾을 수 없습니다."
fi

# --- Raycast 설정 백업 ---
echo ""
info "Raycast 설정 백업은 다음 스크립트를 사용하세요:"
echo "  ./scripts/raycast-migrate.sh export"

# --- 현재 Brewfile 덤프 ---
echo ""
info "현재 설치된 패키지를 Brewfile로 덤프합니다..."
brew bundle dump --file="${DOTFILES_DIR}/Brewfile.current" --force 2>/dev/null
ok "Brewfile.current 저장"
info "기존 Brewfile과 비교하려면: diff Brewfile Brewfile.current"

echo ""
ok "백업 완료!"
