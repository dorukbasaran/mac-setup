#!/bin/bash

# ==============================================================================
# macOS Geliştirici Ortamı İnteraktif Kurulum Sihirbazı (Premium Version Selection Wizard)
# ==============================================================================

# Renk Tanımlamaları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Renk Sıfırlama
CHECK="✓"
FAILED_STEPS=()

# Seçilen Varsayılan Versiyonlar
SELECTED_FLUTTER_VERSION="stable"
SELECTED_JAVA_VERSION="25-tem"
SELECTED_RUBY_VERSION="3.4.1"

# Çevrimdışı / Hata Durumu Sürüm Listeleri (Fallback)
FALLBACK_FLUTTER_VERSIONS=("stable" "3.29.0" "3.27.0" "3.24.5" "3.22.3" "3.19.6")
FALLBACK_JAVA_VERSIONS=("25-tem" "23-tem" "21-tem" "17-tem" "11-tem" "21-zulu" "17-zulu")
FALLBACK_RUBY_VERSIONS=("3.4.1" "3.3.6" "3.2.6" "3.1.6")

# Halihazırda Yüklü Sürümleri Tespit Etme Fonksiyonu
detect_installed_versions() {
    # Ruby Sürüm Tespiti
    if command -v rbenv &>/dev/null; then
        local rbenv_v
        rbenv_v=$(rbenv global 2>/dev/null)
        if [ -n "$rbenv_v" ] && [ "$rbenv_v" != "system" ]; then
            SELECTED_RUBY_VERSION="$rbenv_v"
        else
            local ruby_v
            ruby_v=$(ruby -v 2>/dev/null | awk '{print $2}')
            if [ -n "$ruby_v" ]; then
                SELECTED_RUBY_VERSION="$ruby_v"
            fi
        fi
    else
        local ruby_v
        ruby_v=$(ruby -v 2>/dev/null | awk '{print $2}')
        if [ -n "$ruby_v" ]; then
            SELECTED_RUBY_VERSION="$ruby_v"
        fi
    fi

    # Java Sürüm Tespiti
    if [ -L "$HOME/.sdkman/candidates/java/current" ]; then
        local sdk_java
        sdk_java=$(readlink "$HOME/.sdkman/candidates/java/current" 2>/dev/null | awk -F'/' '{print $NF}')
        if [ -n "$sdk_java" ]; then
            SELECTED_JAVA_VERSION="$sdk_java"
        fi
    else
        local java_v
        java_v=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        if [ -n "$java_v" ]; then
            SELECTED_JAVA_VERSION="$java_v"
        fi
    fi

    # Flutter Sürüm Tespiti
    if command -v flutter &>/dev/null; then
        local flutter_v
        flutter_v=$(flutter --version 2>/dev/null | head -n 1 | awk '{print $2}')
        if [ -n "$flutter_v" ]; then
            SELECTED_FLUTTER_VERSION="$flutter_v"
        fi
    fi
}

# Sürüm tespitini hemen çalıştır
detect_installed_versions

# Kurulum Bileşenleri
CHOICES=(
    "Sistem Gereksinimleri (Xcode CLT & Rosetta 2)"
    "Homebrew Paket Yöneticisi"
    "Arayüzlü Uygulamalar (Docker, Postman, Ollama, Zed, vb.)"
    "Temel CLI Araçları & Diller (Go, Ruby, Helm, k9s, CocoaPods)"
    "Ruby & Rails Geliştirme Ortamı (Rails gem)"
    "Java & SDKMAN Geliştirme Ortamı (JDK 25 Temurin)"
    "Flutter SDK & Mobil Geliştirme Ortamı"
    "Rust & Cargo Geliştirme Ortamı"
    "Node.js & Web Geliştirme Ortamı (NVM, Yarn, pnpm)"
    "Terminal Özelleştirme & Starship Entegrasyonu"
    "Yapay Zeka Kodlama Araçları (Codex, Copilot, Antigravity, OpenCode)"
)

# Seçim durumları (1: seçili, 0: değil)
SELECTIONS=(1 1 1 1 1 1 1 1 1 1 1)

# Arayüzlü Uygulamalar (Casks)
APP_NAMES=("docker" "postman" "ollama" "zed" "spotify" "android-studio" "rectangle")
APP_LABELS=("Docker" "Postman" "Ollama" "Zed Editor" "Spotify" "Android Studio" "Rectangle (Window Manager)")
APP_SELECTIONS=(1 1 1 1 1 1 1) # Varsayılan olarak hepsi seçili

# Yapay Zeka Kodlama Araçları
AI_NAMES=("codex" "copilot-cli" "antigravity" "opencode")
AI_LABELS=("Codex CLI (OpenAI)" "GitHub Copilot CLI" "Antigravity CLI (Google)" "OpenCode (AnomalyCo)")
AI_SELECTIONS=(1 1 1 1) # Varsayılan olarak hepsi seçili

# Temalar
THEME_NAMES=("Gruvbox-dark" "Dracula" "Nord" "Solarized-Dark" "rose-pine" "Monokai" "One-Dark" "tokyo-night")
THEME_LABELS=("Gruvbox Dark" "Dracula" "Nord" "Solarized Dark" "Rosé Pine" "Monokai" "One Dark" "Tokyo Night")
THEME_SELECTIONS=(1 0 1 0 1 0 1 0) # Çoklu tema seçilebilir
THEME_DEFAULT=2 # Varsayılan olarak Nord seçili

CURRENT_INDEX=0
FOCUS_SIDE="left"
TOTAL_ITEMS=13 # 11 bileşen + 2 aksiyon

# İmleç Kontrolü ve Temizleme
cleanup_cursor() {
    tput cnorm # İmleci göster
}
trap cleanup_cursor EXIT
tput civis # İmleci gizle

record_failure() {
    FAILED_STEPS+=("$1")
    echo -e "${RED}! $1 başarısız oldu veya eksik tamamlandı.${NC}"
}

append_once() {
    local target_file="$1"
    local marker="$2"
    local content="$3"

    touch "$target_file"
    if ! grep -Fq "$marker" "$target_file"; then
        printf "\n%s\n" "$content" >> "$target_file"
    fi
}

brew_shellenv_line() {
    if [ -x /opt/homebrew/bin/brew ]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    elif [ -x /usr/local/bin/brew ]; then
        echo 'eval "$(/usr/local/bin/brew shellenv)"'
    else
        echo ""
    fi
}

load_brew_shellenv() {
    local brew_env
    brew_env=$(brew_shellenv_line)
    if [ -n "$brew_env" ]; then
        eval "$brew_env"
    fi
}

install_homebrew() {
    load_brew_shellenv
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi

    echo "Homebrew kuruluyor..."
    echo -e "${YELLOW}DİKKAT: Homebrew resmi kurulum scripti indiriliyor ve çalıştırılıyor.${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
    load_brew_shellenv

    local brew_env_line
    brew_env_line=$(brew_shellenv_line)
    if [ -n "$brew_env_line" ]; then
        append_once "$HOME/.zprofile" "brew shellenv" "$brew_env_line"
        eval "$brew_env_line"
    fi

    command -v brew >/dev/null 2>&1
}

ensure_brew_available() {
    load_brew_shellenv
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi

    echo -e "${YELLOW}Bu adım için Homebrew gerekli; sistemde bulunamadı, şimdi kurulacak.${NC}"
    if install_homebrew; then
        return 0
    fi

    record_failure "Homebrew kurulumu"
    echo -e "${RED}Homebrew yüklenemediği için bu adım devam edemiyor.${NC}"
    return 1
}

print_failure_summary() {
    if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
        return 0
    fi

    echo -e "\n${YELLOW}DİKKAT: Bazı adımlar eksik veya başarısız tamamlandı:${NC}"
    for step in "${FAILED_STEPS[@]}"; do
        echo -e "${YELLOW}- $step${NC}"
    done
}

terminal_profile_exists() {
    local profile_name="$1"
    osascript -e "tell application \"Terminal\" to exists settings set \"$profile_name\"" 2>/dev/null | grep -q "true"
}

read_terminal_profile_name() {
    local theme_path="$1"
    local fallback_name="$2"
    local profile_name

    profile_name=$(/usr/libexec/PlistBuddy -c "Print :name" "$theme_path" 2>/dev/null)
    if [ -n "$profile_name" ]; then
        echo "$profile_name"
    else
        echo "$fallback_name"
    fi
}

import_terminal_profile() {
    local theme_path="$1"
    local profile_name="$2"

    if ! terminal_profile_exists "$profile_name"; then
        open "$theme_path"
        for _ in {1..10}; do
            sleep 0.5
            if terminal_profile_exists "$profile_name"; then
                return 0
            fi
        done
        return 1
    fi

    return 0
}

apply_terminal_profile_font() {
    local profile_name="$1"
    local font_applied=false
    local f_name

    for f_name in "JetBrainsMono Nerd Font" "JetBrainsMonoNerdFont-Regular" "JetBrainsMonoNF-Regular" "JetBrainsMonoNF" "JetBrains Mono"; do
        if osascript -e "tell application \"Terminal\" to set font name of settings set \"$profile_name\" to \"$f_name\"" 2>/dev/null; then
            font_applied=true
            break
        fi
    done
    osascript -e "tell application \"Terminal\" to set font size of settings set \"$profile_name\" to 16" 2>/dev/null || true

    [ "$font_applied" = true ]
}

# Sürüm Çekme Fonksiyonları
fetch_flutter_versions() {
    # Git ls-remote ile etiketleri sorgula (Strict 2 saniye timeout ile)
    local fetched=""
    local tmp_file
    tmp_file=$(mktemp)

    (
        GIT_TERMINAL_PROMPT=0 git ls-remote --tags --refs https://github.com/flutter/flutter.git 2>/dev/null | \
        awk -F'/' '{print $3}' | \
        grep -E "^[3-9]\.[0-9]+\.[0-9]+$" | \
        sort -t. -k1,1nr -k2,2nr -k3,3nr | \
        head -n 10 > "$tmp_file"
    ) &
    local git_pid=$!

    # Watchdog süreci
    (
        sleep 2
        if kill -0 "$git_pid" 2>/dev/null; then
            kill -9 "$git_pid" 2>/dev/null
        fi
    ) &
    local watchdog_pid=$!

    # Git işleminin bitmesini bekle
    wait "$git_pid" 2>/dev/null
    kill "$watchdog_pid" 2>/dev/null
    wait "$watchdog_pid" 2>/dev/null

    if [ -s "$tmp_file" ]; then
        fetched=$(cat "$tmp_file")
    fi
    rm -f "$tmp_file"

    if [ -n "$fetched" ]; then
        echo "stable"
        echo "$fetched"
    else
        for v in "${FALLBACK_FLUTTER_VERSIONS[@]}"; do
            echo "$v"
        done
    fi
}

fetch_java_versions() {
    # JDK LTS ve Popüler Güncel Sürümler (Instant and Reliable)
    for v in "${FALLBACK_JAVA_VERSIONS[@]}"; do
        echo "$v"
    done
}

fetch_ruby_versions() {
    # Ruby Kararlı ve Popüler Sürümler (Instant and Reliable)
    for v in "${FALLBACK_RUBY_VERSIONS[@]}"; do
        echo "$v"
    done
}

read_keypress() {
    local key
    if [ -n "$ZSH_VERSION" ]; then
        read -r -s -k 1 key
    else
        read -r -s -n 1 key
    fi

    if [[ $key == $'\x1b' ]]; then
        local timeout="0.1"
        if [ -n "$BASH_VERSION" ]; then
            if [ "${BASH_VERSINFO[0]}" -le 3 ]; then
                timeout="1"
            fi
        fi

        if [ -n "$ZSH_VERSION" ]; then
            read -r -s -t "$timeout" -k 2 key
        else
            read -r -s -t "$timeout" -n 2 key
        fi
        if [[ $key == "[A" || $key == "OA" ]]; then
            echo "UP"
        elif [[ $key == "[B" || $key == "OB" ]]; then
            echo "DOWN"
        elif [[ $key == "[C" || $key == "OC" ]]; then
            echo "RIGHT"
        elif [[ $key == "[D" || $key == "OD" ]]; then
            echo "LEFT"
        fi
    elif [[ $key == "" ]]; then
        echo "ENTER"
    elif [[ $key == " " ]]; then
        echo "SPACE"
    elif [[ $key == "v" || $key == "V" || $key == "d" || $key == "D" ]]; then
        echo "DEFAULT"
    elif [[ $key == "a" || $key == "A" ]]; then
        echo "ALL"
    elif [[ $key == "q" || $key == "Q" ]]; then
        echo "QUIT"
    fi
}

# Klavye Gezinmeli Versiyon Alt Menüsü
show_version_submenu() {
    local title="$1"
    local current_val="$2"
    shift 2
    local options=("$@")
    local total=${#options[@]}
    local selected_idx=0

    # Mevcut değeri bulup imleci oraya yerleştir
    for i in "${!options[@]}"; do
        if [[ "${options[$i]}" == "$current_val" ]]; then
            selected_idx=$i
            break
        fi
    done

    while true; do
        clear >&2
        echo -e "${BLUE}=======================================================${NC}" >&2
        echo -e "${BLUE}               $title Sürüm Seçimi                     ${NC}" >&2
        echo -e "${BLUE}=======================================================${NC}" >&2
        echo -e "Klavye ${YELLOW}Yön Tuşları (↑/↓)${NC} ile gezinin." >&2
        echo -e "Seçiminizi onaylamak için ${GREEN}ENTER${NC} veya ${GREEN}SPACE${NC} tuşuna basın." >&2
        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2

        for i in "${!options[@]}"; do
            local marker=" "
            if [[ "${options[$i]}" == "$current_val" ]]; then
                marker="${GREEN}${CHECK}${NC}"
            fi

            if [ $selected_idx -eq $i ]; then
                echo -e "${CYAN}➔ [${marker}] ${options[$i]}${NC}" >&2
            else
                echo -e "   [${marker}] ${options[$i]}" >&2
            fi
        done

        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2

        local action
        action=$(read_keypress)

        case $action in
            "UP")
                selected_idx=$(( (selected_idx - 1 + total) % total ))
                ;;
            "DOWN")
                selected_idx=$(( (selected_idx + 1) % total ))
                ;;
            "SPACE"|"ENTER")
                echo "${options[$selected_idx]}"
                return 0
                ;;
            "LEFT"|"QUIT")
                echo "$current_val"
                return 0
                ;;
        esac
    done
}

show_ai_submenu() {
    local selected_idx=0
    local total=$((${#AI_NAMES[@]} + 1)) # araçlar + 1 "Kaydet ve Geri Dön"
    local save_idx=${#AI_NAMES[@]}

    while true; do
        clear >&2
        echo -e "${BLUE}=======================================================${NC}" >&2
        echo -e "${BLUE}            Yapay Zeka Kodlama Araçları Seçimi         ${NC}" >&2
        echo -e "${BLUE}=======================================================${NC}" >&2
        echo -e "Klavye ${YELLOW}Yön Tuşları (↑/↓)${NC} ile gezinin." >&2
        echo -e "Aracı seçmek/bırakmak için ${YELLOW}SPACE${NC} veya ${YELLOW}ENTER${NC}'a basın." >&2
        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2

        for i in "${!AI_NAMES[@]}"; do
            local marker=" "
            if [ ${AI_SELECTIONS[$i]} -eq 1 ]; then
                marker="${GREEN}${CHECK}${NC}"
            fi

            if [ $selected_idx -eq $i ]; then
                echo -e "${CYAN}➔ [${marker}] ${AI_LABELS[$i]}${NC}" >&2
            else
                echo -e "   [${marker}] ${AI_LABELS[$i]}" >&2
            fi
        done

        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2
        if [ $selected_idx -eq $save_idx ]; then
            echo -e "${CYAN}➔ ${GREEN}[ Kaydet ve Geri Dön ]${NC}" >&2
        else
            echo -e "   ${GREEN}[ Kaydet ve Geri Dön ]${NC}" >&2
        fi
        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2

        local action
        action=$(read_keypress)

        case $action in
            "UP")
                selected_idx=$(( (selected_idx - 1 + total) % total ))
                ;;
            "DOWN")
                selected_idx=$(( (selected_idx + 1) % total ))
                ;;
            "SPACE"|"ENTER")
                if [ $selected_idx -eq $save_idx ]; then
                    return 0
                else
                    AI_SELECTIONS[$selected_idx]=$(( 1 - AI_SELECTIONS[$selected_idx] ))
                fi
                ;;
            "LEFT"|"QUIT")
                return 0
                ;;
        esac
    done
}

show_app_submenu() {
    local selected_idx=0
    local total=8 # 7 uygulamalar + 1 "Kaydet ve Geri Dön"

    while true; do
        clear >&2
        echo -e "${BLUE}=======================================================${NC}" >&2
        echo -e "${BLUE}             Arayüzlü Uygulama Seçimi                  ${NC}" >&2
        echo -e "${BLUE}=======================================================${NC}" >&2
        echo -e "Klavye ${YELLOW}Yön Tuşları (↑/↓)${NC} ile gezinin." >&2
        echo -e "Uygulamayı seçmek/bırakmak için ${YELLOW}SPACE${NC} veya ${YELLOW}ENTER${NC}'a basın." >&2
        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2

        for i in {0..6}; do
            local marker=" "
            if [ ${APP_SELECTIONS[$i]} -eq 1 ]; then
                marker="${GREEN}${CHECK}${NC}"
            fi

            if [ $selected_idx -eq $i ]; then
                echo -e "${CYAN}➔ [${marker}] ${APP_LABELS[$i]}${NC}" >&2
            else
                echo -e "   [${marker}] ${APP_LABELS[$i]}" >&2
            fi
        done

        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2
        if [ $selected_idx -eq 7 ]; then
            echo -e "${CYAN}➔ ${GREEN}[ Kaydet ve Geri Dön ]${NC}" >&2
        else
            echo -e "   ${GREEN}[ Kaydet ve Geri Dön ]${NC}" >&2
        fi
        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2

        local action
        action=$(read_keypress)

        case $action in
            "UP")
                selected_idx=$(( (selected_idx - 1 + total) % total ))
                ;;
            "DOWN")
                selected_idx=$(( (selected_idx + 1) % total ))
                ;;
            "SPACE"|"ENTER")
                if [ $selected_idx -eq 7 ]; then
                    return 0
                else
                    APP_SELECTIONS[$selected_idx]=$(( 1 - APP_SELECTIONS[$selected_idx] ))
                fi
                ;;
            "LEFT"|"QUIT")
                return 0
                ;;
        esac
    done
}

show_theme_submenu() {
    local selected_idx=0
    local num_themes=${#THEME_NAMES[@]}
    local total=$((num_themes + 1)) # themes + 1 "Kaydet ve Geri Dön"

    while true; do
        clear >&2
        echo -e "${BLUE}=======================================================${NC}" >&2
        echo -e "${BLUE}             Terminal Tema & Özelleştirme              ${NC}" >&2
        echo -e "${BLUE}=======================================================${NC}" >&2
        echo -e "Klavye ${YELLOW}Yön Tuşları (↑/↓)${NC} ile gezinin." >&2
        echo -e "Temayı kurmak için ${YELLOW}SPACE${NC} veya ${YELLOW}ENTER${NC} ile seçin/bırakın." >&2
        echo -e "Seçili temayı varsayılan yapmak için ${PURPLE}'v'${NC} tuşuna basın." >&2
        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2

        for i in "${!THEME_NAMES[@]}"; do
            local marker=" "
            if [ ${THEME_SELECTIONS[$i]} -eq 1 ]; then
                marker="${GREEN}${CHECK}${NC}"
            fi

            local default_str=""
            if [ $THEME_DEFAULT -eq $i ]; then
                default_str=" ${PURPLE}(Varsayılan)${NC}"
            fi

            if [ $selected_idx -eq $i ]; then
                echo -e "${CYAN}➔ [${marker}] ${THEME_LABELS[$i]}${default_str}${NC}" >&2
            else
                echo -e "   [${marker}] ${THEME_LABELS[$i]}${default_str}" >&2
            fi
        done

        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2
        if [ $selected_idx -eq $num_themes ]; then
            echo -e "${CYAN}➔ ${GREEN}[ Kaydet ve Geri Dön ]${NC}" >&2
        else
            echo -e "   ${GREEN}[ Kaydet ve Geri Dön ]${NC}" >&2
        fi
        echo -e "${BLUE}-------------------------------------------------------${NC}" >&2

        local action
        action=$(read_keypress)

        case $action in
            "UP")
                selected_idx=$(( (selected_idx - 1 + total) % total ))
                ;;
            "DOWN")
                selected_idx=$(( (selected_idx + 1) % total ))
                ;;
            "SPACE"|"ENTER")
                if [ $selected_idx -eq $num_themes ]; then
                    local theme_sum=0
                    for val in "${THEME_SELECTIONS[@]}"; do
                        theme_sum=$((theme_sum + val))
                    done
                    if [ $theme_sum -eq 0 ]; then
                        echo -e "\n${RED}HATA: En az bir tema seçmelisiniz!${NC}" >&2
                        sleep 1.5
                        continue
                    fi
                    return 0
                else
                    THEME_SELECTIONS[$selected_idx]=$(( 1 - THEME_SELECTIONS[$selected_idx] ))
                    if [ ${THEME_SELECTIONS[$selected_idx]} -eq 0 ] && [ $THEME_DEFAULT -eq $selected_idx ]; then
                        for k in "${!THEME_NAMES[@]}"; do
                            if [ ${THEME_SELECTIONS[$k]} -eq 1 ]; then
                                THEME_DEFAULT=$k
                                break
                            fi
                        done
                    fi
                fi
                ;;
            "DEFAULT")
                if [ $selected_idx -ge 0 ] && [ $selected_idx -lt $num_themes ]; then
                    THEME_SELECTIONS[$selected_idx]=1
                    THEME_DEFAULT=$selected_idx
                fi
                ;;
            "LEFT"|"QUIT")
                local theme_sum=0
                for val in "${THEME_SELECTIONS[@]}"; do
                    theme_sum=$((theme_sum + val))
                done
                if [ $theme_sum -eq 0 ]; then
                    echo -e "\n${RED}HATA: En az bir tema seçmelisiniz!${NC}" >&2
                    sleep 1.5
                    continue
                fi
                return 0
                ;;
        esac
    done
}

toggle_all() {
    local sum=0
    for val in "${SELECTIONS[@]}"; do
        sum=$((sum + val))
    done
    if [ $sum -gt 0 ]; then
        SELECTIONS=(0 0 0 0 0 0 0 0 0 0 0)
    else
        SELECTIONS=(1 1 1 1 1 1 1 1 1 1 1)
    fi
}

render_menu() {
    clear
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "${BLUE}        macOS Geliştirici Ortamı Kurulum Sihirbazı     ${NC}"
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "Klavye ${YELLOW}Yön Tuşları (↑/↓)${NC} ile gezinin, ${YELLOW}SPACE${NC} veya ${YELLOW}ENTER${NC} ile seçimi değiştirin."
    echo -e "Apps için ${YELLOW}➔ (Sağ)${NC} ile ${YELLOW}[ App Seç ]${NC}'e, Diller için ${YELLOW}[ Sürüm Seç ]${NC}'e, Starship için ise ${YELLOW}[ Tema Seç ]${NC}'e geçebilirsiniz."
    echo -e "Yapay Zeka Araçları için ${YELLOW}➔ (Sağ)${NC} tuşuna basarak ${YELLOW}[ Araç Seç ]${NC}'e geçebilirsiniz."
    echo -e "Hepsini seçmek/bırakmak için ${YELLOW}'a'${NC} tuşuna basabilirsiniz."
    echo -e "Kuruluma başlamak için en alttaki ${GREEN}[ Kuruluma Başla ]${NC} seçeneğinde ${GREEN}ENTER${NC}'a basın."
    echo -e "${BLUE}-------------------------------------------------------${NC}"

    # Bileşen Listesi (0-10)
    for i in {0..10}; do
        local check=" "
        if [ ${SELECTIONS[$i]} -eq 1 ]; then
            check="${GREEN}${CHECK}${NC}"
        fi

        local label="${CHOICES[$i]}"
        local version_btn=""

        if [ $i -eq 2 ]; then
            local selected_count=0
            for val in "${APP_SELECTIONS[@]}"; do
                selected_count=$((selected_count + val))
            done
            local total_apps=${#APP_NAMES[@]}
            local clean_label="${CHOICES[$i]} ($selected_count/$total_apps)"
            local padded_label
            padded_label=$(printf "%-70s" "$clean_label")
            label="${CHOICES[$i]} (${CYAN}$selected_count/$total_apps${NC})${padded_label:${#clean_label}}"

            if [ $CURRENT_INDEX -eq 2 ] && [ "$FOCUS_SIDE" = "right" ]; then
                version_btn=" ➔ ${YELLOW}[ App Seç ]${NC}"
            else
                version_btn="   ${CYAN}[ App Seç ]${NC}"
            fi
        elif [ $i -eq 4 ]; then
            local clean_label="${CHOICES[$i]} (v$SELECTED_RUBY_VERSION)"
            local padded_label
            padded_label=$(printf "%-70s" "$clean_label")
            label="${CHOICES[$i]} (${CYAN}v$SELECTED_RUBY_VERSION${NC})${padded_label:${#clean_label}}"

            if [ $CURRENT_INDEX -eq 4 ] && [ "$FOCUS_SIDE" = "right" ]; then
                version_btn=" ➔ ${YELLOW}[ Sürüm Seç ]${NC}"
            else
                version_btn="   ${CYAN}[ Sürüm Seç ]${NC}"
            fi
        elif [ $i -eq 5 ]; then
            local clean_label="${CHOICES[$i]} (v$SELECTED_JAVA_VERSION)"
            local padded_label
            padded_label=$(printf "%-70s" "$clean_label")
            label="${CHOICES[$i]} (${CYAN}v$SELECTED_JAVA_VERSION${NC})${padded_label:${#clean_label}}"

            if [ $CURRENT_INDEX -eq 5 ] && [ "$FOCUS_SIDE" = "right" ]; then
                version_btn=" ➔ ${YELLOW}[ Sürüm Seç ]${NC}"
            else
                version_btn="   ${CYAN}[ Sürüm Seç ]${NC}"
            fi
        elif [ $i -eq 6 ]; then
            local clean_label="${CHOICES[$i]} (v$SELECTED_FLUTTER_VERSION)"
            local padded_label
            padded_label=$(printf "%-70s" "$clean_label")
            label="${CHOICES[$i]} (${CYAN}v$SELECTED_FLUTTER_VERSION${NC})${padded_label:${#clean_label}}"

            if [ $CURRENT_INDEX -eq 6 ] && [ "$FOCUS_SIDE" = "right" ]; then
                version_btn=" ➔ ${YELLOW}[ Sürüm Seç ]${NC}"
            else
                version_btn="   ${CYAN}[ Sürüm Seç ]${NC}"
            fi
        elif [ $i -eq 9 ]; then
            local default_theme="${THEME_LABELS[$THEME_DEFAULT]}"
            local clean_label="${CHOICES[$i]} ($default_theme)"
            local padded_label
            padded_label=$(printf "%-70s" "$clean_label")
            label="${CHOICES[$i]} (${CYAN}$default_theme${NC})${padded_label:${#clean_label}}"

            if [ $CURRENT_INDEX -eq 9 ] && [ "$FOCUS_SIDE" = "right" ]; then
                version_btn=" ➔ ${YELLOW}[ Tema Seç ]${NC}"
            else
                version_btn="   ${CYAN}[ Tema Seç ]${NC}"
            fi
        elif [ $i -eq 10 ]; then
            local selected_count=0
            for val in "${AI_SELECTIONS[@]}"; do
                selected_count=$((selected_count + val))
            done
            local total_ai=${#AI_NAMES[@]}
            local clean_label="${CHOICES[$i]} ($selected_count/$total_ai)"
            local padded_label
            padded_label=$(printf "%-70s" "$clean_label")
            label="${CHOICES[$i]} (${CYAN}$selected_count/$total_ai${NC})${padded_label:${#clean_label}}"

            if [ $CURRENT_INDEX -eq 10 ] && [ "$FOCUS_SIDE" = "right" ]; then
                version_btn=" ➔ ${YELLOW}[ Araç Seç ]${NC}"
            else
                version_btn="   ${CYAN}[ Araç Seç ]${NC}"
            fi
        fi

        if [ $CURRENT_INDEX -eq $i ]; then
            if [ "$FOCUS_SIDE" = "left" ]; then
                echo -e "${CYAN}➔ [${check}] ${label}${NC}${version_btn}"
            else
                echo -e "   [${check}] ${label}${version_btn}"
            fi
        else
            echo -e "   [${check}] ${label}${version_btn}"
        fi
    done

    echo -e "${BLUE}-------------------------------------------------------${NC}"

    # Aksiyonlar (11-12)
    if [ $CURRENT_INDEX -eq 11 ]; then
        echo -e "${CYAN}➔ ${GREEN}[ Kuruluma Başla ]${NC}"
    else
        echo -e "   ${GREEN}[ Kuruluma Başla ]${NC}"
    fi

    if [ $CURRENT_INDEX -eq 12 ]; then
        echo -e "${CYAN}➔ ${RED}[ İptal Et ve Çık ]${NC}"
    else
        echo -e "   ${RED}[ İptal Et ve Çık ]${NC}"
    fi

    echo -e "${BLUE}-------------------------------------------------------${NC}"
}

# İnteraktif Döngü
while true; do
    render_menu
    action=$(read_keypress)

    case $action in
        "UP")
            FOCUS_SIDE="left"
            CURRENT_INDEX=$(( (CURRENT_INDEX - 1 + TOTAL_ITEMS) % TOTAL_ITEMS ))
            ;;
        "DOWN")
            FOCUS_SIDE="left"
            CURRENT_INDEX=$(( (CURRENT_INDEX + 1) % TOTAL_ITEMS ))
            ;;
        "RIGHT")
            if [ $CURRENT_INDEX -eq 2 ] || [ $CURRENT_INDEX -eq 4 ] || [ $CURRENT_INDEX -eq 5 ] || [ $CURRENT_INDEX -eq 6 ] || [ $CURRENT_INDEX -eq 9 ] || [ $CURRENT_INDEX -eq 10 ]; then
                FOCUS_SIDE="right"
            fi
            ;;
        "LEFT")
            if [ $CURRENT_INDEX -eq 2 ] || [ $CURRENT_INDEX -eq 4 ] || [ $CURRENT_INDEX -eq 5 ] || [ $CURRENT_INDEX -eq 6 ] || [ $CURRENT_INDEX -eq 9 ] || [ $CURRENT_INDEX -eq 10 ]; then
                FOCUS_SIDE="left"
            fi
            ;;
        "ENTER")
            if [ $CURRENT_INDEX -eq 11 ]; then
                # Kuruluma Başla tetiklendiğinde ENTER ile devam et
                if [ ${SELECTIONS[9]} -eq 1 ]; then
                    theme_sum=0
                    for val in "${THEME_SELECTIONS[@]}"; do
                        theme_sum=$((theme_sum + val))
                    done
                    if [ $theme_sum -eq 0 ]; then
                        echo -e "\n${RED}HATA: Terminal özelleştirme aktifken en az bir tema seçmelisiniz!${NC}"
                        sleep 2
                        continue
                    fi
                fi
                break
            elif [ $CURRENT_INDEX -eq 12 ]; then
                # İptal Et ve Çık
                echo -e "\n${RED}Kurulum iptal edildi. Çıkış yapılıyor...${NC}"
                tput cnorm
                exit 0
            elif [ $CURRENT_INDEX -eq 2 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # App Alt Menüsü
                show_app_submenu
                SELECTIONS[2]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 4 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Ruby Versiyon Alt Menüsü
                clear
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "${BLUE}        macOS Geliştirici Ortamı Kurulum Sihirbazı     ${NC}"
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "\n${YELLOW}Kurulabilir Ruby sürümleri listeleniyor... ⏳${NC}\n"
                echo -e "${BLUE}-------------------------------------------------------${NC}"

                ruby_vers=("${FALLBACK_RUBY_VERSIONS[@]}")
                result=$(show_version_submenu "Ruby" "$SELECTED_RUBY_VERSION" "${ruby_vers[@]}")
                SELECTED_RUBY_VERSION="$result"
                SELECTIONS[4]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 5 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Java Versiyon Alt Menüsü
                clear
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "${BLUE}        macOS Geliştirici Ortamı Kurulum Sihirbazı     ${NC}"
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "\n${YELLOW}Kurulabilir Java (JDK) sürümleri listeleniyor... ⏳${NC}\n"
                echo -e "${BLUE}-------------------------------------------------------${NC}"

                java_vers=("${FALLBACK_JAVA_VERSIONS[@]}")
                result=$(show_version_submenu "Java" "$SELECTED_JAVA_VERSION" "${java_vers[@]}")
                SELECTED_JAVA_VERSION="$result"
                SELECTIONS[5]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 6 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Flutter Versiyon Alt Menüsü
                clear
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "${BLUE}        macOS Geliştirici Ortamı Kurulum Sihirbazı     ${NC}"
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "\n${YELLOW}Resmi Git deposundan kararlı Flutter sürümleri sorgulanıyor... ⏳${NC}\n"
                echo -e "${BLUE}-------------------------------------------------------${NC}"

                flutter_vers=()
                while IFS= read -r line; do
                    flutter_vers+=("$line")
                done <<< "$(fetch_flutter_versions)"

                result=$(show_version_submenu "Flutter" "$SELECTED_FLUTTER_VERSION" "${flutter_vers[@]}")
                SELECTED_FLUTTER_VERSION="$result"
                SELECTIONS[6]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 9 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Terminal Tema Alt Menüsü
                show_theme_submenu
                SELECTIONS[9]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 10 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # AI Araç Alt Menüsü
                show_ai_submenu
                SELECTIONS[10]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            else
                # Sürüm menüsü olmayan diğer bileşenleri ENTER ile de seçebiliriz
                if [ $CURRENT_INDEX -ge 0 ] && [ $CURRENT_INDEX -le 10 ]; then
                    SELECTIONS[$CURRENT_INDEX]=$(( 1 - SELECTIONS[$CURRENT_INDEX] ))
                fi
            fi
            ;;
        "SPACE")
            if [ $CURRENT_INDEX -eq 2 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # App Alt Menüsü
                show_app_submenu
                SELECTIONS[2]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 4 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Ruby Versiyon Alt Menüsü (Sağ taraftayken SPACE basılırsa)
                clear
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "${BLUE}        macOS Geliştirici Ortamı Kurulum Sihirbazı     ${NC}"
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "\n${YELLOW}Kurulabilir Ruby sürümleri listeleniyor... ⏳${NC}\n"
                echo -e "${BLUE}-------------------------------------------------------${NC}"

                ruby_vers=("${FALLBACK_RUBY_VERSIONS[@]}")
                result=$(show_version_submenu "Ruby" "$SELECTED_RUBY_VERSION" "${ruby_vers[@]}")
                SELECTED_RUBY_VERSION="$result"
                SELECTIONS[4]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 5 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Java Versiyon Alt Menüsü (Sağ taraftayken SPACE basılırsa)
                clear
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "${BLUE}        macOS Geliştirici Ortamı Kurulum Sihirbazı     ${NC}"
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "\n${YELLOW}Kurulabilir Java (JDK) sürümleri listeleniyor... ⏳${NC}\n"
                echo -e "${BLUE}-------------------------------------------------------${NC}"

                java_vers=("${FALLBACK_JAVA_VERSIONS[@]}")
                result=$(show_version_submenu "Java" "$SELECTED_JAVA_VERSION" "${java_vers[@]}")
                SELECTED_JAVA_VERSION="$result"
                SELECTIONS[5]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 6 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Flutter Versiyon Alt Menüsü (Sağ taraftayken SPACE basılırsa)
                clear
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "${BLUE}        macOS Geliştirici Ortamı Kurulum Sihirbazı     ${NC}"
                echo -e "${BLUE}=======================================================${NC}"
                echo -e "\n${YELLOW}Resmi Git deposundan kararlı Flutter sürümleri sorgulanıyor... ⏳${NC}\n"
                echo -e "${BLUE}-------------------------------------------------------${NC}"

                flutter_vers=()
                while IFS= read -r line; do
                    flutter_vers+=("$line")
                done <<< "$(fetch_flutter_versions)"

                result=$(show_version_submenu "Flutter" "$SELECTED_FLUTTER_VERSION" "${flutter_vers[@]}")
                SELECTED_FLUTTER_VERSION="$result"
                SELECTIONS[6]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 9 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Terminal Tema Alt Menüsü
                show_theme_submenu
                SELECTIONS[9]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 10 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # AI Araç Alt Menüsü
                show_ai_submenu
                SELECTIONS[10]=1 # Seçim yapılınca otomatik aktif yap
                FOCUS_SIDE="left"
            else
                # Sol taraftayken normal space davranışı
                if [ $CURRENT_INDEX -ge 0 ] && [ $CURRENT_INDEX -le 10 ]; then
                    SELECTIONS[$CURRENT_INDEX]=$(( 1 - SELECTIONS[$CURRENT_INDEX] ))
                fi
            fi
            ;;
        "ALL")
            toggle_all
            ;;
        "QUIT")
            echo -e "\n${RED}Kurulum iptal edildi. Çıkış yapılıyor...${NC}"
            tput cnorm
            exit 0
            ;;
    esac
done

tput cnorm # Kurulum başlarken imleci geri getir
clear
echo -e "${GREEN}Seçimleriniz alındı! Kurulum başlıyor...${NC}"
echo -e "${BLUE}=======================================================${NC}\n"

# 1. Sistem Gereksinimleri
if [ ${SELECTIONS[0]} -eq 1 ]; then
    echo -e "${YELLOW}>> Sistem gereksinimleri kontrol ediliyor...${NC}"
    if ! xcode-select -p >/dev/null 2>&1; then
        xcode-select --install
        echo -e "${YELLOW}Xcode Command Line Tools kurulumu başlatıldı.${NC}"
        echo -e "${YELLOW}Kurulum tamamlandıktan sonra scripti tekrar çalıştırın.${NC}"
        exit 1
    fi

    if /usr/bin/pgrep oahd >/dev/null 2>&1; then
        echo "Rosetta 2 zaten kurulu."
    else
        sudo softwareupdate --install-rosetta --agree-to-license
    fi
    echo -e "${GREEN}✓ Sistem gereksinimleri tamamlandı.${NC}\n"
fi

# 2. Homebrew Kurulumu
if [ ${SELECTIONS[1]} -eq 1 ]; then
    echo -e "${YELLOW}>> Homebrew paket yöneticisi kontrol ediliyor...${NC}"
    load_brew_shellenv
    if ! command -v brew &> /dev/null; then
        if ! install_homebrew; then
            record_failure "Homebrew kurulumu"
            echo -e "${RED}Homebrew yüklenemediği için Homebrew gerektiren adımlar çalışamaz.${NC}"
            exit 1
        fi
    else
        brew update || record_failure "Homebrew update"
    fi
    echo -e "${GREEN}✓ Homebrew tamamlandı.${NC}\n"
fi

# 3. Casks Kurulumu
if [ ${SELECTIONS[2]} -eq 1 ]; then
    echo -e "${YELLOW}>> Seçilen Arayüzlü Uygulamalar (Casks) kuruluyor...${NC}"
    ensure_brew_available || exit 1

    get_app_path() {
        local cask="$1"
        case "$cask" in
            "docker") echo "/Applications/Docker.app" ;;
            "postman") echo "/Applications/Postman.app" ;;
            "ollama") echo "/Applications/Ollama.app" ;;
            "zed") echo "/Applications/Zed.app" ;;
            "spotify") echo "/Applications/Spotify.app" ;;
            "android-studio") echo "/Applications/Android Studio.app" ;;
            "rectangle") echo "/Applications/Rectangle.app" ;;
            *) echo "" ;;
        esac
    }

    casks_to_install=()
    for i in "${!APP_NAMES[@]}"; do
        if [ ${APP_SELECTIONS[$i]} -eq 1 ]; then
            cask="${APP_NAMES[$i]}"
            label="${APP_LABELS[$i]}"
            app_path=""
            app_path=$(get_app_path "$cask")

            installed=false
            version=""

            if [ -n "$app_path" ] && [ -d "$app_path" ]; then
                installed=true
                version=$(defaults read "$app_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
            fi

            if [ "$installed" = true ]; then
                if [ -n "$version" ]; then
                    echo -e "${GREEN}✓ $label zaten kurulu (Sürüm: v$version).${NC}"
                else
                    echo -e "${GREEN}✓ $label zaten kurulu.${NC}"
                fi
            else
                casks_to_install+=("$cask")
            fi
        fi
    done

    if [ ${#casks_to_install[@]} -gt 0 ]; then
        echo "Kurulacak uygulamalar: ${casks_to_install[*]}"
        if brew install --cask "${casks_to_install[@]}"; then
            echo -e "${GREEN}✓ Seçilen uygulamalar başarıyla kuruldu.${NC}\n"
        else
            record_failure "Arayüzlü uygulama kurulumu"
        fi

        # Reset Launchpad to force newly installed casks to show up in App Drawer immediately
        echo "Kurulan uygulamaların Launchpad (Uygulama Çekmecesi) veritabanında hemen görünmesi sağlanıyor..."
        defaults write com.apple.dock ResetLaunchPad -bool true && killall Dock 2>/dev/null || true
    else
        echo -e "${GREEN}✓ Tüm seçili uygulamalar zaten kurulu, yeni kurulum yapılmadı.${NC}\n"
    fi
fi

# 4. Temel CLI ve Diller
if [ ${SELECTIONS[3]} -eq 1 ]; then
    echo -e "${YELLOW}>> CLI araçları, Go ve Ruby kuruluyor...${NC}"
    ensure_brew_available || exit 1
    brew install bash git curl unzip zip go ruby helm k9s cocoapods kubernetes-cli || record_failure "Temel CLI araçları"
    brew link --overwrite kubernetes-cli 2>/dev/null || true

    if [ -d "/Applications/Xcode.app" ]; then
        echo "Tam sürüm Xcode bulundu, ayarları yapılıyor..."
        sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
        sudo xcodebuild -runFirstLaunch
    else
        echo "DİKKAT: Tam sürüm Xcode bulunamadı (/Applications/Xcode.app)."
        echo "        iOS ve macOS geliştirmeleri için App Store'dan Xcode indirmelisiniz."
    fi
    echo -e "${GREEN}✓ CLI ve dil bağımlılıkları tamamlandı.${NC}\n"
fi

# 5. Ruby & Rails (rbenv entegre edildi)
if [ ${SELECTIONS[4]} -eq 1 ]; then
    echo -e "${YELLOW}>> Ruby & Rails kurulumu yapılıyor (Seçilen Sürüm: v$SELECTED_RUBY_VERSION)...${NC}"
    ensure_brew_available || exit 1

    # rbenv ve ruby-build kurulumu
    echo "rbenv ve ruby-build kuruluyor..."
    brew install rbenv ruby-build || record_failure "rbenv ve ruby-build kurulumu"
    if ! command -v rbenv >/dev/null 2>&1; then
        record_failure "rbenv komutu"
        echo -e "${RED}rbenv bulunamadığı için Ruby & Rails adımı atlanıyor.${NC}"
    else

        # rbenv yapılandırması
        ZSHRC_FILE="$HOME/.zshrc"
        append_once "$ZSHRC_FILE" "rbenv init" '# Initialize rbenv
eval "$(rbenv init -)"'
        eval "$(rbenv init -)"

        echo "Ruby v$SELECTED_RUBY_VERSION kuruluyor (Bu işlem birkaç dakika sürebilir)..."
        if rbenv versions | grep -q "$SELECTED_RUBY_VERSION"; then
            echo "✓ Ruby v$SELECTED_RUBY_VERSION zaten rbenv ile kurulu."
        else
            rbenv install "$SELECTED_RUBY_VERSION" || record_failure "Ruby v$SELECTED_RUBY_VERSION kurulumu"
        fi

        rbenv global "$SELECTED_RUBY_VERSION" || record_failure "Ruby global sürüm ayarı"

        # Gem path ayarı
        append_once "$HOME/.zprofile" ".rbenv/shims" 'export PATH="$HOME/.rbenv/shims:$PATH"'
        export PATH="$HOME/.rbenv/shims:$PATH"

        echo "Rails gem kuruluyor..."
        gem install rails || record_failure "Rails gem kurulumu"
        rbenv rehash
    fi
    echo -e "${GREEN}✓ Ruby & Rails kurulumu tamamlandı.${NC}\n"
fi

# 6. Java & SDKMAN
if [ ${SELECTIONS[5]} -eq 1 ]; then
    echo -e "${YELLOW}>> Java & SDKMAN kurulumu yapılıyor (Seçilen Sürüm: v$SELECTED_JAVA_VERSION)...${NC}"
    if [ ! -d "$HOME/.sdkman" ]; then
        echo -e "${YELLOW}DİKKAT: SDKMAN resmi kurulum scripti indiriliyor ve çalıştırılıyor.${NC}"
        curl -fsSL "https://get.sdkman.io" | bash || record_failure "SDKMAN kurulumu"
    fi

    if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        record_failure "SDKMAN init dosyası"
        echo -e "${RED}SDKMAN yüklenemediği için Java adımı atlanıyor.${NC}"
    else
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        echo "JDK $SELECTED_JAVA_VERSION kuruluyor..."
        sdk install java "$SELECTED_JAVA_VERSION" || record_failure "JDK $SELECTED_JAVA_VERSION kurulumu"
        sdk default java "$SELECTED_JAVA_VERSION" || record_failure "JDK varsayılan sürüm ayarı"
    fi

    echo -e "${GREEN}✓ Java & SDKMAN kurulumu tamamlandı.${NC}\n"
fi

# 7. Flutter SDK
if [ ${SELECTIONS[6]} -eq 1 ]; then
    echo -e "${YELLOW}>> Flutter SDK ve Mobil Geliştirme Ortamı kuruluyor (Seçilen Sürüm: v$SELECTED_FLUTTER_VERSION)...${NC}"
    FLUTTER_DIR="$HOME/development/flutter"

    if [ ! -d "$FLUTTER_DIR" ]; then
        mkdir -p ~/development
        echo "Flutter SDK $SELECTED_FLUTTER_VERSION klonlanıyor..."
        git clone https://github.com/flutter/flutter.git -b "$SELECTED_FLUTTER_VERSION" "$FLUTTER_DIR" || record_failure "Flutter SDK klonlama"
        append_once "$HOME/.zprofile" "development/flutter/bin" 'export PATH="$PATH:$HOME/development/flutter/bin"'
        export PATH="$PATH:$HOME/development/flutter/bin"
        flutter precache || record_failure "Flutter precache"
    else
        echo "Mevcut Flutter kurulumu bulundu. Seçilen sürüme ($SELECTED_FLUTTER_VERSION) geçiş yapılıyor..."
        (
            cd "$FLUTTER_DIR" || exit 1
            git fetch --tags &&
            git checkout "$SELECTED_FLUTTER_VERSION" &&
            flutter precache
        ) || record_failure "Flutter sürüm geçişi"
    fi

    echo "Flutter Doctor çalıştırılıyor ve lisanslar onaylanıyor..."
    export PATH="$PATH:$HOME/development/flutter/bin"
    yes | flutter doctor --android-licenses >/dev/null 2>&1 || true
    flutter doctor || true

    echo -e "${BLUE}==========================================================================${NC}"
    echo -e "DİKKAT: Android SDK eksik hatası alıyorsanız, uygulamalar klasöründeki"
    echo -e "Android Studio'yu BİR KERE AÇIP, varsayılan Android SDK'sının inmesini"
    echo -e "beklemelisiniz. Ardından lisans hatası almamak için terminalde:"
    echo -e "flutter doctor --android-licenses"
    echo -e "komutunu çalıştırabilirsiniz."
    echo -e "${BLUE}==========================================================================${NC}"
    echo -e "${GREEN}✓ Flutter kurulumu tamamlandı.${NC}\n"
fi

# 8. Rust & Cargo
if [ ${SELECTIONS[7]} -eq 1 ]; then
    echo -e "${YELLOW}>> Rust ve Cargo kuruluyor...${NC}"
    if ! command -v rustc >/dev/null 2>&1; then
        echo -e "${YELLOW}DİKKAT: Rustup resmi kurulum scripti indiriliyor ve çalıştırılıyor.${NC}"
        curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" | sh -s -- -y || record_failure "Rustup kurulumu"
        [ -s "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
        append_once "$HOME/.zprofile" ".cargo/env" 'source "$HOME/.cargo/env"'
    else
        rustup update || record_failure "Rustup update"
    fi
    echo -e "${GREEN}✓ Rust ve Cargo kurulumu tamamlandı.${NC}\n"
fi

# 9. Node.js (NVM) & Web Dev
if [ ${SELECTIONS[8]} -eq 1 ]; then
    echo -e "${YELLOW}>> Node.js (NVM) ve Web Geliştirme Araçları kuruluyor...${NC}"
    if [ ! -d "$HOME/.nvm" ]; then
        echo -e "${YELLOW}DİKKAT: NVM resmi kurulum scripti indiriliyor ve çalıştırılıyor.${NC}"
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || record_failure "NVM kurulumu"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        echo "NVM zaten kurulu, güncelleniyor..."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    if ! command -v nvm >/dev/null 2>&1; then
        record_failure "NVM komutu"
        echo -e "${RED}NVM yüklenemediği için Node.js adımı atlanıyor.${NC}"
        echo -e "${GREEN}✓ Node.js & Web Geliştirme Araçları tamamlandı.${NC}\n"
    else
        nvm install --lts || record_failure "Node.js LTS kurulumu"
        nvm use --lts || record_failure "Node.js LTS aktif etme"
        nvm alias default 'lts/*' || record_failure "NVM varsayılan alias"

        echo "Yarn ve pnpm kuruluyor..."
        npm install -g yarn pnpm || record_failure "Yarn ve pnpm kurulumu"
        echo -e "${GREEN}✓ Node.js & Web Geliştirme Araçları tamamlandı.${NC}\n"
    fi
fi

# 10. Terminal Özelleştirme & Temalar
if [ ${SELECTIONS[9]} -eq 1 ]; then
    echo -e "${YELLOW}>> Terminal Özelleştirmesi ve Tema Kurulumu Başlatılıyor...${NC}"
    ensure_brew_available || exit 1

    if ! command -v starship &> /dev/null; then
        echo "Starship kuruluyor..."
        brew install starship || record_failure "Starship kurulumu"
    else
        echo "✓ Starship zaten kurulu."
    fi

    if ! brew list --cask 2>/dev/null | grep -q "font-jetbrains-mono-nerd-font"; then
        echo "JetBrains Mono Nerd Font kuruluyor..."
        brew install --cask font-jetbrains-mono-nerd-font || record_failure "JetBrains Mono Nerd Font kurulumu"
    else
        echo "✓ JetBrains Mono Nerd Font zaten kurulu."
    fi

    # Seçilen her temayı indir ve içe aktar
    default_theme_name=""
    for i in "${!THEME_NAMES[@]}"; do
        if [ ${THEME_SELECTIONS[$i]} -eq 1 ]; then
            theme_name=""
            theme_url=""
            theme_file=""

            case $i in
                0)
                    theme_name="Gruvbox-dark"
                    theme_url="https://raw.githubusercontent.com/morhetz/gruvbox-contrib/master/osx-terminal/Gruvbox-dark.terminal"
                    theme_file="Gruvbox-dark.terminal"
                    ;;
                1)
                    theme_name="Dracula"
                    theme_url="https://raw.githubusercontent.com/dracula/terminal-app/main/Dracula.terminal"
                    theme_file="Dracula.terminal"
                    ;;
                2)
                    theme_name="Nord"
                    theme_url="https://raw.githubusercontent.com/nordtheme/terminal-app/refs/heads/develop/src/xml/Nord.terminal"
                    theme_file="Nord.terminal"
                    ;;
                3)
                    theme_name="Solarized Dark"
                    theme_url="https://raw.githubusercontent.com/altercation/solarized/master/osx-terminal.app-colors-solarized/Solarized%20Dark%20ansi.terminal"
                    theme_file="Solarized-Dark.terminal"
                    ;;
                4)
                    theme_name="rose-pine"
                    theme_url="https://raw.githubusercontent.com/rose-pine/terminal.app/main/rose-pine.terminal"
                    theme_file="rose-pine.terminal"
                    ;;
                5)
                    theme_name="Monokai"
                    theme_url="https://raw.githubusercontent.com/stephenway/monokai.terminal/master/Monokai.terminal"
                    theme_file="Monokai.terminal"
                    ;;
                6)
                    theme_name="One Dark"
                    theme_url="https://raw.githubusercontent.com/nathanbuchar/atom-one-dark-terminal/master/scheme/terminal/One%20Dark.terminal"
                    theme_file="One-Dark.terminal"
                    ;;
                7)
                    theme_name="tokyo-night"
                    theme_url="https://raw.githubusercontent.com/l3olton/tokyo-night.terminal/main/tokyo-night.terminal"
                    theme_file="tokyo-night.terminal"
                    ;;
            esac

            theme_path="$HOME/$theme_file"
            if [ -f "$theme_path" ]; then
                echo "[$theme_name] zaten yüklü, indirme atlanıyor..."
            else
                echo "[$theme_name] terminal renk profili indiriliyor..."
                curl -fsSL "$theme_url" -o "$theme_path" || record_failure "$theme_name tema indirme"
            fi

            if [[ -f "$theme_path" ]]; then
                terminal_profile_name=$(read_terminal_profile_name "$theme_path" "$theme_name")

                if import_terminal_profile "$theme_path" "$terminal_profile_name"; then
                    echo -e "${GREEN}✓ $terminal_profile_name profili Terminal'e aktarıldı.${NC}"
                else
                    record_failure "$theme_name tema import"
                    echo -e "${YELLOW}! $terminal_profile_name profili Terminal'de doğrulanamadı.${NC}"
                fi

                if [ $THEME_DEFAULT -eq $i ]; then
                    default_theme_name="$terminal_profile_name"
                fi

                if apply_terminal_profile_font "$terminal_profile_name"; then
                    echo -e "${GREEN}✓ $terminal_profile_name profili JetBrains Mono yazı tipiyle başarıyla yapılandırıldı.${NC}"
                else
                    echo -e "${YELLOW}! $terminal_profile_name profili yapılandırıldı ancak JetBrains Mono yazı tipi uygulanamadı (Terminal'i yeniden başlatıp tekrar deneyebilirsiniz).${NC}"
                fi
            else
                echo -e "${RED}DİKKAT: $theme_name profili bulunamadı!${NC}"
            fi
        fi
    done

    # Varsayılan Tema Seçimi
    starship_preset="gruvbox-rainbow" # Gruvbox'taki efsanevi renkli imleç/prompt tüm temalar için aktif olsun!
    if [ -z "$default_theme_name" ]; then
        default_theme_name="${THEME_NAMES[$THEME_DEFAULT]}"
    fi

    echo "Varsayılan tema '$default_theme_name' olarak ayarlanıyor..."
    defaults write com.apple.Terminal "Default Window Settings" -string "$default_theme_name"
    defaults write com.apple.Terminal "Startup Window Settings" -string "$default_theme_name"

    # Aktif terminal pencerelerini/sekmelerini seçilen varsayılan temaya geçir (AppleScript ile canlı geçiş)
    echo "Terminal canlı teması '$default_theme_name' olarak güncelleniyor..."
    if terminal_profile_exists "$default_theme_name"; then
        osascript -e "tell application \"Terminal\" to if exists window 1 then set current settings of first window to settings set \"$default_theme_name\"" 2>/dev/null || true
    else
        record_failure "$default_theme_name varsayılan tema ayarı"
    fi

    # Zsh Yapılandırmasının Güncellenmesi (.zshrc)
    echo "Starship ve terminal kısayolları için .zshrc yapılandırması güncelleniyor..."
    ZSHRC_FILE="$HOME/.zshrc"
    append_once "$ZSHRC_FILE" "starship init zsh" '# Initialize Starship Prompt
eval "$(starship init zsh)"'

    # Clear komutunun scrollback buffer'ı da temizlemesi için alias ekle
    echo "clear komutu için scrollback temizleme alias'ı kontrol ediliyor..."
    append_once "$ZSHRC_FILE" "alias clear=" '# Clear command that also clears the scrollback buffer
alias clear="clear && printf '\''\e[3J'\''"'

    # Starship Teması Preset Oluşturulması
    echo "Starship varsayılan teması ($starship_preset) kontrol ediliyor..."
    mkdir -p "$HOME/.config"
    if [ -f "$HOME/.config/starship.toml" ]; then
        echo "✓ Mevcut starship.toml bulundu, üzerine yazılmadı."
    else
        starship preset "$starship_preset" -o "$HOME/.config/starship.toml" || record_failure "Starship preset oluşturma"
    fi
    echo -e "${GREEN}✓ Terminal özelleştirmeleri başarıyla uygulandı.${NC}\n"
fi

# 11. Yapay Zeka Araçları (Codex, Copilot, Antigravity, OpenCode)
if [ ${SELECTIONS[10]} -eq 1 ]; then
    echo -e "${YELLOW}>> Yapay Zeka Kodlama Araçları kuruluyor...${NC}"

    if [ ${AI_SELECTIONS[0]} -eq 1 ]; then
        ensure_brew_available || exit 1
        if ! command -v codex &> /dev/null; then
            echo "Codex CLI kuruluyor..."
            brew install --cask codex || record_failure "Codex CLI kurulumu"
        else
            echo "✓ Codex CLI zaten kurulu."
        fi
    fi

    if [ ${AI_SELECTIONS[1]} -eq 1 ]; then
        ensure_brew_available || exit 1
        if ! command -v copilot &> /dev/null && ! command -v copilot-cli &> /dev/null; then
            echo "GitHub Copilot CLI kuruluyor..."
            brew install copilot-cli || record_failure "GitHub Copilot CLI kurulumu"
        else
            echo "✓ GitHub Copilot CLI zaten kurulu."
        fi
    fi

    if [ ${AI_SELECTIONS[2]} -eq 1 ]; then
        if ! command -v agy &> /dev/null; then
            echo "Antigravity CLI kuruluyor..."
            echo -e "${YELLOW}DİKKAT: Antigravity kurulum scripti indiriliyor ve çalıştırılıyor.${NC}"
            curl -fsSL https://antigravity.google/cli/install.sh | bash || record_failure "Antigravity CLI kurulumu"
        else
            echo "✓ Antigravity CLI zaten kurulu."
        fi
    fi

    if [ ${AI_SELECTIONS[3]} -eq 1 ]; then
        ensure_brew_available || exit 1
        if ! command -v opencode &> /dev/null; then
            echo "OpenCode kuruluyor..."
            brew install anomalyco/tap/opencode || record_failure "OpenCode kurulumu"
        else
            echo "✓ OpenCode zaten kurulu."
        fi
    fi
    echo -e "${GREEN}✓ Yapay Zeka Kodlama Araçları kurulumu tamamlandı.${NC}\n"
fi

# Temizlik işlemleri (Gürültülü Homebrew cleanup çıktıları elendi)
echo "Homebrew gereksiz önbellekleri temizleniyor..."
if command -v brew >/dev/null 2>&1; then
    brew cleanup 2>&1 | grep -v -i "skipping" || true
else
    echo "Homebrew bulunamadığı için cleanup atlandı."
fi

# Key repeat hızlandır (macOS Ayarları)
echo "macOS klavye hızı ayarlanıyor..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

print_failure_summary

echo -e "\n${GREEN}=======================================================${NC}"
if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    echo -e "${GREEN}        TÜM SEÇİLİ KURULUMLAR TAMAMLANDI! 🎉          ${NC}"
else
    echo -e "${YELLOW}        KURULUM TAMAMLANDI, BAZI ADIMLAR KONTROL İSTİYOR${NC}"
fi
echo -e "${GREEN}=======================================================${NC}"
echo -e "${BLUE}Yeni kurulan dillerin, path ayarlarının ve terminal ${NC}"
echo -e "${BLUE}tasarımının aktif olması için terminali kapatıp açın  ${NC}"
echo -e "${BLUE}veya 'source ~/.zshrc' komutunu çalıştırın.           ${NC}"
echo -e "${BLUE}=======================================================${NC}"
