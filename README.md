# 🛠 macOS Development Setting

새로운 Mac에서 개발 환경을 원커맨드로 자동 설정합니다.

## 🚀 사용법

```bash
git clone https://github.com/BaeJi77/development-setting.git ~/development-setting
cd ~/development-setting
chmod +x set-up.sh && ./set-up.sh
```

---

## 📋 설치 후 설정 가이드 (Post-Install Checklist)

`set-up.sh` 실행 후, 아래 단계를 순서대로 수행하세요.

### Step 1: 터미널 재시작
셸 설정(`.zshrc`)이 반영되려면 터미널을 완전히 종료 후 다시 열어야 합니다.

### Step 2: Powerlevel10k 설정
최초 실행 시 설정 마법사가 자동으로 뜹니다. 뜨지 않으면:
```bash
p10k configure
```

### Step 3: 앱 권한 승인
**시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용**에서 다음 앱들을 허용:

| 앱 | 필요 권한 | 이유 |
|---|---|---|
| Rectangle | 손쉬운 사용 | 윈도우 관리 단축키 |
| Scroll Reverser | 손쉬운 사용 + 입력 모니터링 | 마우스/트랙패드 스크롤 분리 |
| Raycast | 손쉬운 사용 | 시스템 제어 |
| Karabiner-Elements | 입력 모니터링 | 키 리매핑 |

> 설치 스크립트가 이 앱들을 자동으로 실행하여 권한 팝업을 트리거합니다.

### Step 4: SSH 키 생성 및 GitHub 등록
```bash
# 1. 키 생성
ssh-keygen -t ed25519 -C "$(git config user.email)" -f ~/.ssh/id_ed25519 -N ""

# 2. ssh-agent에 추가
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. 공개키를 클립보드에 복사
pbcopy < ~/.ssh/id_ed25519.pub

# 4. GitHub에 등록
#    https://github.com/settings/ssh/new 에서 붙여넣기
#    또는:
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
```

### Step 5: Raycast 설정 복원
`set-up.sh`가 자동으로 `.rayconfig` 파일을 열어 Import를 시도합니다.  
자동으로 열리지 않았다면:
```bash
# 프로젝트 내 .rayconfig 파일 더블클릭
open ~/development-setting/*.rayconfig
```
또는 Raycast에서 `Import Settings & Data` 명령어를 검색하세요.

### Step 6: Karabiner-Elements 설정 (선택)
추천 키매핑:
- **CapsLock → Hyper Key** (⌃⌥⇧⌘): 앱 전환, 윈도우 관리 등에 활용
- **Right ⌘ → 한/영 전환**: 한영 전환 키가 없는 키보드용

설정 방법: Karabiner-Elements > Complex Modifications > Add rule

### Step 7: VS Code 확장 복원 (선택)
기존에 백업한 확장 목록이 있다면:
```bash
# 확장 목록에서 일괄 설치
cat ~/development-setting/vscode-extensions.txt | xargs -L 1 code --install-extension
```
확장 목록 백업:
```bash
./scripts/backup-apps.sh
```

### Step 8: 언어 런타임 설치
```bash
# Node.js (LTS)
nvm install --lts

# Python
pyenv install 3.12
pyenv global 3.12

# Go (GVM)
gvm install go1.22 -B
gvm use go1.22 --default
```

### Step 9: iTerm2 설정 확인
`set-up.sh`가 iTerm2 설정을 `iterm2/` 폴더에서 로드하도록 자동 설정합니다.  
확인: iTerm2 > Settings > General > Preferences > "Load preferences from a custom folder" ✅

---

## 🔄 기존 환경 마이그레이션

기존에 사용하던 Mac의 설정을 이 레포로 옮기는 방법입니다.  
**새 Mac 설정 전에 기존 Mac에서 먼저 수행하세요.**

### 1. 이 레포 클론 (기존 Mac에서)
```bash
git clone https://github.com/BaeJi77/development-setting.git ~/development-setting
cd ~/development-setting
```

### 2. iTerm2 설정 내보내기
iTerm2 > Settings > General > Preferences에서:
- ✅ "Load preferences from a custom folder or URL" 체크
- 폴더를 `~/development-setting/iterm2`로 지정
- "Save changes" 드롭다운에서 **"Automatically"** 선택

또는 터미널에서:
```bash
cp ~/Library/Preferences/com.googlecode.iterm2.plist ~/development-setting/iterm2/
```

### 3. Raycast 설정 내보내기
```bash
# 방법 1: Raycast 앱에서
# Raycast 열기 (⌥ + Space) → "Export Settings & Data" 검색 → 실행
# 저장 위치를 ~/development-setting/ 으로 지정
# ⚠️ git diff를 위해 암호를 설정하지 않는 것을 추천

# 방법 2: 스크립트 사용 (이미 export한 .rayconfig가 있는 경우)
./scripts/raycast-migrate.sh export    # JSON으로 변환하여 git diff 가능하게
```

### 4. Powerlevel10k 설정 내보내기
```bash
cp ~/.p10k.zsh ~/development-setting/dotfiles/.p10k.zsh
```

### 5. VS Code 확장 목록 백업
```bash
./scripts/backup-apps.sh
```

### 6. Git 설정 수정
```bash
# dotfiles/.gitconfig의 [user] 섹션을 본인 정보로 수정
vi ~/development-setting/dotfiles/.gitconfig
```

### 7. 현재 설치된 Homebrew 패키지 확인
```bash
# 현재 설치된 패키지 목록 확인 후 Brewfile에 누락된 것 추가
./scripts/sync-brewfile.sh
```

### 8. 커밋 & 푸시
```bash
cd ~/development-setting
git add -A
git commit -m "기존 환경 마이그레이션"
git push
```

이제 새 Mac에서 `./set-up.sh`만 실행하면 동일한 환경이 복원됩니다.

---

## 🏢 회사 전용 설정 추가하기

회사 VPN, 내부 도구, 전용 alias 등을 Git에 올리지 않고 로컬에서만 관리하는 방법입니다.

### 1. 회사 전용 설정 파일 생성
```bash
# 회사 전용 alias, 환경변수 등을 별도 파일로 관리
touch ~/.work_config
```

### 2. 내용 작성 예시
```bash
# ~/.work_config

# 회사 VPN
alias vpn-connect="sudo openconnect vpn.company.com"
alias vpn-disconnect="sudo pkill openconnect"

# 내부 도구
alias deploy="ssh deploy@production.internal ./deploy.sh"
alias staging="ssh ubuntu@staging.internal"

# 환경변수
export COMPANY_API_URL="https://api.internal.company.com"
export COMPANY_TOKEN="your-token-here"

# 회사 Kubernetes 클러스터
alias kprod="kubectx production"
alias kstage="kubectx staging"
```

### 3. .zshrc에 source 추가
```bash
echo '[[ -f ~/.work_config ]] && source ~/.work_config' >> ~/.zshrc
```

이렇게 하면:
- `~/.work_config`는 이 레포에 포함되지 않으므로 민감 정보가 보호됩니다
- 새 Mac에서는 파일을 수동으로 다시 생성하면 됩니다
- 여러 회사/프로젝트별로 `~/.work_config_A`, `~/.work_config_B` 등으로 분리할 수도 있습니다

---

## 📂 프로젝트 구조

```
development-setting/
├── set-up.sh              # 메인 설정 스크립트 (9단계)
├── Brewfile               # 패키지 선언 (brew bundle)
├── macos.sh               # macOS 시스템 기본 설정
├── dotfiles/
│   ├── .aliases           # 셸 단축 명령어
│   ├── .gitconfig         # Git 설정 (delta pager 포함)
│   └── .p10k.zsh          # Powerlevel10k 설정 (마이그레이션 후)
├── iterm2/                # iTerm2 설정 파일
├── scripts/
│   ├── raycast-migrate.sh # Raycast 설정 export/import
│   ├── sync-brewfile.sh   # Brewfile 동기화 확인
│   └── backup-apps.sh     # 앱 설정 백업 (VS Code 등)
├── *.rayconfig            # Raycast 설정 파일
└── README.md
```

## 📦 설치되는 도구

<details>
<summary><b>CLI 도구</b></summary>

| 도구 | 설명 | 대체 |
|---|---|---|
| `bat` | 구문 강조 파일 뷰어 | `cat` |
| `eza` | 아이콘/컬러/Git 상태 | `ls` |
| `ripgrep` | 초고속 텍스트 검색 | `grep` |
| `fd` | 초고속 파일 검색 | `find` |
| `fzf` | 퍼지 파인더 | - |
| `zoxide` | 스마트 cd | - |
| `git-delta` | Git diff 뷰어 (syntax highlighting) | `diff` |
| `jq` / `yq` | JSON/YAML 파서 | - |
| `gh` | GitHub CLI | - |
| `lazygit` / `lazydocker` | Git/Docker TUI | - |
| `htop` | 시스템 모니터 | `top` |
| `tldr` | 명령어 도움말 | `man` |
| `trash` | 휴지통으로 이동 | `rm` |
| `wget` | HTTP 다운로드 | - |
| `tree` | 디렉토리 구조 표시 | - |
| `watch` | 명령어 반복 실행 | - |
| `kubectl` / `kubectx` / `k9s` | Kubernetes | - |
| `pyenv` | Python 버전 관리 | - |
| `nvm` | Node.js 버전 관리 | - |

</details>

<details>
<summary><b>GUI 앱</b></summary>

| 앱 | 설명 |
|---|---|
| iTerm2 | 터미널 |
| Chrome, Arc | 브라우저 |
| Notion | 노트/위키 |
| Raycast | 런처 (Spotlight 대체) |
| VS Code | 에디터 |
| JetBrains Toolbox | IDE 관리 |
| Rancher | Docker/Kubernetes |
| OpenLens | Kubernetes IDE |
| Rectangle | 윈도우 관리 |
| Lunar | 모니터 밝기 |
| Scroll Reverser | 마우스 스크롤 방향 |
| Ice | 메뉴바 관리 |
| Keka | 압축 해제 |
| Karabiner-Elements | 키 리매핑 |

</details>

<details>
<summary><b>Mac App Store</b></summary>

Clop, Next Meeting

</details>

## 🔧 유틸리티 스크립트

| 스크립트 | 사용법 | 설명 |
|---|---|---|
| `scripts/raycast-migrate.sh` | `./scripts/raycast-migrate.sh export` | Raycast 설정 export/import |
| `scripts/sync-brewfile.sh` | `./scripts/sync-brewfile.sh` | 설치된 패키지와 Brewfile 비교 |
| `scripts/backup-apps.sh` | `./scripts/backup-apps.sh` | VS Code 확장 등 백업 |

## ⚙️ 커스터마이징

| 변경 대상 | 파일 |
|---|---|
| 패키지 추가/제거 | `Brewfile` |
| Alias 추가 | `dotfiles/.aliases` |
| Git 설정 | `dotfiles/.gitconfig` |
| macOS 설정 | `macos.sh` ([참고](https://macos-defaults.com)) |
| 회사 전용 설정 | `~/.work_config` (위 가이드 참고) |
