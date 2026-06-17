#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Claude Settings - Interactive Setup   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Input konfigurasi
read -p "ANTHROPIC_BASE_URL (default: https://ai.vannyezha.my.id): " BASE_URL
BASE_URL=${BASE_URL:-"https://ai.vannyezha.my.id"}
BASE_URL="${BASE_URL%/}"

read -p "ANTHROPIC_AUTH_TOKEN: " AUTH_TOKEN
echo ""

if [ -z "$AUTH_TOKEN" ]; then
    echo -e "${RED}❌ Token tidak boleh kosong!${NC}"
    exit 1
fi

echo -e "${BLUE}⏳ Mengambil daftar model...${NC}"

RESPONSE=$(curl -sS --max-time 15 \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    "$BASE_URL/v1/models")

MODELS=$(echo "$RESPONSE" | jq -r '.data[].id' 2>/dev/null | sort)

if [ -z "$MODELS" ]; then
    echo -e "${RED}❌ Tidak ada model ditemukan${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

mapfile -t MODEL_ARRAY <<< "$MODELS"
echo -e "${GREEN}✅ Ditemukan ${#MODEL_ARRAY[@]} model${NC}"
echo ""

# Fungsi pilih model - SEMUA OUTPUT TAMPILAN KE STDERR
select_model() {
    local TITLE=$1
    local FILTER=$2
    
    # Semua echo ke stderr (>&2)
    echo -e "${YELLOW}🎯 $TITLE${NC}" >&2
    if [ -n "$FILTER" ]; then
        echo -e "${BLUE}   (disarankan: $FILTER)${NC}" >&2
    fi
    echo "" >&2
    
    local i=1
    local FILTERED=()
    
    # Tampilkan model yang cocok dengan filter dulu
    if [ -n "$FILTER" ]; then
        for m in "${MODEL_ARRAY[@]}"; do
            if echo "$m" | grep -qi "$FILTER"; then
                FILTERED+=("$m")
                printf "   ${GREEN}%3d${NC}) %s ${GREEN}(recommended)${NC}\n" $i "$m" >&2
                ((i++))
            fi
        done
    fi
    
    # Tampilkan semua model lainnya
    for m in "${MODEL_ARRAY[@]}"; do
        if [ -z "$FILTER" ] || ! echo "$m" | grep -qi "$FILTER"; then
            FILTERED+=("$m")
            printf "   ${BLUE}%3d${NC}) %s\n" $i "$m" >&2
            ((i++))
        fi
    done
    echo "" >&2
    
    while true; do
        read -p "Pilihan (1-${#FILTERED[@]}): " CHOICE >&2
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le ${#FILTERED[@]} ]; then
            echo -e "${GREEN}   ✓ ${FILTERED[$((CHOICE-1))]}${NC}" >&2
            echo "" >&2
            # Hanya ini yang ke stdout (nilai yang dipilih)
            echo "${FILTERED[$((CHOICE-1))]}"
            return 0
        fi
        echo -e "${RED}   Input tidak valid${NC}" >&2
    done
}

# Pilih model dengan rekomendasi
OPUS_MODEL=$(select_model "Pilih model untuk OPUS (heavy thinking)" "opus|thinking")
SONNET_MODEL=$(select_model "Pilih model untuk SONNET (balanced)" "sonnet|gemini-pro")
HAIKU_MODEL=$(select_model "Pilih model untuk HAIKU (fast/low)" "haiku|flash|low")

# Simpan ke settings.json
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
mkdir -p "$CLAUDE_DIR"

if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}⚠️  Backup file lama dibuat${NC}"
fi

jq -n \
    --arg base "$BASE_URL" \
    --arg token "$AUTH_TOKEN" \
    --arg opus "$OPUS_MODEL" \
    --arg sonnet "$SONNET_MODEL" \
    --arg haiku "$HAIKU_MODEL" \
    '{
        env: {
            ANTHROPIC_BASE_URL: $base,
            ANTHROPIC_AUTH_TOKEN: $token,
            ANTHROPIC_DEFAULT_OPUS_MODEL: $opus,
            ANTHROPIC_DEFAULT_SONNET_MODEL: $sonnet,
            ANTHROPIC_DEFAULT_HAIKU_MODEL: $haiku
        },
        hasCompletedOnboarding: true
    }' > "$SETTINGS_FILE"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅ Konfigurasi berhasil disimpan!     ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "📂 File: ${BLUE}$SETTINGS_FILE${NC}"
echo ""
echo -e "${YELLOW}Ringkasan:${NC}"
echo "   BASE_URL : $BASE_URL"
echo "   TOKEN    : $AUTH_TOKEN"
echo "   OPUS     : $OPUS_MODEL"
echo "   SONNET   : $SONNET_MODEL"
echo "   HAIKU    : $HAIKU_MODEL"
