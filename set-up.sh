#!/bin/zsh

# 스크립트가 오류 발생 시 중단되도록 설정
set -e

echo "🚀 macOS 궁극의 개발 환경 자동 설치를 시작합니다. (Cask 패키지 검증 완료)"

# 1. Homebrew 설치 및 업데이트
if ! command -v brew &> /dev/null; then
    echo "🍺 Homebrew를 설치합니다..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "🍺 Homebrew는 이미 설치되어 있습니다. 업데이트를 진행합니다..."
    brew update
fi

# 2. 필수 터미널 도구 설치
echo "⌨️ 필수 터미널 도구를 설치합니다..."
brew install git fzf kubectl kubectx k9s

# 3. GUI 앱 설치 (⭐️ Cask 이름 전체 검증 완료)
echo "💻 GUI 앱들을 설치합니다..."
brew install --cask \
    iterm2 \
    google-chrome \
    arc \
    notion \
    openlens \
    rancher \
    visual-studio-code \
    jetbrains-toolbox \
    raycast \
    magnet \
    lunar \
    scroll-reverser

# Ice (Menu bar manager)는 별도 tap 추가 후 설치
brew tap jordanbaird/ice
brew install --cask ice

# 4. Oh My Zsh 및 플러그인/테마 설치
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
if [ ! -d "$ZSH_CUSTOM" ]; then
    echo "셸을 Oh My Zsh로 업그레이드합니다..."
    /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "👍 Oh My Zsh는 이미 설치되어 있습니다."
fi

echo "🎨 Zsh 플러그인과 테마를 설치합니다..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting &>/dev/null || true
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM}/plugins/zsh-autosuggestions &>/dev/null || true
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k &>/dev/null || true

# 5. .zshrc 설정 업데이트
echo "⚙️ .zshrc 설정을 업데이트합니다..."
sed -i '' 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
sed -i '' 's/plugins=(git)/plugins=(git z fzf zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc

# 6. 언어 버전 관리자 설치
echo "📚 언어 버전 관리자를 설치합니다..."
brew install pyenv
brew install sdkman-cli
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

# 7. 환경변수, Alias 및 터미널 설정
if ! grep -q "# --- Custom Settings & Aliases ---" ~/.zshrc; then
  echo "✍️ .zshrc에 모든 커스텀 설정을 추가합니다..."
  cat <<'EOF' >> ~/.zshrc

# --- Custom Settings & Aliases ---

# VS Code 'code' command
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# iTerm2 Key Bindings (Word/Line navigation)
bindkey -e
bindkey '\033[1;5D' backward-word  # Option + Left
bindkey '\033[1;5C' forward-word   # Option + Right
bindkey '\033[1;9D' beginning-of-line # Command + Left
bindkey '\033[1;9C' end-of-line       # Command + Right

# Language Version Managers
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# General
alias l="ls -lAh"
alias la="ls -A"
alias ll="ls -l"
alias ..="cd .."
alias ...="cd ../.."
alias grep='grep --color=auto'

# Git
alias gs="git status"
alias ga="git add"
alias gaa="git add ."
alias gc="git checkout"
alias gco="git checkout"
alias gcm="git commit -m"
alias gp="git push"
alias gpull="git pull"
alias gl="git log --oneline"
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Kubernetes
alias k="kubectl"
alias kgp="k get pods -o wide"
alias kgn="k get nodes -o wide"
alias ka="k apply -f"
alias kd="k describe"
alias kdel="k delete"
alias klogs="k logs -f"
alias kx="kubectx"
alias kns="kubens"

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
EOF
fi

echo "\n✅ 모든 자동 설치가 완료되었습니다!"

# App Store 수동 설치 항목 강조 표시
echo "\n======================================================================="
echo "‼️ 중요: App Store 수동 설치 항목 ‼️"
echo "-----------------------------------------------------------------------"
echo "아래 앱들은 스크립트로 자동 설치할 수 없습니다."
echo "링크를 클릭하여 Mac App Store에서 직접 설치해주세요."
echo ""
echo "  1. Clop (클립보드 매니저)"
echo "     👉 링크: https://apps.apple.com/us/app/clop/id1516295283"
echo ""
echo "  2. Next Meeting (메뉴 막대 일정 알리미)"
echo "     👉 링크: https://apps.apple.com/us/app/next-meeting/id1520163534"
echo "=======================================================================\n"

echo "잠시 후 Powerlevel10k 설정 마법사를 시작합니다..."
sleep 2

# 새로운 zsh를 실행하여 모든 설정을 적용하고 p10k 설정 마법사를 자동으로 시작
exec zsh
