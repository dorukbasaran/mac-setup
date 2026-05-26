#!/bin/bash

# ==============================================================================
# macOS Geliştirici Ortamı İnteraktif Kurulum Sihirbazı (Premium Keyboard Wizard)
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

# Kurulum Seçenekleri
CHOICES=(
    "Sistem Gereksinimleri (Xcode CLT & Rosetta 2)"
    "Homebrew Paket Yöneticisi"
    "Arayüzlü Uygulamalar (Docker, Postman, Ollama, Zed, Spotify, Android Studio)"
    "Temel CLI Araçları & Diller (Go, Ruby, Helm, k9s, CocoaPods)"
    "Ruby & Rails Geliştirme Ortamı (Rails gem)"
    "Java & SDKMAN Geliştirme Ortamı (JDK 25 Temurin)"
    "Flutter SDK & Mobil Geliştirme Ortamı"
    "Rust & Cargo Geliştirme Ortamı"
    "Node.js & Web Geliştirme Ortamı (NVM, Yarn, pnpm)"
    "Terminal Özelleştirme & Starship Entegrasyonu"
)

# Seçim durumları (1: seçili, 0: değil)
SELECTIONS=(1 1 1 1 1 1 1 1 1 1)

# Temalar
THEME_NAMES=("Gruvbox-dark" "Dracula" "Nord" "Solarized-Dark")
THEME_LABELS=("Gruvbox Dark" "Dracula" "Nord" "Solarized Dark")
THEME_SELECTIONS=(1 0 1 0) # Varsayılan olarak birden fazla kurulabilir
THEME_DEFAULT=2 # Varsayılan tema (Kullanıcının seçimi üzerine Nord yapıldı)

CURRENT_INDEX=0
TOTAL_ITEMS=16 # 10 bileşen + 4 tema + 2 aksiyon

# İmleç Kontrolü ve Temizleme
cleanup_cursor() {
    tput cnorm # İmleci göster
}
trap cleanup_cursor EXIT
tput civis # İmleci geçici olarak gizle

render_menu() {
    clear
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "${BLUE}        macOS Geliştirici Ortamı Kurulum Sihirbazı     ${NC}"
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "Klavye ${YELLOW}Yön Tuşları (↑/↓)${NC} ile gezinin, ${YELLOW}SPACE${NC} veya ${YELLOW}ENTER${NC} ile seçin."
    echo -e "Temalar üzerinde ${YELLOW}'v'${NC} tuşuna basarak varsayılan temayı seçin."
    echo -e "Hepsini seçmek/bırakmak için ${YELLOW}'a'${NC} tuşuna basabilirsiniz."
    echo -e "Kuruluma başlamak için en alttaki ${GREEN}[ Kuruluma Başla ]${NC} seçeneğinde ${GREEN}ENTER${NC}'a basın."
    echo -e "${BLUE}-------------------------------------------------------${NC}"

    # Bileşen Listesi (0-9)
    for i in {0..9}; do
        local check=" "
        if [ ${SELECTIONS[$i]} -eq 1 ]; then
            check="${GREEN}${CHECK}${NC}"
        fi
        
        if [ $CURRENT_INDEX -eq $i ]; then
            echo -e "${CYAN}➔ [${check}] ${CHOICES[$i]}${NC}"
        else
            echo -e "   [${check}] ${CHOICES[$i]}"
        fi
    done

    echo -e "${BLUE}-------------------------------------------------------${NC}"
    
    # Temalar Başlığı
    if [ ${SELECTIONS[9]} -eq 1 ]; then
        echo -e "${YELLOW}Yüklenecek Temalar (En az bir tema seçilmelidir):${NC}"
    else
        echo -e "${NC}Yüklenecek Temalar (Terminal Özelleştirme kapalı):${NC}"
    fi

    # Tema Listesi (10-13)
    for i in {0..3}; do
        local item_idx=$((i + 10))
        local check=" "
        if [ ${THEME_SELECTIONS[$i]} -eq 1 ]; then
            check="${GREEN}${CHECK}${NC}"
        fi
        
        local default_str=""
        if [ $THEME_DEFAULT -eq $i ]; then
            default_str=" ${PURPLE}(Varsayılan)${NC}"
        fi

        local label=${THEME_LABELS[$i]}
        if [ ${SELECTIONS[9]} -eq 0 ]; then
            label="${NC}${label} (Devre Dışı)${NC}"
        fi

        if [ $CURRENT_INDEX -eq $item_idx ]; then
            echo -e "${CYAN}➔ [${check}] ${label}${default_str}${NC}"
        else
            echo -e "   [${check}] ${label}${default_str}"
        fi
    done

    echo -e "${BLUE}-------------------------------------------------------${NC}"

    # Aksiyonlar (14-15)
    if [ $CURRENT_INDEX -eq 14 ]; then
        echo -e "${CYAN}➔ ${GREEN}[ Kuruluma Başla ]${NC}"
    else
        echo -e "   ${GREEN}[ Kuruluma Başla ]${NC}"
    fi

    if [ $CURRENT_INDEX -eq 15 ]; then
        echo -e "${CYAN}➔ ${RED}[ İptal Et ve Çık ]${NC}"
    else
        echo -e "   ${RED}[ İptal Et ve Çık ]${NC}"
    fi

    echo -e "${BLUE}-------------------------------------------------------${NC}"
}

read_keypress() {
    local key
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key
        if [[ $key == "[A" ]]; then
            echo "UP"
        elif [[ $key == "[B" ]]; then
            echo "DOWN"
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

toggle_all() {
    local sum=0
    for val in "${SELECTIONS[@]}"; do
        sum=$((sum + val))
    done
    if [ $sum -gt 0 ]; then
        SELECTIONS=(0 0 0 0 0 0 0 0 0 0)
    else
        SELECTIONS=(1 1 1 1 1 1 1 1 1 1)
    fi
}

# İnteraktif Döngü
while true; do
    render_menu
    action=$(read_keypress)
    
    case $action in
        "UP")
            CURRENT_INDEX=$(( (CURRENT_INDEX - 1 + TOTAL_ITEMS) % TOTAL_ITEMS ))
            ;;
        "DOWN")
            CURRENT_INDEX=$(( (CURRENT_INDEX + 1) % TOTAL_ITEMS ))
            ;;
        "SPACE"|"ENTER")
            if [ $CURRENT_INDEX -eq 14 ]; then
                # Kuruluma Başla aksiyonu tetiklendiğinde ENTER ile devam et
                if [[ $action == "ENTER" ]]; then
                    if [ ${SELECTIONS[9]} -eq 1 ]; then
                        local theme_sum=0
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
                fi
            elif [ $CURRENT_INDEX -eq 15 ]; then
                # İptal Et ve Çık
                if [[ $action == "ENTER" ]]; then
                    echo -e "\n${RED}Kurulum iptal edildi. Çıkış yapılıyor...${NC}"
                    tput cnorm
                    exit 0
                fi
            elif [ $CURRENT_INDEX -ge 0 ] && [ $CURRENT_INDEX -le 9 ]; then
                SELECTIONS[$CURRENT_INDEX]=$(( 1 - SELECTIONS[$CURRENT_INDEX] ))
            elif [ $CURRENT_INDEX -ge 10 ] && [ $CURRENT_INDEX -le 13 ]; then
                local theme_idx=$(( CURRENT_INDEX - 10 ))
                THEME_SELECTIONS[$theme_idx]=$(( 1 - THEME_SELECTIONS[$theme_idx] ))
                
                # Eğer tema seçildiyse terminal özelleştirmeyi otomatik olarak aktif et
                if [ ${THEME_SELECTIONS[$theme_idx]} -eq 1 ]; then
                    SELECTIONS[9]=1
                fi
                
                # Eğer seçimi kaldırılan tema varsayılan ise, varsayılanı başka seçiliye kaydır
                if [ ${THEME_SELECTIONS[$theme_idx]} -eq 0 ] && [ $THEME_DEFAULT -eq $theme_idx ]; then
                    for k in {0..3}; do
                        if [ ${THEME_SELECTIONS[$k]} -eq 1 ]; then
                            THEME_DEFAULT=$k
                            break
                        fi
                    done
                fi
            fi
            ;;
        "DEFAULT")
            if [ $CURRENT_INDEX -ge 10 ] && [ $CURRENT_INDEX -le 13 ]; then
                local theme_idx=$(( CURRENT_INDEX - 10 ))
                THEME_SELECTIONS[$theme_idx]=1
                SELECTIONS[9]=1
                THEME_DEFAULT=$theme_idx
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
    xcode-select -p >/dev/null 2>&1 || xcode-select --install

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
    if ! command -v brew &> /dev/null; then
        echo "Homebrew kuruluyor..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        brew update
    fi
    echo -e "${GREEN}✓ Homebrew tamamlandı.${NC}\n"
fi

# 3. Casks Kurulumu
if [ ${SELECTIONS[2]} -eq 1 ]; then
    echo -e "${YELLOW}>> Arayüzlü Uygulamalar (Casks) kuruluyor...${NC}"
    CASKS=(
        docker
        postman
        ollama
        zed
        spotify
        android-studio
    )
    brew install --cask "${CASKS[@]}" || true
    echo -e "${GREEN}✓ Uygulamalar başarıyla kuruldu.${NC}\n"
fi

# 4. Temel CLI ve Diller
if [ ${SELECTIONS[3]} -eq 1 ]; then
    echo -e "${YELLOW}>> CLI araçları, Go ve Ruby kuruluyor...${NC}"
    brew install bash git curl unzip zip go ruby helm k9s cocoapods
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

# 5. Ruby & Rails
if [ ${SELECTIONS[4]} -eq 1 ]; then
    echo -e "${YELLOW}>> Ruby & Rails kurulumu yapılıyor...${NC}"
    echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zprofile
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
    
    echo "Rails kuruluyor..."
    gem install rails
    echo -e "${GREEN}✓ Ruby & Rails kurulumu tamamlandı.${NC}\n"
fi

# 6. Java & SDKMAN
if [ ${SELECTIONS[5]} -eq 1 ]; then
    echo -e "${YELLOW}>> Java & SDKMAN kurulumu yapılıyor...${NC}"
    if [ ! -d "$HOME/.sdkman" ]; then
        curl -s "https://get.sdkman.io" | /opt/homebrew/bin/bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        sdk install java 25-tem
    else
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        sdk install java 25-tem
    fi
    echo -e "${GREEN}✓ Java & SDKMAN kurulumu tamamlandı.${NC}\n"
fi

# 7. Flutter SDK
if [ ${SELECTIONS[6]} -eq 1 ]; then
    echo -e "${YELLOW}>> Flutter SDK ve Mobil Geliştirme Ortamı kuruluyor...${NC}"
    FLUTTER_DIR="$HOME/development/flutter"
    if [ ! -d "$FLUTTER_DIR" ]; then
        mkdir -p ~/development
        git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
        echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zprofile
        export PATH="$PATH:$HOME/development/flutter/bin"
        flutter precache
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
        curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" | sh -s -- -y
        source "$HOME/.cargo/env"
        echo 'source "$HOME/.cargo/env"' >> ~/.zprofile
    else
        rustup update
    fi
    echo -e "${GREEN}✓ Rust ve Cargo kurulumu tamamlandı.${NC}\n"
fi

# 9. Node.js (NVM) & Web Dev
if [ ${SELECTIONS[8]} -eq 1 ]; then
    echo -e "${YELLOW}>> Node.js (NVM) ve Web Geliştirme Araçları kuruluyor...${NC}"
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts
        nvm use --lts
        nvm alias default 'lts/*'

        echo "Yarn ve pnpm kuruluyor..."
        npm install -g yarn pnpm
    else
        echo "NVM zaten kurulu, güncelleniyor..."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts
        nvm use --lts
    fi
    echo -e "${GREEN}✓ Node.js & Web Geliştirme Araçları tamamlandı.${NC}\n"
fi

# 10. Terminal Özelleştirme & Temalar
if [ ${SELECTIONS[9]} -eq 1 ]; then
    echo -e "${YELLOW}>> Terminal Özelleştirmesi ve Tema Kurulumu Başlatılıyor...${NC}"
    
    echo "Starship ve JetBrains Mono Nerd Font kuruluyor..."
    brew install starship
    brew install --cask font-jetbrains-mono-nerd-font
    
    # Seçilen her temayı indir ve içe aktar
    for i in {0..3}; do
        if [ ${THEME_SELECTIONS[$i]} -eq 1 ]; then
            local theme_name=""
            local theme_url=""
            local theme_file=""
            local font_name="JetBrainsMonoNerdFont-Regular"

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
            esac

            echo "[$theme_name] terminal renk profili indiriliyor..."
            local theme_path="$HOME/$theme_file"
            curl -fsSL "$theme_url" -o "$theme_path"

            if [[ -f "$theme_path" ]]; then
                open "$theme_path"
                sleep 1 # Tanınması için kısa bir süre bekle
                
                # AppleScript ile yazı tipi ve boyutunu ayarla
                osascript -e "tell application \"Terminal\" to set font name of settings set \"$theme_name\" to \"$font_name\""
                osascript -e "tell application \"Terminal\" to set font size of settings set \"$theme_name\" to 13"
                echo -e "${GREEN}✓ $theme_name profili başarıyla kuruldu.${NC}"
            else
                echo -e "${RED}DİKKAT: $theme_name tema dosyası indirilemedi!${NC}"
            fi
        fi
    done

    # Varsayılan Tema Seçimi
    local default_theme_name=""
    local starship_preset=""
    case $THEME_DEFAULT in
        0)
            default_theme_name="Gruvbox-dark"
            starship_preset="gruvbox-rainbow"
            ;;
        1)
            default_theme_name="Dracula"
            starship_preset="tokyo-night"
            ;;
        2)
            default_theme_name="Nord"
            starship_preset="no-runtime-versions"
            ;;
        3)
            default_theme_name="Solarized Dark"
            starship_preset="plain-text-symbols"
            ;;
    esac

    echo "Varsayılan tema '$default_theme_name' olarak ayarlanıyor..."
    defaults write com.apple.Terminal "Default Window Settings" -string "$default_theme_name"
    defaults write com.apple.Terminal "Startup Window Settings" -string "$default_theme_name"

    # Zsh Yapılandırmasının Güncellenmesi (.zshrc)
    echo "Starship için .zshrc yapılandırması güncelleniyor..."
    ZSHRC_FILE="$HOME/.zshrc"
    touch "$ZSHRC_FILE"

    if ! grep -q "starship init zsh" "$ZSHRC_FILE"; then
        echo -e "\n# Initialize Starship Prompt\neval \"\$(starship init zsh)\"" >> "$ZSHRC_FILE"
    fi

    # Starship Teması Preset Oluşturulması
    echo "Starship varsayılan teması ($starship_preset) yapılandırılıyor..."
    mkdir -p "$HOME/.config"
    starship preset "$starship_preset" -o "$HOME/.config/starship.toml"
    echo -e "${GREEN}✓ Terminal özelleştirmeleri başarıyla uygulandı.${NC}\n"
fi

# Temizlik işlemleri (Gürültülü Homebrew uyarıları temizlendi)
echo "Homebrew gereksiz önbellekleri temizleniyor..."
brew cleanup 2>&1 | grep -v -i "skipping" || true

# Key repeat hızlandır (macOS Ayarları)
echo "macOS klavye hızı ayarlanıyor..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

echo -e "\n${GREEN}=======================================================${NC}"
echo -e "${GREEN}        TÜM SEÇİLİ KURULUMLAR TAMAMLANDI! 🎉          ${NC}"
echo -e "${GREEN}=======================================================${NC}"
echo -e "${BLUE}Yeni kurulan dillerin, path ayarlarının ve terminal ${NC}"
echo -e "${BLUE}tasarımının aktif olması için terminali kapatıp açın  ${NC}"
echo -e "${BLUE}veya 'source ~/.zshrc' komutunu çalıştırın.           ${NC}"
echo -e "${BLUE}=======================================================${NC}"
