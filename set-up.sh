#!/bin/zsh

# ============================================================
# macOS 개발 환경 자동 설정 스크립트 (멱등성 보장)
# 사용법: chmod +x set-up.sh && ./set-up.sh
# 옵션:   ./set-up.sh --dry-run  (변경 없이 미리보기)
# ============================================================

# 스크립트 위치 기준으로 경로 설정
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Dry-run 모드 ---
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "\033[1;36m🔍 DRY-RUN 모드: 실제 변경 없이 미리보기만 합니다.\033[0m"
    echo ""
fi

# --- 컬러 로깅 ---
info()  { echo "\033[1;34m▸\033[0m $1"; }
ok()    { echo "\033[1;32m✓\033[0m $1"; }
warn()  { echo "\033[1;33m!\033[0m $1"; }
skip()  { echo "\033[1;90m⊘\033[0m $1 (이미 설정됨)"; }
step()  { echo "\n\033[1;35m━━━ $1 ━━━\033[0m"; }

# ============================================================
# 0. 기존 설정 백업
# ============================================================
step "0/9 기존 설정 백업"

BACKUP_DIR="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

backup_if_exists() {
    local file="$1"
    if [ -f "$file" ] && [ ! -L "$file" ]; then
        if $DRY_RUN; then
            info "[DRY-RUN] 백업 예정: ${file} → ${BACKUP_DIR}/"
            return
        fi
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/"
        info "백업: ${file} → ${BACKUP_DIR}/$(basename "$file")"
    fi
}

backup_if_exists "${HOME}/.zshrc"
backup_if_exists "${HOME}/.zprofile"
backup_if_exists "${HOME}/.gitconfig"

ok "기존 설정 백업 (${BACKUP_DIR:-불필요})"

# ============================================================
# 1. Homebrew 설치 및 업데이트
# ============================================================
step "1/9 Homebrew"

if ! command -v brew &>/dev/null; then
    if $DRY_RUN; then
        info "[DRY-RUN] Homebrew를 설치합니다"
    else
        info "Homebrew를 설치합니다..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Apple Silicon Mac의 경우 PATH 설정 (중복 방지)
    if [[ "$(uname -m)" == "arm64" ]]; then
        if ! grep -q '/opt/homebrew/bin/brew shellenv' ~/.zprofile 2>/dev/null; then
            if $DRY_RUN; then
                info "[DRY-RUN] ~/.zprofile에 brew shellenv 추가 예정"
            else
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            fi
        else
            skip "~/.zprofile brew shellenv"
        fi
        eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
    fi
else
    if $DRY_RUN; then
        skip "Homebrew 이미 설치됨"
    else
        info "Homebrew 업데이트 중..."
        brew update
    fi
fi
ok "Homebrew"

# ============================================================
# 2. Brewfile로 패키지 일괄 설치
#    - brew (CLI), cask (GUI), mas (App Store) 모두 포함
#    - --no-quarantine: Gatekeeper 경고 방지
# ============================================================
step "2/9 패키지 설치 (Brewfile)"

if $DRY_RUN; then
    info "[DRY-RUN] brew bundle --file=${DOTFILES_DIR}/Brewfile 실행 예정"
else
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

    HOMEBREW_CASK_OPTS="--no-quarantine" brew bundle --file="${DOTFILES_DIR}/Brewfile" || warn "일부 패키지 설치 실패 (위 로그 확인)"

    # Spotlight 인덱스 갱신: cask로 설치한 앱이 Spotlight 검색에 나타나도록
    info "Spotlight 인덱스를 갱신합니다..."
    sudo mdutil -a -i on 2>/dev/null || true
fi

ok "패키지 설치"

# ============================================================
# 3. Oh My Zsh + 플러그인 + 테마
# ============================================================
step "3/9 Oh My Zsh"

ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"

# 클론 또는 업데이트 함수 (멱등)
clone_or_pull() {
    local repo="$1" dest="$2" extra_args="${3:-}"
    if $DRY_RUN; then
        if [ -d "$dest/.git" ]; then
            info "[DRY-RUN] $(basename "$dest") 업데이트 예정"
        else
            info "[DRY-RUN] $(basename "$dest") 설치 예정"
        fi
        return
    fi
    if [ -d "$dest/.git" ]; then
        git -C "$dest" pull --ff-only &>/dev/null && info "  $(basename "$dest") 업데이트됨" || true
    else
        git clone ${extra_args} "$repo" "$dest" &>/dev/null && info "  $(basename "$dest") 설치됨"
    fi
}

if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    if $DRY_RUN; then
        info "[DRY-RUN] Oh My Zsh 설치 예정"
    else
        info "Oh My Zsh를 설치합니다..."
        /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
else
    skip "Oh My Zsh"
fi

# 플러그인 & 테마 설치/업데이트 (멱등)
clone_or_pull "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
clone_or_pull "https://github.com/zsh-users/zsh-autosuggestions.git" "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
clone_or_pull "https://github.com/romkatv/powerlevel10k.git" "${ZSH_CUSTOM}/themes/powerlevel10k" "--depth=1"

if ! $DRY_RUN; then
    # 테마 설정 (어떤 값이든 매칭하여 교체, 없으면 추가)
    if grep -q '^ZSH_THEME=' ~/.zshrc 2>/dev/null; then
        sed -i '' 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc
    else
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc
    fi

    # 플러그인 설정 (현재 plugins=(...) 내용과 관계없이 교체)
    DESIRED_PLUGINS="plugins=(git z fzf zsh-syntax-highlighting zsh-autosuggestions)"
    if grep -q '^plugins=' ~/.zshrc 2>/dev/null; then
        sed -i '' "s|^plugins=.*|${DESIRED_PLUGINS}|" ~/.zshrc
    else
        echo "${DESIRED_PLUGINS}" >> ~/.zshrc
    fi
else
    info "[DRY-RUN] .zshrc 테마/플러그인 설정 업데이트 예정"
fi

ok "Oh My Zsh"

# ============================================================
# 4. Dotfiles 심볼릭 링크 + .zshrc 설정
# ============================================================
step "4/9 Dotfiles"

# 심볼릭 링크 생성 (이미 올바르면 skip — 멱등)
link_file() {
    local src="$1" dest="$2"
    # 이미 올바른 심볼릭 링크라면 skip
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        skip "${dest} → 이미 올바른 링크"
        return 0
    fi
    if $DRY_RUN; then
        info "[DRY-RUN] ${dest} → ${src} 링크 예정"
        return 0
    fi
    if [ -f "$dest" ] || [ -L "$dest" ]; then
        mv "$dest" "${dest}.bak.$(date +%s)"
        info "${dest} 기존 파일 백업 완료"
    fi
    ln -sf "$src" "$dest"
    ok "${dest} → 심볼릭 링크 생성됨"
}

link_file "${DOTFILES_DIR}/dotfiles/.gitconfig" "${HOME}/.gitconfig"

# Powerlevel10k 설정 복원 (마이그레이션된 경우)
if [ -f "${DOTFILES_DIR}/dotfiles/.p10k.zsh" ]; then
    link_file "${DOTFILES_DIR}/dotfiles/.p10k.zsh" "${HOME}/.p10k.zsh"
    ok "Powerlevel10k 설정 복원됨"
fi

# --- .zshrc 마이그레이션: 기존 중복 설정 주석 처리 ---
migrate_zshrc() {
    local patterns=(
        'PYENV_ROOT'
        'pyenv init'
        'gvm/scripts/gvm'
        'NVM_DIR'
        'nvm.sh'
        'zoxide init'
        'p10k.zsh'
        'p10k-instant-prompt'
    )
    local marker="# --- development-setting ---"

    # 이미 관리 블록이 있으면 마이그레이션 불필요
    if grep -q "$marker" ~/.zshrc 2>/dev/null; then
        return 0
    fi

    info ".zshrc에서 중복 설정을 마이그레이션합니다..."

    # 관리 블록 밖에 있는 중복 설정을 주석 처리 (| 구분자로 / 충돌 방지)
    for pattern in "${patterns[@]}"; do
        if grep -v '^\s*#' ~/.zshrc 2>/dev/null | grep -q "$pattern"; then
            if $DRY_RUN; then
                info "[DRY-RUN] 기존 설정 주석 처리 예정: ${pattern}"
            else
                sed -i '' "s|^\([^#]*${pattern}\)|# [migrated] \1|" ~/.zshrc
                info "  기존 설정 주석 처리: ${pattern}"
            fi
        fi
    done

    # if/fi 블록 정합성 보장: migrated된 if 블록의 then/fi도 주석 처리
    if ! $DRY_RUN; then
        # "# [migrated] ...then" 다음에 오는 독립적인 fi를 주석 처리
        awk '
        /^# \[migrated\].*\bthen$/ { in_migrated_block=1; print; next }
        in_migrated_block && /^[[:space:]]*fi$/ { print "# [migrated] " $0; in_migrated_block=0; next }
        in_migrated_block && /^# \[migrated\]/ { print; next }
        in_migrated_block && /^[[:space:]]*#/ { print; next }
        { in_migrated_block=0; print }
        ' ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
    fi
}

migrate_zshrc

# .zshrc에 커스텀 설정 추가 (중복 방지)
if ! grep -q "# --- development-setting ---" ~/.zshrc 2>/dev/null; then
    if $DRY_RUN; then
        info "[DRY-RUN] .zshrc에 커스텀 블록 추가 예정"
    else
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
command -v pyenv >/dev/null && eval "$(pyenv init -)"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# nvm (Node.js 버전 관리)
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# zoxide (스마트 cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Powerlevel10k
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
EOF
    fi
else
    skip ".zshrc 커스텀 블록"
fi

ok "Dotfiles"

# ============================================================
# 5. iTerm2 설정 마이그레이션
#    - iterm2/ 폴더에 기존 설정이 없을 때만 현재 Mac 설정을 export
#    - iTerm2가 이 폴더에서 설정을 로드하도록 지정
# ============================================================
step "5/9 iTerm2"

ITERM2_DIR="${DOTFILES_DIR}/iterm2"
ITERM2_PLIST="${HOME}/Library/Preferences/com.googlecode.iterm2.plist"

# iterm2/ 폴더에 기존 설정이 없을 때만 현재 Mac 설정을 export (멱등)
if [ -f "$ITERM2_PLIST" ] && [ ! -f "${ITERM2_DIR}/com.googlecode.iterm2.plist" ]; then
    if $DRY_RUN; then
        info "[DRY-RUN] iTerm2 설정을 iterm2/ 폴더로 export 예정 (최초 1회)"
    else
        cp "$ITERM2_PLIST" "${ITERM2_DIR}/"
        info "현재 iTerm2 설정을 iterm2/ 폴더로 export (최초 1회)"
    fi
elif [ -f "${ITERM2_DIR}/com.googlecode.iterm2.plist" ]; then
    skip "iterm2/ 폴더의 기존 설정 사용"
else
    info "iTerm2 설정 파일이 없습니다 (iTerm2 설치 후 재실행하세요)"
fi

if ! $DRY_RUN; then
    defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${ITERM2_DIR}"
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
fi

ok "iTerm2"

# ============================================================
# 6. GVM (Go Version Manager)
# ============================================================
step "6/9 GVM"

if [ ! -d "${HOME}/.gvm" ]; then
    if $DRY_RUN; then
        info "[DRY-RUN] GVM 설치 예정"
    else
        info "Go 버전 관리자(GVM)를 설치합니다..."
        bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
    fi
else
    skip "GVM"
fi

ok "GVM"

# ============================================================
# 7. macOS 시스템 설정 (Dock, Finder, 키보드 등)
# ============================================================
step "7/9 macOS 설정"

if [ -f "${DOTFILES_DIR}/macos.sh" ]; then
    if $DRY_RUN; then
        info "[DRY-RUN] macOS 시스템 설정 적용 예정"
    else
        zsh "${DOTFILES_DIR}/macos.sh"
    fi
fi

ok "macOS 설정"

# ============================================================
# 8. Raycast 설정 복원
# ============================================================
step "8/9 Raycast"

RAYCONFIG=$(ls -t "${DOTFILES_DIR}"/*.rayconfig 2>/dev/null | head -1)
if [ -n "$RAYCONFIG" ]; then
    info "Raycast 설정 파일을 발견했습니다: $(basename "$RAYCONFIG")"
    if $DRY_RUN; then
        info "[DRY-RUN] Raycast import 대화상자 열기 예정"
    else
        info "Raycast에서 import 대화상자가 열립니다..."
        open "$RAYCONFIG"
    fi
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
        if $DRY_RUN; then
            info "[DRY-RUN] ${app} 실행 예정"
        else
            open -a "$app" 2>/dev/null && info "  ${app} 실행됨" || true
        fi
    fi
done

# Git 사용자 정보 대화형 입력
if grep -q "Your Name" "${DOTFILES_DIR}/dotfiles/.gitconfig" 2>/dev/null; then
    echo ""
    info "Git 사용자 정보를 설정합니다."
    if $DRY_RUN; then
        info "[DRY-RUN] Git 사용자 정보 입력 UI 표시 예정"
    else
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
fi

ok "최종 설정"

# ============================================================
# 완료
# ============================================================
echo ""
if $DRY_RUN; then
    echo "\033[1;36m🔍 DRY-RUN 완료. 위 내용을 확인 후 --dry-run 없이 실행하세요.\033[0m"
else
    echo "\033[1;32m✅ 설치 완료!\033[0m"
    echo ""
    echo "📋 다음 단계:"
    echo "  1. 터미널 재시작"
    [ ! -f "${DOTFILES_DIR}/dotfiles/.p10k.zsh" ] && echo "  2. 'p10k configure'로 Powerlevel10k 설정"
    echo "  3. 시스템 설정 > 개인정보 보호 > 손쉬운 사용에서 앱 권한 승인"
    echo ""
    echo "📖 자세한 포스트 설치 가이드는 README.md를 참고하세요."
    if [ -d "$BACKUP_DIR" ]; then
        echo ""
        echo "💾 백업 위치: ${BACKUP_DIR}"
        echo "   문제 발생 시: cp ${BACKUP_DIR}/.zshrc ~/.zshrc"
    fi
fi
