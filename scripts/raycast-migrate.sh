#!/bin/zsh

# ============================================================
# Raycast 설정 마이그레이션 스크립트
#
# 사용법:
#   ./scripts/raycast-migrate.sh export   # .rayconfig → JSON 변환
#   ./scripts/raycast-migrate.sh import   # .rayconfig 파일로 Raycast에 복원
#
# .rayconfig 파일은 gzip 압축된 JSON이므로
# 암호 없이 export하면 JSON으로 변환하여 git diff가 가능합니다.
# ============================================================

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

info()  { echo "\033[1;34m▸\033[0m $1"; }
ok()    { echo "\033[1;32m✓\033[0m $1"; }
warn()  { echo "\033[1;33m!\033[0m $1"; }

case "$1" in
    export)
        # 가장 최신의 .rayconfig 파일 찾기
        latest=$(ls -t "${DOTFILES_DIR}"/*.rayconfig 2>/dev/null | head -1)

        if [ -z "$latest" ]; then
            warn ".rayconfig 파일이 없습니다."
            echo ""
            info "Raycast에서 설정을 먼저 export하세요:"
            echo "  1. Raycast 열기 (⌥ + Space)"
            echo "  2. 'Export Settings & Data' 검색 후 실행"
            echo "  3. 암호를 설정하지 않고 export (git diff를 위해)"
            echo "  4. 저장된 .rayconfig 파일을 ${DOTFILES_DIR}/ 로 이동"
            echo ""
            echo "  그 후 다시 이 스크립트를 실행하세요."
            exit 1
        fi

        info "최신 .rayconfig: $(basename "$latest")"

        # 표준 이름으로 복사
        cp "$latest" "${DOTFILES_DIR}/raycast.rayconfig"

        # JSON으로 변환 (gzip 해제)
        if gunzip -k -f -S .rayconfig "${DOTFILES_DIR}/raycast.rayconfig" 2>/dev/null; then
            mv "${DOTFILES_DIR}/raycast" "${DOTFILES_DIR}/raycast.json"
            ok "raycast.json으로 변환 완료 (git diff 가능)"
            info "파일 크기: $(du -h "${DOTFILES_DIR}/raycast.json" | cut -f1)"
        else
            warn "JSON 변환 실패 (암호가 설정된 .rayconfig일 수 있습니다)"
            info "암호 없이 다시 export해주세요."
        fi
        ;;

    import)
        # .rayconfig 파일 찾기
        rayconfig="${DOTFILES_DIR}/raycast.rayconfig"

        if [ ! -f "$rayconfig" ]; then
            # 가장 최신의 .rayconfig 파일로 fallback
            rayconfig=$(ls -t "${DOTFILES_DIR}"/*.rayconfig 2>/dev/null | head -1)
        fi

        if [ -z "$rayconfig" ] || [ ! -f "$rayconfig" ]; then
            warn "import할 .rayconfig 파일이 없습니다."
            exit 1
        fi

        info "$(basename "$rayconfig") 파일을 Raycast로 import합니다..."
        open "$rayconfig"
        ok "Raycast에서 Import 대화상자가 열렸습니다."
        info "Raycast 앱에서 import를 완료하세요."
        ;;

    *)
        echo "Raycast 설정 마이그레이션 도구"
        echo ""
        echo "사용법:"
        echo "  $0 export    .rayconfig → JSON 변환 (버전관리용)"
        echo "  $0 import    .rayconfig 파일을 Raycast에 복원"
        echo ""
        echo "새 Mac에서:"
        echo "  1. set-up.sh가 자동으로 import를 시도합니다."
        echo "  2. 또는 .rayconfig 파일을 더블클릭하세요."
        ;;
esac
