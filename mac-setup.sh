#!/bin/bash

# ==============================================================================
# macOS Developer Environment Interactive Setup Wizard
# ==============================================================================

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Color reset
CHECK="✓"
FAILED_STEPS=()
APP_TITLE="macOS Developer Environment"
APP_SUBTITLE="Interactive Setup Wizard"
UI_WIDTH=72
MENU_LABEL_WIDTH=50
CLEAR_LINE='\033[K'

# Selected default versions
SELECTED_FLUTTER_VERSION="stable"
SELECTED_JAVA_VERSION="25-tem"
SELECTED_RUBY_VERSION="3.4.1"

# Offline / error fallback version lists
FALLBACK_FLUTTER_VERSIONS=("stable" "3.29.0" "3.27.0" "3.24.5" "3.22.3" "3.19.6")
FALLBACK_JAVA_VERSIONS=("25-tem" "23-tem" "21-tem" "17-tem" "11-tem" "21-zulu" "17-zulu")
FALLBACK_RUBY_VERSIONS=("3.4.1" "3.3.6" "3.2.6" "3.1.6")

# Installed version detection function
detect_installed_versions() {
    # Ruby version detection
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

    # Java version detection
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

    # Flutter version detection
    if command -v flutter &>/dev/null; then
        local flutter_v
        flutter_v=$(flutter --version 2>/dev/null | head -n 1 | awk '{print $2}')
        if [ -n "$flutter_v" ]; then
            SELECTED_FLUTTER_VERSION="$flutter_v"
        fi
    fi
}

# Run version detection immediately
detect_installed_versions

# Setup components
CHOICES=(
    "System Requirements (Xcode CLT & Rosetta 2)"
    "Homebrew Package Manager"
    "GUI Applications (Docker, Postman, Ollama, Zed, etc.)"
    "Core CLI Tools & Languages (Go, Ruby, Helm, k9s, CocoaPods)"
    "Ruby & Rails Development Environment (Rails gem)"
    "Java & SDKMAN Development Environment (JDK 25 Temurin)"
    "Flutter SDK & Mobile Development Environment"
    "Rust & Cargo Development Environment"
    "Node.js & Web Development Environment (NVM, Yarn, pnpm)"
    "Terminal Customization & Starship Integration"
    "AI Coding Tools (Codex, Claude Code, Copilot, Antigravity, OpenCode)"
)

# Selection states (1: selected, 0: not selected)
SELECTIONS=(1 1 1 1 1 1 1 1 1 1 1)

# GUI Applications (Casks)
APP_NAMES=("docker" "postman" "ollama" "zed" "spotify" "android-studio" "rectangle" "youtype")
APP_LABELS=("Docker" "Postman" "Ollama" "Zed Editor" "Spotify" "Android Studio" "Rectangle (Window Manager)" "YouType")
APP_SELECTIONS=(1 1 1 1 1 1 1 1) # All selected by default
APP_STATUS_LABELS=()

# Terminal Tools (Brew Formula)
TERMINAL_TOOL_NAMES=("jq" "yq" "tree" "watch" "ripgrep" "fd" "fzf" "bat" "eza" "htop" "fastfetch" "nerdfetch" "tmux" "gitleaks")
TERMINAL_TOOL_LABELS=("jq" "yq" "tree" "watch" "ripgrep (rg)" "fd" "fzf" "bat" "eza" "htop" "fastfetch" "nerdfetch" "tmux" "gitleaks")
TERMINAL_TOOL_SELECTIONS=(1 1 1 1 1 1 1 1 1 1 1 1 1 1)
TERMINAL_TOOL_STATUS_LABELS=()

# AI Coding Tools
AI_NAMES=("codex" "claude-code" "copilot-cli" "antigravity" "opencode")
AI_LABELS=("Codex CLI (OpenAI)" "Claude Code (Anthropic)" "GitHub Copilot CLI" "Antigravity CLI (Google)" "OpenCode (AnomalyCo)")
AI_SELECTIONS=(1 1 1 1 1) # All selected by default

# Themes
THEME_NAMES=("Gruvbox-dark" "Dracula" "Nord" "Solarized-Dark" "rose-pine" "Monokai" "One-Dark" "tokyo-night")
THEME_LABELS=("Gruvbox Dark" "Dracula" "Nord" "Solarized Dark" "Rosé Pine" "Monokai" "One Dark" "Tokyo Night")
THEME_SELECTIONS=(1 0 1 0 1 0 1 0) # Multiple themes can be selected
THEME_DEFAULT=2 # Nord selected by default
TERMINAL_DEFAULT_PROFILE=""

CURRENT_INDEX=0
FOCUS_SIDE="left"
TOTAL_ITEMS=13 # 11 components + 2 actions
UI_FIRST_RENDER=1

# Cursor control and cleanup
cleanup_cursor() {
    tput cnorm # Show cursor
}
trap cleanup_cursor EXIT
tput civis # Hide cursor

begin_tui_render() {
    if [ "$UI_FIRST_RENDER" -eq 1 ]; then
        clear
        UI_FIRST_RENDER=0
    else
        printf '\033[H'
    fi
}

end_tui_render() {
    printf '\033[J'
}

print_tui_line() {
    printf "%b${CLEAR_LINE}\n" "$1"
}

record_failure() {
    FAILED_STEPS+=("$1")
    echo -e "${RED}! $1 failed or completed partially.${NC}"
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

configure_clear_alias() {
    local target_file="$1"
    local tmp_file

    touch "$target_file"
    tmp_file="${target_file}.tmp.$$"

    awk '
        $0 == "# Clear command that also clears the scrollback buffer" { skip_clear_alias = 1; next }
        skip_clear_alias && $0 ~ /^alias clear=/ { skip_clear_alias = 0; next }
        { skip_clear_alias = 0; print }
    ' "$target_file" > "$tmp_file" && mv "$tmp_file" "$target_file"

    append_once "$target_file" "# mac-setup clear scrollback alias" '# mac-setup clear scrollback alias
# Clears the visible screen and scrollback without changing shell history.
alias clear='\''command clear && printf "\033[3J"'\'''
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

    echo "Installing Homebrew..."
    echo -e "${YELLOW}WARNING: Downloading and running the official Homebrew installer.${NC}"
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

    echo -e "${YELLOW}Homebrew is required for this step; it was not found and will be installed now.${NC}"
    if install_homebrew; then
        return 0
    fi

    record_failure "Homebrew installation"
    echo -e "${RED}This step cannot continue because Homebrew could not be installed.${NC}"
    return 1
}

print_failure_summary() {
    if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
        return 0
    fi

    echo -e "\n${YELLOW}WARNING: Some steps failed or completed partially:${NC}"
    for step in "${FAILED_STEPS[@]}"; do
        echo -e "${YELLOW}- $step${NC}"
    done
}

repeat_char() {
    local char="$1"
    local count="$2"
    printf "%*s" "$count" "" | tr " " "$char"
}

print_separator() {
    local color="${1:-$BLUE}"
    local char="${2:--}"
    print_tui_line "${color}$(repeat_char "$char" "$UI_WIDTH")${NC}"
}

print_centered() {
    local text="$1"
    local color="${2:-$BLUE}"
    local text_len=${#text}
    local pad=$(( (UI_WIDTH - text_len) / 2 ))

    if [ $pad -lt 0 ]; then
        pad=0
    fi

    printf "%b%*s%s%b%b\n" "$color" "$pad" "" "$text" "$NC" "$CLEAR_LINE"
}

print_header() {
    local title="$1"
    local subtitle="$2"

    print_separator "$BLUE" "="
    print_centered "$title" "$BLUE"
    if [ -n "$subtitle" ]; then
        print_centered "$subtitle" "$CYAN"
    fi
    print_separator "$BLUE" "="
}

print_help_line() {
    print_tui_line "  $1"
}

print_loading_header() {
    local message="$1"
    clear
    print_header "$APP_TITLE" "$APP_SUBTITLE"
    echo
    echo -e "  ${YELLOW}$message${NC}"
    echo
    print_separator "$BLUE" "-"
}

count_selected() {
    local sum=0
    local val
    for val in "$@"; do
        sum=$((sum + val))
    done
    echo "$sum"
}

get_app_path() {
    local cask="$1"
    local path
    local candidates=()

    case "$cask" in
        "docker") candidates=("/Applications/Docker.app" "$HOME/Applications/Docker.app") ;;
        "postman") candidates=("/Applications/Postman.app" "$HOME/Applications/Postman.app") ;;
        "ollama") candidates=("/Applications/Ollama.app" "$HOME/Applications/Ollama.app") ;;
        "zed") candidates=("/Applications/Zed.app" "$HOME/Applications/Zed.app") ;;
        "spotify") candidates=("/Applications/Spotify.app" "$HOME/Applications/Spotify.app") ;;
        "android-studio") candidates=("/Applications/Android Studio.app" "$HOME/Applications/Android Studio.app") ;;
        "rectangle") candidates=("/Applications/Rectangle.app" "$HOME/Applications/Rectangle.app") ;;
        "youtype") candidates=("/Applications/YouType.app" "$HOME/Applications/YouType.app") ;;
    esac

    for path in "${candidates[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

app_command_for_cask() {
    local cask="$1"

    case "$cask" in
        "docker") echo "docker" ;;
        "postman") echo "postman" ;;
        "ollama") echo "ollama" ;;
        "zed") echo "zed" ;;
        "android-studio") echo "studio" ;;
        "rectangle") echo "rectangle" ;;
        "youtype") echo "YouType" ;;
        *) return 1 ;;
    esac
}

read_app_version() {
    local app_path="$1"
    local version

    version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app_path/Contents/Info.plist" 2>/dev/null)
    if [ -z "$version" ]; then
        version=$(defaults read "$app_path/Contents/Info" CFBundleShortVersionString 2>/dev/null)
    fi
    if [ -z "$version" ]; then
        version=$(mdls -raw -name kMDItemVersion "$app_path" 2>/dev/null)
        if [ "$version" = "(null)" ]; then
            version=""
        fi
    fi

    echo "$version"
}

app_installed_version() {
    local cask="$1"
    local app_path
    local command_name
    local version

    if app_path=$(get_app_path "$cask"); then
        read_app_version "$app_path"
        return 0
    fi

    if brew list --cask "$cask" >/dev/null 2>&1; then
        version=$(brew list --cask --versions "$cask" 2>/dev/null | awk '{print $2}')
        echo "$version"
        return 0
    fi

    if command_name=$(app_command_for_cask "$cask") && command -v "$command_name" >/dev/null 2>&1; then
        version=$("$command_name" --version 2>/dev/null | head -n 1)
        echo "$version"
        return 0
    fi

    return 1
}

app_status_label() {
    local cask="$1"
    local selected="${2:-1}"
    local version

    if version=$(app_installed_version "$cask"); then
        if [ -n "$version" ]; then
            echo "v$version"
        else
            echo "Installed"
        fi
    elif [ "$selected" -eq 1 ]; then
        echo "Selected"
    else
        echo "Could not verify"
    fi
}

refresh_app_status_cache() {
    local i

    APP_STATUS_LABELS=()
    for i in "${!APP_NAMES[@]}"; do
        APP_STATUS_LABELS[$i]=$(app_status_label "${APP_NAMES[$i]}" "${APP_SELECTIONS[$i]}")
    done
}

terminal_tool_status_label() {
    local tool="$1"

    if command -v "$tool" >/dev/null 2>&1 || brew list --formula "$tool" >/dev/null 2>&1; then
        echo " ${GREEN}(Installed)${NC}"
    else
        echo ""
    fi
}

refresh_terminal_tool_status_cache() {
    local i

    TERMINAL_TOOL_STATUS_LABELS=()
    for i in "${!TERMINAL_TOOL_NAMES[@]}"; do
        TERMINAL_TOOL_STATUS_LABELS[$i]=$(terminal_tool_status_label "${TERMINAL_TOOL_NAMES[$i]}")
    done
}

truncate_text() {
    local text="$1"
    local max_len="$2"

    if [ ${#text} -gt "$max_len" ]; then
        printf "%s..." "${text:0:$((max_len - 3))}"
    else
        printf "%s" "$text"
    fi
}

terminal_profile_exists() {
    local profile_name="$1"
    osascript -e "tell application \"Terminal\" to exists settings set \"$profile_name\"" 2>/dev/null | grep -q "true"
}

terminal_profile_installed() {
    local profile_name="$1"
    /usr/libexec/PlistBuddy -c "Print :'Window Settings':$profile_name:name" "$HOME/Library/Preferences/com.apple.Terminal.plist" >/dev/null 2>&1
}

theme_index_for_profile() {
    local profile_name="$1"
    local i

    case "$profile_name" in
        "Solarized Dark"|"Solarized Dark ansi") profile_name="Solarized-Dark" ;;
        "One Dark") profile_name="One-Dark" ;;
        "tk2") profile_name="tokyo-night" ;;
    esac

    for i in "${!THEME_NAMES[@]}"; do
        if [ "${THEME_NAMES[$i]}" = "$profile_name" ]; then
            echo "$i"
            return 0
        fi
    done

    return 1
}

set_theme_default() {
    local idx="$1"

    THEME_DEFAULT=$idx
    THEME_SELECTIONS[$idx]=1
    TERMINAL_DEFAULT_PROFILE="${THEME_NAMES[$idx]}"
}

selected_theme_count() {
    local sum=0
    local val

    for val in "${THEME_SELECTIONS[@]}"; do
        sum=$((sum + val))
    done

    echo "$sum"
}

set_first_selected_theme_as_default() {
    local i

    for i in "${!THEME_NAMES[@]}"; do
        if [ ${THEME_SELECTIONS[$i]} -eq 1 ]; then
            set_theme_default "$i"
            return 0
        fi
    done

    return 1
}

sync_theme_state_from_terminal() {
    local installed_count=0
    local default_profile
    local default_idx
    local i

    for i in "${!THEME_NAMES[@]}"; do
        if terminal_profile_installed "${THEME_NAMES[$i]}"; then
            THEME_SELECTIONS[$i]=1
            installed_count=$((installed_count + 1))
        else
            THEME_SELECTIONS[$i]=0
        fi
    done

    if [ $installed_count -eq 0 ]; then
        THEME_SELECTIONS=(1 0 1 0 1 0 1 0)
    fi

    default_profile=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || true)
    if default_idx=$(theme_index_for_profile "$default_profile"); then
        set_theme_default "$default_idx"
    else
        set_first_selected_theme_as_default
    fi
}

read_terminal_profile_name() {
    local theme_path="$1"
    local fallback_name="$2"
    local profile_name

    profile_name=$(/usr/libexec/PlistBuddy -c "Print :name" "$theme_path" 2>/dev/null)
    if [ -z "$profile_name" ]; then
        profile_name=$(defaults read "$theme_path" name 2>/dev/null)
    fi

    if [ -n "$profile_name" ]; then
        echo "$profile_name"
    else
        echo "$fallback_name"
    fi
}

set_terminal_profile_file_name() {
    local theme_path="$1"
    local profile_name="$2"

    if /usr/libexec/PlistBuddy -c "Set :name $profile_name" "$theme_path" 2>/dev/null; then
        return 0
    fi

    /usr/libexec/PlistBuddy -c "Add :name string $profile_name" "$theme_path" 2>/dev/null
}

download_theme_file() {
    local theme_path="$1"
    local theme_name="$2"
    shift 2

    local tmp_path="${theme_path}.tmp"
    local theme_url
    for theme_url in "$@"; do
        if [ -z "$theme_url" ]; then
            continue
        fi

        echo "[$theme_name] terminal color profile is downloading..."
        if curl -fL --retry 2 --connect-timeout 10 "$theme_url" -o "$tmp_path"; then
            mv "$tmp_path" "$theme_path"
            return 0
        fi
    done

    rm -f "$tmp_path"
    return 1
}

import_terminal_profile() {
    local theme_path="$1"
    local profile_name="$2"

    if ! terminal_profile_exists "$profile_name"; then
        open -a Terminal "$theme_path"
        for _ in {1..20}; do
            sleep 0.5
            if terminal_profile_exists "$profile_name"; then
                return 0
            fi
        done
        return 1
    fi

    return 0
}

set_terminal_default_profile() {
    local profile_name="$1"

    defaults write com.apple.Terminal "Default Window Settings" -string "$profile_name"
    defaults write com.apple.Terminal "Startup Window Settings" -string "$profile_name"
    osascript \
        -e "tell application \"Terminal\" to set default settings to settings set \"$profile_name\"" \
        -e "tell application \"Terminal\" to set startup settings to settings set \"$profile_name\"" \
        2>/dev/null || true
}

starship_palette_name_for_theme() {
    local profile_name="$1"

    case "$profile_name" in
        "Gruvbox-dark") echo "gruvbox_dark" ;;
        "Dracula") echo "dracula" ;;
        "Nord") echo "nord" ;;
        "Solarized-Dark"|"Solarized Dark"|"Solarized Dark ansi") echo "solarized_dark" ;;
        "rose-pine") echo "rose_pine" ;;
        "Monokai") echo "monokai" ;;
        "One-Dark"|"One Dark") echo "one_dark" ;;
        "tokyo-night") echo "tokyo_night" ;;
        *) echo "gruvbox_dark" ;;
    esac
}

print_starship_palette_toml() {
    local palette_name="$1"

    case "$palette_name" in
        monokai)
            cat <<'EOF'
[palettes.monokai]
color_fg0 = '#f8f8f2'
color_bg1 = '#3e3d32'
color_bg3 = '#75715e'
color_blue = '#66d9ef'
color_aqua = '#a1efe4'
color_green = '#a6e22e'
color_orange = '#fd971f'
color_purple = '#ae81ff'
color_red = '#f92672'
color_yellow = '#e6db74'
EOF
            ;;
        one_dark)
            cat <<'EOF'
[palettes.one_dark]
color_fg0 = '#abb2bf'
color_bg1 = '#282c34'
color_bg3 = '#3e4451'
color_blue = '#61afef'
color_aqua = '#56b6c2'
color_green = '#98c379'
color_orange = '#d19a66'
color_purple = '#c678dd'
color_red = '#e06c75'
color_yellow = '#e5c07b'
EOF
            ;;
        tokyo_night)
            cat <<'EOF'
[palettes.tokyo_night]
color_fg0 = '#c0caf5'
color_bg1 = '#1a1b26'
color_bg3 = '#414868'
color_blue = '#7aa2f7'
color_aqua = '#7dcfff'
color_green = '#9ece6a'
color_orange = '#ff9e64'
color_purple = '#bb9af7'
color_red = '#f7768e'
color_yellow = '#e0af68'
EOF
            ;;
        solarized_dark)
            cat <<'EOF'
[palettes.solarized_dark]
color_fg0 = '#eee8d5'
color_bg1 = '#073642'
color_bg3 = '#586e75'
color_blue = '#268bd2'
color_aqua = '#2aa198'
color_green = '#859900'
color_orange = '#cb4b16'
color_purple = '#6c71c4'
color_red = '#dc322f'
color_yellow = '#b58900'
EOF
            ;;
        dracula)
            cat <<'EOF'
[palettes.dracula]
color_fg0 = '#f8f8f2'
color_bg1 = '#282a36'
color_bg3 = '#44475a'
color_blue = '#6272a4'
color_aqua = '#8be9fd'
color_green = '#50fa7b'
color_orange = '#ffb86c'
color_purple = '#bd93f9'
color_red = '#ff5555'
color_yellow = '#f1fa8c'
EOF
            ;;
        nord)
            cat <<'EOF'
[palettes.nord]
color_fg0 = '#eceff4'
color_bg1 = '#2e3440'
color_bg3 = '#4c566a'
color_blue = '#5e81ac'
color_aqua = '#88c0d0'
color_green = '#a3be8c'
color_orange = '#d08770'
color_purple = '#b48ead'
color_red = '#bf616a'
color_yellow = '#ebcb8b'
EOF
            ;;
        rose_pine)
            cat <<'EOF'
[palettes.rose_pine]
color_fg0 = '#e0def4'
color_bg1 = '#191724'
color_bg3 = '#26233a'
color_blue = '#31748f'
color_aqua = '#9ccfd8'
color_green = '#31748f'
color_orange = '#f6c177'
color_purple = '#c4a7e7'
color_red = '#eb6f92'
color_yellow = '#f6c177'
EOF
            ;;
        *)
            cat <<'EOF'
[palettes.gruvbox_dark]
color_fg0 = '#fbf1c7'
color_bg1 = '#3c3836'
color_bg3 = '#665c54'
color_blue = '#458588'
color_aqua = '#689d6a'
color_green = '#98971a'
color_orange = '#d65d0e'
color_purple = '#b16286'
color_red = '#cc241d'
color_yellow = '#d79921'
EOF
            ;;
    esac
}

improve_starship_prompt_contrast() {
    local config_path="$1"

    [ -f "$config_path" ] || return 0

    sed -i '' \
        -e 's/style = "bg:color_orange fg:color_fg0"/style = "bg:color_orange fg:color_bg1"/' \
        -e 's/style_user = "bg:color_orange fg:color_fg0"/style_user = "bg:color_orange fg:color_bg1"/' \
        -e 's/style_root = "bg:color_orange fg:color_fg0"/style_root = "bg:color_orange fg:color_bg1"/' \
        -e 's/style = "fg:color_fg0 bg:color_yellow"/style = "fg:color_bg1 bg:color_yellow"/' \
        "$config_path"
}

update_starship_palette() {
    local config_path="$1"
    local profile_name="$2"
    local palette_name
    local tmp_path

    palette_name=$(starship_palette_name_for_theme "$profile_name")
    tmp_path="${config_path}.tmp"

    if ! grep -q "color_orange" "$config_path" 2>/dev/null || ! grep -q "^\[palettes\\." "$config_path" 2>/dev/null; then
        echo "✓ Existing starship.toml looks customized; color palette was not changed."
        return 0
    fi

    awk -v palette_name="$palette_name" '
        BEGIN { skip_palette = 0 }
        /^palette = / {
            print "palette = '\''" palette_name "'\''"
            next
        }
        /^\[palettes\./ {
            skip_palette = 1
            next
        }
        /^\[[^]]+\]/ {
            skip_palette = 0
        }
        !skip_palette {
            print
        }
    ' "$config_path" > "$tmp_path" || return 1

    printf "\n" >> "$tmp_path"
    print_starship_palette_toml "$palette_name" >> "$tmp_path"
    mv "$tmp_path" "$config_path"
    improve_starship_prompt_contrast "$config_path"
    echo "✓ Starship color palette '$palette_name' updated."
}

apply_terminal_profile_font() {
    local profile_name="$1"
    local font_applied=false
    local f_name

    local target_fonts=("JetBrainsMono NFM" "JetBrainsMonoNL NFM" "JetBrainsMonoNF-Regular" "JetBrainsMonoNFM-Regular" "JetBrainsMono Nerd Font" "JetBrainsMonoNerdFont-Regular" "JetBrainsMonoNF")
    for f_name in "${target_fonts[@]}"; do
        osascript -e "tell application \"Terminal\" to set font name of settings set \"$profile_name\" to \"$f_name\"" 2>/dev/null || true
        local applied_font
        applied_font=$(osascript -e "tell application \"Terminal\" to get font name of settings set \"$profile_name\"" 2>/dev/null || true)
        if [[ "$applied_font" == *"NF"* ]] || [[ "$applied_font" == *"Nerd"* ]]; then
            font_applied=true
            break
        fi
    done

    if [ "$font_applied" = false ]; then
        osascript -e "tell application \"Terminal\" to set font name of settings set \"$profile_name\" to \"JetBrains Mono\"" 2>/dev/null || true
        local applied_font
        applied_font=$(osascript -e "tell application \"Terminal\" to get font name of settings set \"$profile_name\"" 2>/dev/null || true)
        if [[ "$applied_font" == *"JetBrains"* ]]; then
            font_applied=true
        fi
    fi
    osascript -e "tell application \"Terminal\" to set font size of settings set \"$profile_name\" to 16" 2>/dev/null || true

    [ "$font_applied" = true ]
}

# Version fetch functions
fetch_flutter_versions() {
    # Query tags with git ls-remote using a strict 2-second timeout.
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

    # Watchdog process
    (
        sleep 2
        if kill -0 "$git_pid" 2>/dev/null; then
            kill -9 "$git_pid" 2>/dev/null
        fi
    ) &
    local watchdog_pid=$!

    # Wait for the Git process to finish
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
    # JDK LTS and popular current versions (instant and reliable)
    for v in "${FALLBACK_JAVA_VERSIONS[@]}"; do
        echo "$v"
    done
}

fetch_ruby_versions() {
    # Stable and popular Ruby versions (instant and reliable)
    for v in "${FALLBACK_RUBY_VERSIONS[@]}"; do
        echo "$v"
    done
}

read_keypress() {
    local key
    if [ -n "$ZSH_VERSION" ]; then
        if ! read -r -s -k 1 key; then
            echo "QUIT"
            return 0
        fi
    else
        if ! read -r -s -n 1 key; then
            echo "QUIT"
            return 0
        fi
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

# Keyboard-navigable version submenu
show_version_submenu() {
    local title="$1"
    local current_val="$2"
    shift 2
    local options=("$@")
    local total=${#options[@]}
    local selected_idx=0

    # Find the current value and place the cursor there
    for i in "${!options[@]}"; do
        if [[ "${options[$i]}" == "$current_val" ]]; then
            selected_idx=$i
            break
        fi
    done

    while true; do
        begin_tui_render >&2
        print_header "$title Version Selection" "Select with ENTER / SPACE" >&2
        print_help_line "${YELLOW}↑/↓${NC} navigate  ${GREEN}ENTER/SPACE${NC} select  ${YELLOW}←/q${NC} back" >&2
        print_separator "$BLUE" "-" >&2

        for i in "${!options[@]}"; do
            local marker=" "
            if [[ "${options[$i]}" == "$current_val" ]]; then
                marker="${GREEN}${CHECK}${NC}"
            fi

            if [ $selected_idx -eq $i ]; then
                print_tui_line "${CYAN}➔ [${marker}] ${options[$i]}${NC}" >&2
            else
                print_tui_line "   [${marker}] ${options[$i]}" >&2
            fi
        done

        print_separator "$BLUE" "-" >&2
        end_tui_render >&2

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
    local total=$((${#AI_NAMES[@]} + 1)) # tools + 1 "Save and Go Back"
    local save_idx=${#AI_NAMES[@]}

    while true; do
        begin_tui_render >&2
        print_header "AI Coding Tools" "Tool selection" >&2
        print_help_line "${YELLOW}↑/↓${NC} navigate  ${GREEN}ENTER/SPACE${NC} select/deselect  ${YELLOW}←/q${NC} back" >&2
        print_separator "$BLUE" "-" >&2

        for i in "${!AI_NAMES[@]}"; do
            local marker=" "
            if [ ${AI_SELECTIONS[$i]} -eq 1 ]; then
                marker="${GREEN}${CHECK}${NC}"
            fi

            if [ $selected_idx -eq $i ]; then
                print_tui_line "${CYAN}➔ [${marker}] ${AI_LABELS[$i]}${NC}" >&2
            else
                print_tui_line "   [${marker}] ${AI_LABELS[$i]}" >&2
            fi
        done

        print_separator "$BLUE" "-" >&2
        if [ $selected_idx -eq $save_idx ]; then
            print_tui_line "${CYAN}➔ ${GREEN}[ Save and Go Back ]${NC}" >&2
        else
            print_tui_line "   ${GREEN}[ Save and Go Back ]${NC}" >&2
        fi
        print_separator "$BLUE" "-" >&2
        end_tui_render >&2

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
    local total=$((${#APP_NAMES[@]} + 1))
    local save_idx=${#APP_NAMES[@]}

    print_loading_header "Checking application status..."
    refresh_app_status_cache

    while true; do
        begin_tui_render >&2
        print_header "GUI Applications" "Cask selection" >&2
        print_help_line "${YELLOW}↑/↓${NC} navigate  ${GREEN}ENTER/SPACE${NC} select/deselect  ${YELLOW}←/q${NC} back" >&2
        print_separator "$BLUE" "-" >&2

        for i in "${!APP_NAMES[@]}"; do
            local marker=" "
            local status
            local row_label
            if [ ${APP_SELECTIONS[$i]} -eq 1 ]; then
                marker="${GREEN}${CHECK}${NC}"
            fi

            status="${APP_STATUS_LABELS[$i]}"
            row_label="${APP_LABELS[$i]} - Status: $status"

            if [ $selected_idx -eq $i ]; then
                print_tui_line "${CYAN}➔ [${marker}] ${row_label}${NC}" >&2
            else
                print_tui_line "   [${marker}] ${row_label}" >&2
            fi
        done

        print_separator "$BLUE" "-" >&2
        if [ $selected_idx -eq $save_idx ]; then
            print_tui_line "${CYAN}➔ ${GREEN}[ Save and Go Back ]${NC}" >&2
        else
            print_tui_line "   ${GREEN}[ Save and Go Back ]${NC}" >&2
        fi
        print_separator "$BLUE" "-" >&2
        end_tui_render >&2

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
                    APP_SELECTIONS[$selected_idx]=$(( 1 - APP_SELECTIONS[$selected_idx] ))
                    APP_STATUS_LABELS[$selected_idx]=$(app_status_label "${APP_NAMES[$selected_idx]}" "${APP_SELECTIONS[$selected_idx]}")
                fi
                ;;
            "LEFT"|"QUIT")
                return 0
                ;;
        esac
    done
}

show_terminal_tools_submenu() {
    local selected_idx=0
    local total=$((${#TERMINAL_TOOL_NAMES[@]} + 1))
    local save_idx=${#TERMINAL_TOOL_NAMES[@]}

    print_loading_header "Checking terminal tool status..."
    refresh_terminal_tool_status_cache

    while true; do
        begin_tui_render >&2
        print_header "Terminal Tools" "Brew formula selection" >&2
        print_help_line "${YELLOW}↑/↓${NC} navigate  ${GREEN}ENTER/SPACE${NC} select/deselect  ${YELLOW}←/q${NC} back" >&2
        print_separator "$BLUE" "-" >&2

        for i in "${!TERMINAL_TOOL_NAMES[@]}"; do
            local marker=" "
            local installed_str="${TERMINAL_TOOL_STATUS_LABELS[$i]}"

            if [ ${TERMINAL_TOOL_SELECTIONS[$i]} -eq 1 ]; then
                marker="${GREEN}${CHECK}${NC}"
            fi

            if [ $selected_idx -eq $i ]; then
                print_tui_line "${CYAN}➔ [${marker}] ${TERMINAL_TOOL_LABELS[$i]}${installed_str}${NC}" >&2
            else
                print_tui_line "   [${marker}] ${TERMINAL_TOOL_LABELS[$i]}${installed_str}" >&2
            fi
        done

        print_separator "$BLUE" "-" >&2
        if [ $selected_idx -eq $save_idx ]; then
            print_tui_line "${CYAN}➔ ${GREEN}[ Save and Go Back ]${NC}" >&2
        else
            print_tui_line "   ${GREEN}[ Save and Go Back ]${NC}" >&2
        fi
        print_separator "$BLUE" "-" >&2
        end_tui_render >&2

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
                    TERMINAL_TOOL_SELECTIONS[$selected_idx]=$(( 1 - TERMINAL_TOOL_SELECTIONS[$selected_idx] ))
                fi
                ;;
            "LEFT"|"QUIT")
                return 0
                ;;
        esac
    done
}

show_theme_submenu() {
    local selected_idx=$THEME_DEFAULT
    local num_themes=${#THEME_NAMES[@]}
    local total=$((num_themes + 1)) # themes + 1 "Save and Go Back"

    while true; do
        local subtitle="Default: ${THEME_LABELS[$THEME_DEFAULT]}"

        begin_tui_render >&2
        print_header "Terminal Theme Selection" "$subtitle" >&2
        print_help_line "${YELLOW}↑/↓${NC} navigate  ${GREEN}ENTER/SPACE${NC} install/skip  ${PURPLE}v${NC} default" >&2
        print_separator "$BLUE" "-" >&2

        for i in "${!THEME_NAMES[@]}"; do
            local marker=" "
            if [ ${THEME_SELECTIONS[$i]} -eq 1 ]; then
                marker="${GREEN}${CHECK}${NC}"
            fi

            local default_str=""
            if [ $THEME_DEFAULT -eq $i ]; then
                default_str=" ${PURPLE}(Default)${NC}"
            fi

            local installed_str=""
            if terminal_profile_installed "${THEME_NAMES[$i]}"; then
                installed_str=" ${GREEN}(Installed)${NC}"
            fi

            if [ $selected_idx -eq $i ]; then
                print_tui_line "${CYAN}➔ [${marker}] ${THEME_LABELS[$i]}${installed_str}${default_str}${NC}" >&2
            else
                print_tui_line "   [${marker}] ${THEME_LABELS[$i]}${installed_str}${default_str}" >&2
            fi
        done

        print_separator "$BLUE" "-" >&2
        if [ $selected_idx -eq $num_themes ]; then
            print_tui_line "${CYAN}➔ ${GREEN}[ Save and Go Back ]${NC}" >&2
        else
            print_tui_line "   ${GREEN}[ Save and Go Back ]${NC}" >&2
        fi
        print_separator "$BLUE" "-" >&2
        end_tui_render >&2

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
                    local theme_sum
                    theme_sum=$(selected_theme_count)
                    if [ $theme_sum -eq 0 ]; then
                        echo -e "\n${RED}ERROR: You must select at least one theme!${NC}" >&2
                        sleep 1.5
                        continue
                    fi
                    return 0
                else
                    if [ ${THEME_SELECTIONS[$selected_idx]} -eq 1 ]; then
                        if [ $selected_idx -eq $THEME_DEFAULT ] && [ "$(selected_theme_count)" -eq 1 ]; then
                            echo -e "\n${RED}ERROR: The last default theme cannot be removed.${NC}" >&2
                            sleep 1.5
                            continue
                        fi

                        THEME_SELECTIONS[$selected_idx]=0
                        if [ $THEME_DEFAULT -eq $selected_idx ]; then
                            set_first_selected_theme_as_default
                        fi
                    else
                        THEME_SELECTIONS[$selected_idx]=1
                    fi
                fi
                ;;
            "DEFAULT")
                if [ $selected_idx -ge 0 ] && [ $selected_idx -lt $num_themes ]; then
                    set_theme_default "$selected_idx"
                fi
                ;;
            "LEFT"|"QUIT")
                local theme_sum
                theme_sum=$(selected_theme_count)
                if [ $theme_sum -eq 0 ]; then
                    echo -e "\n${RED}ERROR: You must select at least one theme!${NC}" >&2
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

render_menu_row() {
    local idx="$1"
    local label="$2"
    local button="$3"
    local check=" "
    local prefix="   "
    local clean_label="$label"
    local padded_label
    local label_width="$MENU_LABEL_WIDTH"

    if [ -z "$button" ]; then
        label_width=$((UI_WIDTH - 8))
    fi

    if [ ${SELECTIONS[$idx]} -eq 1 ]; then
        check="${GREEN}${CHECK}${NC}"
    fi

    clean_label=$(truncate_text "$clean_label" "$label_width")
    padded_label=$(printf "%-${label_width}s" "$clean_label")

    if [ $CURRENT_INDEX -eq $idx ] && [ "$FOCUS_SIDE" = "left" ]; then
        prefix="${CYAN}➔${NC} "
        print_tui_line "${prefix}[${check}] ${CYAN}${padded_label}${NC}${button}"
    else
        print_tui_line "${prefix}[${check}] ${padded_label}${button}"
    fi
}

menu_button() {
    local idx="$1"
    local text="$2"

    if [ $CURRENT_INDEX -eq $idx ] && [ "$FOCUS_SIDE" = "right" ]; then
        echo " ${YELLOW}➔ [$text]${NC}"
    else
        echo "   ${CYAN}[$text]${NC}"
    fi
}

render_menu() {
    begin_tui_render
    local selected_components
    selected_components=$(count_selected "${SELECTIONS[@]}")

    print_header "$APP_TITLE" "$APP_SUBTITLE"
    print_help_line "Selected components: ${GREEN}$selected_components/${#CHOICES[@]}${NC}"
    print_help_line "${YELLOW}↑/↓${NC} navigate  ${GREEN}ENTER/SPACE${NC} select  ${YELLOW}→${NC} details  ${YELLOW}a${NC} all  ${RED}q${NC} quit"
    print_separator "$BLUE" "-"

    # Component list (0-10)
    for i in {0..10}; do
        local label="${CHOICES[$i]}"
        local version_btn=""

        if [ $i -eq 2 ]; then
            local selected_count
            selected_count=$(count_selected "${APP_SELECTIONS[@]}")
            local total_apps=${#APP_NAMES[@]}
            label="GUI Applications ($selected_count/$total_apps)"
            version_btn=$(menu_button "$i" "Choose Apps")
        elif [ $i -eq 3 ]; then
            local selected_count
            selected_count=$(count_selected "${TERMINAL_TOOL_SELECTIONS[@]}")
            local total_tools=${#TERMINAL_TOOL_NAMES[@]}
            label="Core CLI & Terminal Tools ($selected_count/$total_tools)"
            version_btn=$(menu_button "$i" "Choose Tools")
        elif [ $i -eq 4 ]; then
            label="Ruby & Rails (v$SELECTED_RUBY_VERSION)"
            version_btn=$(menu_button "$i" "Choose Version")
        elif [ $i -eq 5 ]; then
            label="Java & SDKMAN (v$SELECTED_JAVA_VERSION)"
            version_btn=$(menu_button "$i" "Choose Version")
        elif [ $i -eq 6 ]; then
            label="Flutter SDK (v$SELECTED_FLUTTER_VERSION)"
            version_btn=$(menu_button "$i" "Choose Version")
        elif [ $i -eq 9 ]; then
            local default_theme="${THEME_LABELS[$THEME_DEFAULT]}"
            if [ -n "$TERMINAL_DEFAULT_PROFILE" ] && ! theme_index_for_profile "$TERMINAL_DEFAULT_PROFILE" >/dev/null; then
                default_theme="$TERMINAL_DEFAULT_PROFILE"
            fi
            label="Terminal & Starship ($default_theme)"
            version_btn=$(menu_button "$i" "Choose Theme")
        elif [ $i -eq 10 ]; then
            local selected_count
            selected_count=$(count_selected "${AI_SELECTIONS[@]}")
            local total_ai=${#AI_NAMES[@]}
            label="AI Coding Tools ($selected_count/$total_ai)"
            version_btn=$(menu_button "$i" "Choose Tools")
        fi

        render_menu_row "$i" "$label" "$version_btn"
    done

    print_separator "$BLUE" "-"

    # Actions (11-12)
    if [ $CURRENT_INDEX -eq 11 ]; then
        print_tui_line "${CYAN}➔ ${GREEN}[ Start Setup ]${NC}"
    else
        print_tui_line "   ${GREEN}[ Start Setup ]${NC}"
    fi

    if [ $CURRENT_INDEX -eq 12 ]; then
        print_tui_line "${CYAN}➔ ${RED}[ Cancel and Exit ]${NC}"
    else
        print_tui_line "   ${RED}[ Cancel and Exit ]${NC}"
    fi

    print_separator "$BLUE" "-"
    end_tui_render
}

# Interactive loop
sync_theme_state_from_terminal
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
            if [ $CURRENT_INDEX -eq 2 ] || [ $CURRENT_INDEX -eq 3 ] || [ $CURRENT_INDEX -eq 4 ] || [ $CURRENT_INDEX -eq 5 ] || [ $CURRENT_INDEX -eq 6 ] || [ $CURRENT_INDEX -eq 9 ] || [ $CURRENT_INDEX -eq 10 ]; then
                FOCUS_SIDE="right"
            fi
            ;;
        "LEFT")
            if [ $CURRENT_INDEX -eq 2 ] || [ $CURRENT_INDEX -eq 3 ] || [ $CURRENT_INDEX -eq 4 ] || [ $CURRENT_INDEX -eq 5 ] || [ $CURRENT_INDEX -eq 6 ] || [ $CURRENT_INDEX -eq 9 ] || [ $CURRENT_INDEX -eq 10 ]; then
                FOCUS_SIDE="left"
            fi
            ;;
        "ENTER")
            if [ $CURRENT_INDEX -eq 11 ]; then
                # Continue with ENTER when Start Setup is triggered
                if [ ${SELECTIONS[9]} -eq 1 ]; then
                    theme_sum=0
                    for val in "${THEME_SELECTIONS[@]}"; do
                        theme_sum=$((theme_sum + val))
                    done
                    if [ $theme_sum -eq 0 ]; then
                        echo -e "\n${RED}ERROR: You must select at least one theme while terminal customization is enabled!${NC}"
                        sleep 2
                        continue
                    fi
                fi
                break
            elif [ $CURRENT_INDEX -eq 12 ]; then
                # Cancel and Exit
                echo -e "\n${RED}Setup canceled. Exiting...${NC}"
                tput cnorm
                exit 0
            elif [ $CURRENT_INDEX -eq 2 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # App submenu
                show_app_submenu
                SELECTIONS[2]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 3 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Terminal Tools submenu
                show_terminal_tools_submenu
                SELECTIONS[3]=1
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 4 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Ruby version submenu
                print_loading_header "Listing installable Ruby versions..."

                ruby_vers=("${FALLBACK_RUBY_VERSIONS[@]}")
                result=$(show_version_submenu "Ruby" "$SELECTED_RUBY_VERSION" "${ruby_vers[@]}")
                SELECTED_RUBY_VERSION="$result"
                SELECTIONS[4]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 5 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Java version submenu
                print_loading_header "Listing installable Java (JDK) versions..."

                java_vers=("${FALLBACK_JAVA_VERSIONS[@]}")
                result=$(show_version_submenu "Java" "$SELECTED_JAVA_VERSION" "${java_vers[@]}")
                SELECTED_JAVA_VERSION="$result"
                SELECTIONS[5]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 6 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Flutter version submenu
                print_loading_header "Querying stable Flutter versions from the official Git repository..."

                flutter_vers=()
                while IFS= read -r line; do
                    flutter_vers+=("$line")
                done <<< "$(fetch_flutter_versions)"

                result=$(show_version_submenu "Flutter" "$SELECTED_FLUTTER_VERSION" "${flutter_vers[@]}")
                SELECTED_FLUTTER_VERSION="$result"
                SELECTIONS[6]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 9 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Terminal theme submenu
                show_theme_submenu
                SELECTIONS[9]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 10 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # AI tools submenu
                show_ai_submenu
                SELECTIONS[10]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            else
                # Components without a version menu can also be selected with ENTER
                if [ $CURRENT_INDEX -ge 0 ] && [ $CURRENT_INDEX -le 10 ]; then
                    SELECTIONS[$CURRENT_INDEX]=$(( 1 - SELECTIONS[$CURRENT_INDEX] ))
                fi
            fi
            ;;
        "SPACE")
            if [ $CURRENT_INDEX -eq 2 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # App submenu
                show_app_submenu
                SELECTIONS[2]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 3 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Terminal Tools submenu
                show_terminal_tools_submenu
                SELECTIONS[3]=1
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 4 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Ruby version submenu (when SPACE is pressed on the right side)
                print_loading_header "Listing installable Ruby versions..."

                ruby_vers=("${FALLBACK_RUBY_VERSIONS[@]}")
                result=$(show_version_submenu "Ruby" "$SELECTED_RUBY_VERSION" "${ruby_vers[@]}")
                SELECTED_RUBY_VERSION="$result"
                SELECTIONS[4]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 5 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Java version submenu (when SPACE is pressed on the right side)
                print_loading_header "Listing installable Java (JDK) versions..."

                java_vers=("${FALLBACK_JAVA_VERSIONS[@]}")
                result=$(show_version_submenu "Java" "$SELECTED_JAVA_VERSION" "${java_vers[@]}")
                SELECTED_JAVA_VERSION="$result"
                SELECTIONS[5]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 6 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Flutter version submenu (when SPACE is pressed on the right side)
                print_loading_header "Querying stable Flutter versions from the official Git repository..."

                flutter_vers=()
                while IFS= read -r line; do
                    flutter_vers+=("$line")
                done <<< "$(fetch_flutter_versions)"

                result=$(show_version_submenu "Flutter" "$SELECTED_FLUTTER_VERSION" "${flutter_vers[@]}")
                SELECTED_FLUTTER_VERSION="$result"
                SELECTIONS[6]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 9 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # Terminal theme submenu
                show_theme_submenu
                SELECTIONS[9]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            elif [ $CURRENT_INDEX -eq 10 ] && [ "$FOCUS_SIDE" = "right" ]; then
                # AI tools submenu
                show_ai_submenu
                SELECTIONS[10]=1 # Automatically enable after making a selection
                FOCUS_SIDE="left"
            else
                # Normal SPACE behavior on the left side
                if [ $CURRENT_INDEX -ge 0 ] && [ $CURRENT_INDEX -le 10 ]; then
                    SELECTIONS[$CURRENT_INDEX]=$(( 1 - SELECTIONS[$CURRENT_INDEX] ))
                fi
            fi
            ;;
        "ALL")
            toggle_all
            ;;
        "QUIT")
            echo -e "\n${RED}Setup canceled. Exiting...${NC}"
            tput cnorm
            exit 0
            ;;
    esac
done

tput cnorm # Restore cursor before setup starts
clear
print_header "$APP_TITLE" "Setup Starting"
echo -e "  ${GREEN}Selections received. Running selected steps.${NC}\n"

# 1. System requirements
if [ ${SELECTIONS[0]} -eq 1 ]; then
    echo -e "${YELLOW}>> Checking system requirements...${NC}"
    if ! xcode-select -p >/dev/null 2>&1; then
        xcode-select --install
        echo -e "${YELLOW}Xcode Command Line Tools installation started.${NC}"
        echo -e "${YELLOW}Run the script again after installation completes.${NC}"
        exit 1
    fi

    if /usr/bin/pgrep oahd >/dev/null 2>&1; then
        echo "Rosetta 2 is already installed."
    else
        sudo softwareupdate --install-rosetta --agree-to-license
    fi
    echo -e "${GREEN}✓ System requirements completed.${NC}\n"
fi

# 2. Homebrew Installation
if [ ${SELECTIONS[1]} -eq 1 ]; then
    echo -e "${YELLOW}>> Checking Homebrew package manager...${NC}"
    load_brew_shellenv
    if ! command -v brew &> /dev/null; then
        if ! install_homebrew; then
            record_failure "Homebrew installation"
            echo -e "${RED}Steps requiring Homebrew cannot run because Homebrew could not be installed.${NC}"
            exit 1
        fi
    else
        brew update || record_failure "Homebrew update"
    fi
    echo -e "${GREEN}✓ Homebrew completed.${NC}\n"
fi

# 3. Cask installation
if [ ${SELECTIONS[2]} -eq 1 ]; then
    echo -e "${YELLOW}>> Installing selected GUI applications (casks)...${NC}"
    ensure_brew_available || exit 1

    casks_to_install=()
    for i in "${!APP_NAMES[@]}"; do
        if [ ${APP_SELECTIONS[$i]} -eq 1 ]; then
            cask="${APP_NAMES[$i]}"
            label="${APP_LABELS[$i]}"
            version=""

            if version=$(app_installed_version "$cask"); then
                if [ -n "$version" ]; then
                    echo -e "${GREEN}✓ $label is already installed (Version: v$version).${NC}"
                else
                    echo -e "${GREEN}✓ $label is already installed.${NC}"
                fi
            else
                echo -e "${YELLOW}- $label could not be auto-verified; Homebrew cask installation will be checked.${NC}"
                casks_to_install+=("$cask")
            fi
        fi
    done

    if [ ${#casks_to_install[@]} -gt 0 ]; then
        echo "Applications to install: ${casks_to_install[*]}"
        for cask in "${casks_to_install[@]}"; do
            if [ "$cask" = "youtype" ]; then
                if brew install --cask youtype; then
                    youtype_path=""
                    youtype_path=$(get_app_path "youtype" || true)
                    if [ -n "$youtype_path" ]; then
                        xattr -dr com.apple.quarantine "$youtype_path" 2>/dev/null || true
                    fi
                else
                    record_failure "YouType installation"
                fi
            else
                brew install --cask "$cask" || record_failure "$cask installation"
            fi
        done
        echo -e "${GREEN}✓ Selected application installations processed.${NC}\n"

        # Reset Launchpad to force newly installed casks to show up in App Drawer immediately
        echo "Refreshing Launchpad so installed applications appear immediately..."
        defaults write com.apple.dock ResetLaunchPad -bool true && killall Dock 2>/dev/null || true
    else
        echo -e "${GREEN}✓ All selected applications are already installed; no new installation was performed.${NC}\n"
    fi
fi

# 4. Core CLI and languages
if [ ${SELECTIONS[3]} -eq 1 ]; then
    echo -e "${YELLOW}>> Installing CLI tools, terminal applications, Go, and Ruby...${NC}"
    ensure_brew_available || exit 1
    selected_terminal_tools=()
    for i in "${!TERMINAL_TOOL_NAMES[@]}"; do
        if [ ${TERMINAL_TOOL_SELECTIONS[$i]} -eq 1 ]; then
            selected_terminal_tools+=("${TERMINAL_TOOL_NAMES[$i]}")
        fi
    done

    brew install \
        bash git curl wget unzip zip \
        go ruby helm k9s cocoapods kubernetes-cli \
        "${selected_terminal_tools[@]}" \
        || record_failure "Core CLI tools"
    brew link --overwrite kubernetes-cli 2>/dev/null || true

    if [ -d "/Applications/Xcode.app" ]; then
        echo "Full Xcode installation found; configuring it..."
        sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
        sudo xcodebuild -runFirstLaunch
    else
        echo "WARNING: Full Xcode was not found (/Applications/Xcode.app)."
        echo "        Download Xcode from the App Store for iOS and macOS development."
    fi
    echo -e "${GREEN}✓ CLI and language dependencies completed.${NC}\n"
fi

# 5. Ruby & Rails (rbenv integrated)
if [ ${SELECTIONS[4]} -eq 1 ]; then
    echo -e "${YELLOW}>> Installing Ruby & Rails (Selected Version: v$SELECTED_RUBY_VERSION)...${NC}"
    ensure_brew_available || exit 1

    # rbenv and ruby-build installation
    echo "Installing rbenv and ruby-build..."
    brew install rbenv ruby-build || record_failure "rbenv and ruby-build installation"
    if ! command -v rbenv >/dev/null 2>&1; then
        record_failure "rbenv command"
        echo -e "${RED}Skipping Ruby & Rails because rbenv was not found.${NC}"
    else

        # rbenv configuration
        ZSHRC_FILE="$HOME/.zshrc"
        append_once "$ZSHRC_FILE" "rbenv init" '# Initialize rbenv
eval "$(rbenv init -)"'
        eval "$(rbenv init -)"

        echo "Ruby v$SELECTED_RUBY_VERSION is being installed (this may take several minutes)..."
        if rbenv versions | grep -q "$SELECTED_RUBY_VERSION"; then
            echo "✓ Ruby v$SELECTED_RUBY_VERSION is already installed with rbenv."
        else
            rbenv install "$SELECTED_RUBY_VERSION" || record_failure "Ruby v$SELECTED_RUBY_VERSION installation"
        fi

        rbenv global "$SELECTED_RUBY_VERSION" || record_failure "Ruby global version setting"

        # Gem path setting
        append_once "$HOME/.zprofile" ".rbenv/shims" 'export PATH="$HOME/.rbenv/shims:$PATH"'
        export PATH="$HOME/.rbenv/shims:$PATH"

        echo "Installing Rails gem..."
        gem install rails || record_failure "Rails gem installation"
        rbenv rehash
    fi
    echo -e "${GREEN}✓ Ruby & Rails installation completed.${NC}\n"
fi

# 6. Java & SDKMAN
if [ ${SELECTIONS[5]} -eq 1 ]; then
    echo -e "${YELLOW}>> Installing Java & SDKMAN (Selected Version: v$SELECTED_JAVA_VERSION)...${NC}"
    if [ ! -d "$HOME/.sdkman" ]; then
        echo -e "${YELLOW}WARNING: Downloading and running the official SDKMAN installer.${NC}"
        curl -fsSL "https://get.sdkman.io" | bash || record_failure "SDKMAN installation"
    fi

    if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        record_failure "SDKMAN init file"
        echo -e "${RED}Skipping Java because SDKMAN could not be installed.${NC}"
    else
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        echo "Installing JDK $SELECTED_JAVA_VERSION..."
        sdk install java "$SELECTED_JAVA_VERSION" || record_failure "JDK $SELECTED_JAVA_VERSION installation"
        sdk default java "$SELECTED_JAVA_VERSION" || record_failure "JDK default version setting"
    fi

    echo -e "${GREEN}✓ Java & SDKMAN installation completed.${NC}\n"
fi

# 7. Flutter SDK
if [ ${SELECTIONS[6]} -eq 1 ]; then
    echo -e "${YELLOW}>> Installing Flutter SDK and mobile development environment (Selected Version: v$SELECTED_FLUTTER_VERSION)...${NC}"
    FLUTTER_DIR="$HOME/development/flutter"

    if [ ! -d "$FLUTTER_DIR" ]; then
        mkdir -p ~/development
        echo "Flutter SDK $SELECTED_FLUTTER_VERSION is being cloned..."
        git clone https://github.com/flutter/flutter.git -b "$SELECTED_FLUTTER_VERSION" "$FLUTTER_DIR" || record_failure "Flutter SDK clone"
        append_once "$HOME/.zprofile" "development/flutter/bin" 'export PATH="$PATH:$HOME/development/flutter/bin"'
        export PATH="$PATH:$HOME/development/flutter/bin"
        flutter precache || record_failure "Flutter precache"
    else
        echo "Existing Flutter installation found. Switching to selected version ($SELECTED_FLUTTER_VERSION)..."
        (
            cd "$FLUTTER_DIR" || exit 1
            git fetch --tags &&
            git checkout "$SELECTED_FLUTTER_VERSION" &&
            flutter precache
        ) || record_failure "Flutter version switch"
    fi

    echo "Running Flutter Doctor and accepting licenses..."
    export PATH="$PATH:$HOME/development/flutter/bin"
    yes | flutter doctor --android-licenses >/dev/null 2>&1 || true
    flutter doctor || true

    print_separator "$BLUE" "-"
    echo -e "  ${YELLOW}WARNING:${NC} If Android SDK is missing, open Android Studio once and"
    echo -e "  complete the default SDK download. Then run:"
    echo -e "  ${CYAN}flutter doctor --android-licenses${NC}"
    print_separator "$BLUE" "-"
    echo -e "${GREEN}✓ Flutter installation completed.${NC}\n"
fi

# 8. Rust & Cargo
if [ ${SELECTIONS[7]} -eq 1 ]; then
    echo -e "${YELLOW}>> Installing Rust and Cargo...${NC}"
    if ! command -v rustc >/dev/null 2>&1; then
        echo -e "${YELLOW}WARNING: Downloading and running the official Rustup installer.${NC}"
        curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" | sh -s -- -y || record_failure "Rustup installation"
        [ -s "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
        append_once "$HOME/.zprofile" ".cargo/env" 'source "$HOME/.cargo/env"'
    else
        rustup update || record_failure "Rustup update"
    fi
    echo -e "${GREEN}✓ Rust and Cargo installation completed.${NC}\n"
fi

# 9. Node.js (NVM) & Web Dev
if [ ${SELECTIONS[8]} -eq 1 ]; then
    echo -e "${YELLOW}>> Installing Node.js (NVM) and web development tools...${NC}"
    if [ ! -d "$HOME/.nvm" ]; then
        echo -e "${YELLOW}WARNING: Downloading and running the official NVM installer.${NC}"
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || record_failure "NVM installation"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        echo "NVM is already installed; updating..."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    if ! command -v nvm >/dev/null 2>&1; then
        record_failure "NVM command"
        echo -e "${RED}Skipping Node.js because NVM could not be installed.${NC}"
        echo -e "${GREEN}✓ Node.js & web development tools completed.${NC}\n"
    else
        nvm install --lts || record_failure "Node.js LTS installation"
        nvm use --lts || record_failure "activate Node.js LTS"
        nvm alias default 'lts/*' || record_failure "NVM default alias"

        echo "Installing Yarn and pnpm..."
        npm install -g yarn pnpm || record_failure "Yarn and pnpm installation"
        echo -e "${GREEN}✓ Node.js & web development tools completed.${NC}\n"
    fi
fi

# 10. Terminal customization & themes
if [ ${SELECTIONS[9]} -eq 1 ]; then
    echo -e "${YELLOW}>> Starting terminal customization and theme installation...${NC}"
    ensure_brew_available || exit 1

    if ! command -v starship &> /dev/null; then
        echo "Installing Starship..."
        brew install starship || record_failure "Starship installation"
    else
        echo "✓ Starship is already installed."
    fi

    if ! brew list --cask 2>/dev/null | grep -q "font-jetbrains-mono-nerd-font"; then
        echo "Installing JetBrains Mono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font || record_failure "JetBrains Mono Nerd Font installation"
    else
        echo "✓ JetBrains Mono Nerd Font is already installed."
    fi

    # Download and import each selected theme
    default_theme_name=""
    for i in "${!THEME_NAMES[@]}"; do
        if [ ${THEME_SELECTIONS[$i]} -eq 1 ]; then
            theme_name=""
            theme_url=""
            theme_url_alt=""
            theme_file=""
            expected_profile_name=""

            case $i in
                0)
                    theme_name="Gruvbox-dark"
                    theme_url="https://raw.githubusercontent.com/morhetz/gruvbox-contrib/master/osx-terminal/Gruvbox-dark.terminal"
                    theme_file="Gruvbox-dark.terminal"
                    expected_profile_name="Gruvbox-dark"
                    ;;
                1)
                    theme_name="Dracula"
                    theme_url="https://raw.githubusercontent.com/dracula/terminal-app/main/Dracula.terminal"
                    theme_file="Dracula.terminal"
                    expected_profile_name="Dracula"
                    ;;
                2)
                    theme_name="Nord"
                    theme_url="https://raw.githubusercontent.com/nordtheme/terminal-app/refs/heads/develop/src/xml/Nord.terminal"
                    theme_file="Nord.terminal"
                    expected_profile_name="Nord"
                    ;;
                3)
                    theme_name="Solarized Dark ansi"
                    theme_url="https://raw.githubusercontent.com/altercation/solarized/master/osx-terminal.app-colors-solarized/Solarized%20Dark%20ansi.terminal"
                    theme_file="Solarized-Dark.terminal"
                    expected_profile_name="Solarized-Dark"
                    ;;
                4)
                    theme_name="rose-pine"
                    theme_url="https://raw.githubusercontent.com/rose-pine/terminal.app/main/rose-pine.terminal"
                    theme_file="rose-pine.terminal"
                    expected_profile_name="rose-pine"
                    ;;
                5)
                    theme_name="Monokai"
                    theme_url="https://raw.githubusercontent.com/stephenway/monokai.terminal/master/Monokai.terminal"
                    theme_file="Monokai.terminal"
                    expected_profile_name="Monokai"
                    ;;
                6)
                    theme_name="One Dark"
                    theme_url="https://raw.githubusercontent.com/nathanbuchar/atom-one-dark-terminal/master/scheme/terminal/One%20Dark.terminal"
                    theme_url_alt="https://github.com/nathanbuchar/atom-one-dark-terminal/raw/master/scheme/terminal/One%20Dark.terminal"
                    theme_file="One-Dark.terminal"
                    expected_profile_name="One-Dark"
                    ;;
                7)
                    theme_name="tokyo-night"
                    theme_url="https://raw.githubusercontent.com/l3olton/tokyo-night.terminal/main/tokyo-night.terminal"
                    theme_file="tokyo-night.terminal"
                    expected_profile_name="tokyo-night"
                    ;;
            esac

            theme_path="$HOME/$theme_file"
            if [ ! -f "$theme_path" ]; then
                download_theme_file "$theme_path" "$theme_name" "$theme_url" "$theme_url_alt" || record_failure "$theme_name theme download"
            elif terminal_profile_exists "$expected_profile_name"; then
                echo "[$expected_profile_name] Terminal profile is already installed."
            else
                echo "[$theme_name] file exists and will be imported into Terminal..."
            fi

            if [[ -f "$theme_path" ]]; then
                if ! set_terminal_profile_file_name "$theme_path" "$expected_profile_name"; then
                    echo -e "${YELLOW}! $theme_name profile name in the file could not be updated; existing name will be used.${NC}"
                fi
                terminal_profile_name=$(read_terminal_profile_name "$theme_path" "$expected_profile_name")

                if import_terminal_profile "$theme_path" "$terminal_profile_name"; then
                    echo -e "${GREEN}✓ $terminal_profile_name profile was imported into Terminal.${NC}"
                else
                    echo -e "${YELLOW}! $terminal_profile_name profile could not be verified; refreshing theme file...${NC}"
                    if download_theme_file "$theme_path" "$theme_name" "$theme_url" "$theme_url_alt"; then
                        if ! set_terminal_profile_file_name "$theme_path" "$expected_profile_name"; then
                            echo -e "${YELLOW}! $theme_name profile name in the file could not be updated; existing name will be used.${NC}"
                        fi
                        terminal_profile_name=$(read_terminal_profile_name "$theme_path" "$expected_profile_name")
                        if import_terminal_profile "$theme_path" "$terminal_profile_name"; then
                            echo -e "${GREEN}✓ $terminal_profile_name profile was re-downloaded and imported.${NC}"
                        else
                            record_failure "$theme_name theme import"
                            echo -e "${YELLOW}! $terminal_profile_name profile could not be verified in Terminal.${NC}"
                        fi
                    else
                        record_failure "$theme_name theme refresh"
                        echo -e "${YELLOW}! $theme_name theme file could not be refreshed.${NC}"
                    fi
                fi

                if [ $THEME_DEFAULT -eq $i ]; then
                    default_theme_name="$terminal_profile_name"
                fi

                if apply_terminal_profile_font "$terminal_profile_name"; then
                    echo -e "${GREEN}✓ $terminal_profile_name profile was configured with the JetBrains Mono font.${NC}"
                else
                    echo -e "${YELLOW}! $terminal_profile_name profile was configured, but the JetBrains Mono font could not be applied (restart Terminal and try again).${NC}"
                fi
            else
                echo -e "${RED}WARNING: $theme_name profile was not found!${NC}"
            fi
        fi
    done

    # Default Theme Selection
    starship_preset="gruvbox-rainbow" # Use the colorful Gruvbox-style prompt preset for all themes.
    if [ -z "$default_theme_name" ]; then
        default_theme_name="${THEME_NAMES[$THEME_DEFAULT]}"
    fi

    echo "Default theme '$default_theme_name' is being set..."
    set_terminal_default_profile "$default_theme_name"

    # Switch active Terminal windows/tabs to the selected default theme (live AppleScript update)
    echo "Live Terminal theme '$default_theme_name' is being updated..."
    if terminal_profile_exists "$default_theme_name"; then
        osascript -e "tell application \"Terminal\" to if exists window 1 then set current settings of first window to settings set \"$default_theme_name\"" 2>/dev/null || true
    else
        record_failure "$default_theme_name default theme setting"
    fi

    # Updating Zsh configuration (.zshrc)
    echo "Updating .zshrc for Starship and terminal shortcuts..."
    ZSHRC_FILE="$HOME/.zshrc"
    append_once "$ZSHRC_FILE" "starship init zsh" '# Initialize Starship Prompt
eval "$(starship init zsh)"'

    # Add alias so clear also clears the scrollback buffer
    echo "Checking clear alias for scrollback cleanup..."
    configure_clear_alias "$ZSHRC_FILE"

    # Hide the "Last login" line in the macOS login banner
    echo "Hiding the Last login message at Terminal startup..."
    touch "$HOME/.hushlogin" || record_failure "hide Terminal Last login message"

    # Creating Starship theme preset
    echo "Starship default theme ($starship_preset) is being checked..."
    mkdir -p "$HOME/.config"
    if [ -f "$HOME/.config/starship.toml" ]; then
        update_starship_palette "$HOME/.config/starship.toml" "$default_theme_name" || record_failure "Starship color palette update"
    else
        starship preset "$starship_preset" -o "$HOME/.config/starship.toml" || record_failure "Starship preset creation"
        update_starship_palette "$HOME/.config/starship.toml" "$default_theme_name" || record_failure "Starship color palette update"
    fi
    echo -e "${GREEN}✓ Terminal customizations were applied successfully.${NC}\n"
fi

# 11. AI Coding Tools (Codex, Claude Code, Copilot, Antigravity, OpenCode)
if [ ${SELECTIONS[10]} -eq 1 ]; then
    echo -e "${YELLOW}>> Installing AI coding tools...${NC}"

    if [ ${AI_SELECTIONS[0]} -eq 1 ]; then
        ensure_brew_available || exit 1
        if ! command -v codex &> /dev/null; then
            echo "Installing Codex CLI..."
            brew install --cask codex || record_failure "Codex CLI installation"
        else
            echo "✓ Codex CLI is already installed."
        fi
    fi

    if [ ${AI_SELECTIONS[1]} -eq 1 ]; then
        if ! command -v claude &> /dev/null; then
            echo "Installing Claude Code..."
            if ! command -v npm &> /dev/null; then
                ensure_brew_available || exit 1
                echo "npm was not found; installing Node.js..."
                brew install node || record_failure "Node.js/npm installation"
            fi

            if command -v npm &> /dev/null; then
                npm install -g @anthropic-ai/claude-code || record_failure "Claude Code installation"
            else
                record_failure "npm was not found for Claude Code"
            fi
        else
            claude_version=$(claude --version 2>/dev/null || true)
            if [ -n "$claude_version" ]; then
                echo "✓ Claude Code is already installed ($claude_version)."
            else
                echo "✓ Claude Code is already installed."
            fi
        fi
    fi

    if [ ${AI_SELECTIONS[2]} -eq 1 ]; then
        ensure_brew_available || exit 1
        if ! command -v copilot &> /dev/null && ! command -v copilot-cli &> /dev/null; then
            echo "Installing GitHub Copilot CLI..."
            brew install copilot-cli || record_failure "GitHub Copilot CLI installation"
        else
            echo "✓ GitHub Copilot CLI is already installed."
        fi
    fi

    if [ ${AI_SELECTIONS[3]} -eq 1 ]; then
        if ! command -v agy &> /dev/null; then
            echo "Installing Antigravity CLI..."
            echo -e "${YELLOW}WARNING: Downloading and running the Antigravity installer.${NC}"
            curl -fsSL https://antigravity.google/cli/install.sh | bash || record_failure "Antigravity CLI installation"
        else
            echo "✓ Antigravity CLI is already installed."
        fi
    fi

    if [ ${AI_SELECTIONS[4]} -eq 1 ]; then
        ensure_brew_available || exit 1
        if ! command -v opencode &> /dev/null; then
            echo "Installing OpenCode..."
            brew install anomalyco/tap/opencode || record_failure "OpenCode installation"
        else
            echo "✓ OpenCode is already installed."
        fi
    fi
    echo -e "${GREEN}✓ AI coding tools installation completed.${NC}\n"
fi

# Cleanup operations (noisy Homebrew cleanup output filtered)
echo "Cleaning unnecessary Homebrew caches..."
if command -v brew >/dev/null 2>&1; then
    brew cleanup 2>&1 | grep -v -i "skipping" || true
else
    echo "Skipping cleanup because Homebrew was not found."
fi

# Speed up key repeat (macOS settings)
echo "Configuring macOS keyboard speed..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

print_failure_summary

echo
if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    print_header "Setup Complete" "All selected steps completed successfully"
else
    print_header "Setup Complete" "Some steps need attention"
fi
echo -e "  ${BLUE}Applying new PATH and terminal settings in this window...${NC}"
print_separator "$BLUE" "-"

if [ -t 0 ] && [ -n "$SHELL" ] && [ -x "$SHELL" ]; then
    exec "$SHELL" -l
fi
