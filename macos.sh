#!/bin/zsh

# ============================================================
# macOS 시스템 기본 설정
# 참고: https://macos-defaults.com
# 실행 후 로그아웃 또는 재시작이 필요할 수 있습니다.
# ============================================================

echo "⚙️  macOS 시스템 설정을 적용합니다..."

# --- Dock ---
# Dock 아이콘 크기
defaults write com.apple.dock tilesize -int 42
# 확대 효과 비활성화
defaults write com.apple.dock magnification -bool false
# Dock 자동 숨김
defaults write com.apple.dock autohide -bool true
# Dock 나타나는 딜레이 제거
defaults write com.apple.dock autohide-delay -float 0
# Dock 애니메이션 속도
defaults write com.apple.dock autohide-time-modifier -float 0.3
# 최근 사용 앱 표시 안 함
defaults write com.apple.dock show-recents -bool false
# 실행 중인 앱 표시등
defaults write com.apple.dock show-process-indicators -bool true
# 윈도우 최소화 효과: scale (기본 genie보다 빠름)
defaults write com.apple.dock mineffect -string "scale"
# Dock 위치 왼쪽
defaults write com.apple.dock orientation -string "left"

# --- Finder ---
# 숨김 파일 항상 표시
defaults write com.apple.finder AppleShowAllFiles -bool true
# 파일 확장자 항상 표시
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# 경로 표시줄 표시
defaults write com.apple.finder ShowPathbar -bool true
# 상태 표시줄 표시
defaults write com.apple.finder ShowStatusBar -bool true
# 기본 Finder 뷰: 리스트 (Nlsv=리스트, icnv=아이콘, clmv=컬럼, glyv=갤러리)
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
# 새 Finder 윈도우의 기본 위치: 다운로드 폴더
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads"
# 확장자 변경 시 경고 활성화
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true
# .DS_Store 파일 네트워크/USB에 생성 안 함
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- 키보드 ---
# 키 반복 속도 (낮을수록 빠름, 기본 6)
defaults write NSGlobalDomain KeyRepeat -int 0
# 키 반복 시작까지 대기 시간 (낮을수록 빠름, 기본 25)
defaults write NSGlobalDomain InitialKeyRepeat -int 0
# 자동 대문자 비활성화
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# 자동 마침표 비활성화
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
# 자동 스펠링 교정 비활성화
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
# Smart quotes 비활성화 (코딩 시 방해됨)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
# Smart dashes 비활성화
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# --- 스크린샷 ---
# 스크린샷 저장 위치 (기본 ~/Desktop)
mkdir -p "${HOME}/Desktop"
defaults write com.apple.screencapture location -string "${HOME}/Desktop"
# 스크린샷 포맷 (png, jpg, pdf, tiff)
defaults write com.apple.screencapture type -string "png"
# 스크린샷 그림자 제거
defaults write com.apple.screencapture disable-shadow -bool true

# --- 트랙패드 ---
# 탭으로 클릭
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
# 세 손가락 드래그
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

# --- 기타 ---
# 저장 시 기본적으로 iCloud가 아닌 로컬 디스크
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
# 크래시 리포터를 알림으로 (모달 팝업 대신)
defaults write com.apple.CrashReporter DialogType -string "notification"
# 시스템 소리 비활성화
defaults write NSGlobalDomain com.apple.sound.beep.volume -float 0.0

# --- 변경사항 적용 ---
echo "🔄 변경사항을 적용하기 위해 관련 프로세스를 재시작합니다..."
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "✅ macOS 시스템 설정이 적용되었습니다!"
echo "⚠️  일부 설정은 로그아웃/재시작 후 적용됩니다."
