#!/bin/zsh

# ============================================================
# macOS 개발 환경 자동 설정 스크립트
# 사용법: chmod +x set-up.sh && ./set-up.sh
# ============================================================

# 스크립트 위치 기준으로 경로 설정
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- 컬러 로깅 ---
info()  { echo "\033[1;34m▸\033[0m $1"; }
ok()    { echo "\033[1;32m✓\033[0m $1"; }
warn()  { echo "\033[1;33m!\033[0m $1"; }
step()  { echo "\n\033[1;35m━━━ $1 ━━━\033[0m"; }

# ============================================================
# 1. Homebrew 설치 및 업데이트
# ============================================================
step "1/9 Homebrew"

if ! command -v brew &>/dev/null; then
    info "Homebrew를 설치합니다..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon Mac의 경우 PATH 설정
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    info "Homebrew 업데이트 중..."
    brew update
fi
ok "Homebrew"

# ============================================================
# 2. Brewfile로 패키지 일괄 설치
#    - brew (CLI), cask (GUI), mas (App Store) 모두 포함
#    - --no-quarantine: Gatekeeper 경고 방지
# ============================================================
step "2/9 패키지 설치 (Brewfile)"

# Mac App Store 로그인 확인 (mas 앱 설치에 필요)
if command -v mas &>/dev/null; then
    if ! mas account &>/dev/null; then
        warn "Mac App Store에 로그인되어 있지 않습니다."
        info "App Store 앱을 열어 로그인해주세요. 로그인 후 Enter를 누르세요."
        open -a "App Store"
        read -r "?로그인 완료 후 Enter: "
    fi
else
    info "mas가 아직 설치되지 않았습니다. Brewfile에서 함께 설치됩니다."
fi

brew bundle --file="${DOTFILES_DIR}/Brewfile" --no-quarantine || warn "일부 패키지 설치 실패 (위 로그 확인)"

# Spotlight 인덱스 갱신: cask로 설치한 앱이 Spotlight 검색에 나타나도록
info "Spotlight 인덱스를 갱신합니다..."
sudo mdutil -a -i on 2>/dev/null || true

ok "패키지 설치"

# ============================================================
# 3. Oh My Zsh + 플러그인 + 테마
# ============================================================
step "3/9 Oh My Zsh"

ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"

if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    info "Oh My Zsh를 설치합니다..."
    /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 플러그인 & 테마 설치 (이미 있으면 skip)
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting &>/dev/null || true
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM}/plugins/zsh-autosuggestions &>/dev/null || true
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k &>/dev/null || true

# .zshrc에 테마와 플러그인 반영
sed -i '' 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
sed -i '' 's/plugins=(git)/plugins=(git z fzf zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc

ok "Oh My Zsh"

# ============================================================
# 4. Dotfiles 심볼릭 링크 + .zshrc 설정
# ============================================================
step "4/9 Dotfiles"

# 기존 파일이 있으면 백업 후 심볼릭 링크 생성
link_file() {
    local src="$1" dest="$2"
    if [ -f "$dest" ] || [ -L "$dest" ]; then
        mv "$dest" "${dest}.bak.$(date +%s)"
        info "${dest} 기존 파일 백업 완료"
    fi
    ln -sf "$src" "$dest"
}

link_file "${DOTFILES_DIR}/dotfiles/.gitconfig" "${HOME}/.gitconfig"

# Powerlevel10k 설정 복원 (마이그레이션된 경우)
if [ -f "${DOTFILES_DIR}/dotfiles/.p10k.zsh" ]; then
    link_file "${DOTFILES_DIR}/dotfiles/.p10k.zsh" "${HOME}/.p10k.zsh"
    ok "Powerlevel10k 설정 복원됨"
fi

# .zshrc에 커스텀 설정 추가 (중복 방지)
if ! grep -q "# --- development-setting ---" ~/.zshrc 2>/dev/null; then
    info ".zshrc에 커스텀 설정을 추가합니다..."
    cat <<'EOF' >> ~/.zshrc

# --- development-setting ---

# Aliases (bat→cat, eza→ls, rg→grep 등)
[[ -f "$HOME/development-setting/dotfiles/.aliases" ]] && source "$HOME/development-setting/dotfiles/.aliases"

# VS Code 'code' command
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# iTerm2 Key Bindings (단어/줄 단위 이동)
bindkey -e
bindkey '\033b' backward-word       # Option + Left
bindkey '\033f' forward-word        # Option + Right
bindkey '\033[1;9D' beginning-of-line  # Command + Left
bindkey '\033[1;9C' end-of-line        # Command + Right

# 언어 버전 관리자
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# nvm (Node.js 버전 관리)
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# zoxide (스마트 cd)
eval "$(zoxide init zsh)"

# Powerlevel10k
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
EOF
fi

ok "Dotfiles"

# ============================================================
# 5. iTerm2 설정 마이그레이션
#    - 현재 Mac의 설정을 iterm2/ 폴더로 export
#    - iTerm2가 이 폴더에서 설정을 로드하도록 지정
# ============================================================
step "5/9 iTerm2"

ITERM2_DIR="${DOTFILES_DIR}/iterm2"

if [ -f "${HOME}/Library/Preferences/com.googlecode.iterm2.plist" ]; then
    cp "${HOME}/Library/Preferences/com.googlecode.iterm2.plist" "${ITERM2_DIR}/"
    info "현재 iTerm2 설정을 iterm2/ 폴더로 export"
fi

defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${ITERM2_DIR}"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

ok "iTerm2"

# ============================================================
# 6. GVM (Go Version Manager)
# ============================================================
step "6/9 GVM"

if [ ! -d "${HOME}/.gvm" ]; then
    info "Go 버전 관리자(GVM)를 설치합니다..."
    bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
fi

ok "GVM"

# ============================================================
# 7. macOS 시스템 설정 (Dock, Finder, 키보드 등)
# ============================================================
step "7/9 macOS 설정"

if [ -f "${DOTFILES_DIR}/macos.sh" ]; then
    zsh "${DOTFILES_DIR}/macos.sh"
fi

ok "macOS 설정"

# ============================================================
# 8. Raycast 설정 복원
# ============================================================
step "8/9 Raycast"

RAYCONFIG=$(ls -t "${DOTFILES_DIR}"/*.rayconfig 2>/dev/null | head -1)
if [ -n "$RAYCONFIG" ]; then
    info "Raycast 설정 파일을 발견했습니다: $(basename "$RAYCONFIG")"
    info "Raycast에서 import 대화상자가 열립니다..."
    open "$RAYCONFIG"
else
    info "Raycast 설정 파일(.rayconfig)이 없습니다."
    info "기존 Mac에서 Raycast > 'Export Settings & Data'로 export 후 이 폴더에 넣으세요."
fi

ok "Raycast"

# ============================================================
# 9. 권한 필요 앱 자동 실행 및 Git 설정
# ============================================================
step "9/9 최종 설정"

# 권한 필요 앱 자동 실행 (권한 팝업 트리거)
info "권한 필요 앱을 실행합니다..."
for app in "Rectangle" "Scroll Reverser" "Raycast" "Karabiner-Elements"; do
    if [ -d "/Applications/${app}.app" ] || [ -d "${HOME}/Applications/${app}.app" ]; then
        open -a "$app" 2>/dev/null && info "  ${app} 실행됨" || true
    fi
done

# Git 사용자 정보 대화형 입력
if grep -q "Your Name" "${DOTFILES_DIR}/dotfiles/.gitconfig" 2>/dev/null; then
    echo ""
    info "Git 사용자 정보를 설정합니다."
    printf "  이름: "
    read -r git_name
    printf "  이메일: "
    read -r git_email
    if [ -n "$git_name" ] && [ -n "$git_email" ]; then
        sed -i '' "s/Your Name/${git_name}/" "${DOTFILES_DIR}/dotfiles/.gitconfig"
        sed -i '' "s/your.email@example.com/${git_email}/" "${DOTFILES_DIR}/dotfiles/.gitconfig"
        ok "Git 사용자 정보 설정 완료"
    else
        warn "건너뛰. dotfiles/.gitconfig에서 수동으로 설정하세요."
    fi
fi

ok "최종 설정"

# ============================================================
# 완료
# ============================================================
echo ""
echo "\033[1;32m✅ 설치 완료!\033[0m"
echo ""
echo "📋 다음 단계:"
echo "  1. 터미널 재시작"
[ ! -f "${DOTFILES_DIR}/dotfiles/.p10k.zsh" ] && echo "  2. 'p10k configure'로 Powerlevel10k 설정"
echo "  3. 시스템 설정 > 개인정보 보호 > 손쉬운 사용에서 앱 권한 승인"
echo ""
echo "📖 자세한 포스트 설치 가이드는 README.md를 참고하세요."
