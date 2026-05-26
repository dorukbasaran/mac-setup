#!/bin/bash

# ==============================================================================
# macOS Geliştirici Ortamı İnteraktif Kurulum Sihirbazı
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

# Kurulum Seçim Değişkenleri (Default: hepsi aktif "1")
INSTALL_SYSTEM=1
INSTALL_BREW=1
INSTALL_CASKS=1
INSTALL_CLI=1
INSTALL_RAILS=1
INSTALL_JAVA=1
INSTALL_FLUTTER=1
INSTALL_RUST=1
INSTALL_NODE=1
INSTALL_TERMINAL=1

# Varsayılan Tema Seçimi
# 1: Gruvbox Dark, 2: Dracula, 3: Nord, 4: Solarized Dark
THEME_CHOICE=1

show_option() {
    local num=$1
    local name=$2
    local val=$3
    if [ $val -eq 1 ]; then
        echo -e " [${GREEN}${CHECK}${NC}] ${num}. ${name}"
    else
        echo -e " [ ] ${num}. ${name}"
    fi
}

toggle_theme() {
    while true; do
        clear
        echo -e "${BLUE}=======================================================${NC}"
        echo -e "${BLUE}                 Terminal Teması Seçimi                ${NC}"
        echo -e "${BLUE}=======================================================${NC}"
        echo -e "Lütfen kurmak istediğiniz terminal temasını seçin:"
        echo -e " 1) Gruvbox Dark     (Starship: Gruvbox Rainbow)"
        echo -e " 2) Dracula          (Starship: Tokyo Night)"
        echo -e " 3) Nord             (Starship: No Runtime Versions)"
        echo -e " 4) Solarized Dark   (Starship: Plain Text Symbols)"
        echo -e "${BLUE}-------------------------------------------------------${NC}"
        echo -n "Seçiminiz (1-4): "
        read -r t_choice
        case $t_choice in
            1|2|3|4) 
                THEME_CHOICE=$t_choice
                break
                ;;
            *) 
                echo -e "${RED}Geçersiz seçim! Lütfen 1 ile 4 arasında bir değer girin.${NC}" 
                sleep 1 
                ;;
        esac
    done
}

toggle_all() {
    local sum=$((INSTALL_SYSTEM + INSTALL_BREW + INSTALL_CASKS + INSTALL_CLI + INSTALL_RAILS + INSTALL_JAVA + INSTALL_FLUTTER + INSTALL_RUST + INSTALL_NODE + INSTALL_TERMINAL))
    if [ $sum -gt 0 ]; then
        INSTALL_SYSTEM=0
        INSTALL_BREW=0
        INSTALL_CASKS=0
        INSTALL_CLI=0
        INSTALL_RAILS=0
        INSTALL_JAVA=0
        INSTALL_FLUTTER=0
        INSTALL_RUST=0
        INSTALL_NODE=0
        INSTALL_TERMINAL=0
    else
        INSTALL_SYSTEM=1
        INSTALL_BREW=1
        INSTALL_CASKS=1
        INSTALL_CLI=1
        INSTALL_RAILS=1
        INSTALL_JAVA=1
        INSTALL_FLUTTER=1
        INSTALL_RUST=1
        INSTALL_NODE=1
        INSTALL_TERMINAL=1
    fi
}

show_menu() {
    clear
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "${BLUE}        macOS Geliştirici Ortamı Kurulum Sihirbazı     ${NC}"
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "Kurmak istediğiniz bileşenleri seçin (açıp kapatmak için sayı girin)."
    echo -e "Seçimleri tamamladıktan sonra kuruluma başlamak için ${GREEN}'i'${NC} tuşuna basın."
    echo -e "${BLUE}-------------------------------------------------------${NC}"
    
    show_option 1  "Sistem Gereksinimleri (Xcode CLT & Rosetta 2)" $INSTALL_SYSTEM
    show_option 2  "Homebrew Paket Yöneticisi" $INSTALL_BREW
    show_option 3  "Arayüzlü Uygulamalar (Docker, Postman, Ollama, Zed, Spotify, Android Studio)" $INSTALL_CASKS
    show_option 4  "Temel CLI Araçları & Diller (Go, Ruby, Helm, k9s, CocoaPods)" $INSTALL_CLI
    show_option 5  "Ruby & Rails Geliştirme Ortamı (Rails gem)" $INSTALL_RAILS
    show_option 6  "Java & SDKMAN Geliştirme Ortamı (JDK 25 Temurin)" $INSTALL_JAVA
    show_option 7  "Flutter SDK & Mobil Geliştirme Ortamı" $INSTALL_FLUTTER
    show_option 8  "Rust & Cargo Geliştirme Ortamı" $INSTALL_RUST
    show_option 9  "Node.js & Web Geliştirme Ortamı (NVM, Yarn, pnpm)" $INSTALL_NODE
    show_option 10 "Terminal Özelleştirme (Starship & Font & Tema)" $INSTALL_TERMINAL
    
    echo -e "${BLUE}-------------------------------------------------------${NC}"
    
    if [ $INSTALL_TERMINAL -eq 1 ]; then
        echo -e "Terminal Teması Ayarı (Değiştirmek için ${YELLOW}'t'${NC} tuşuna basın):"
        case $THEME_CHOICE in
            1) echo -e "  Seçili Tema: ${CYAN}Gruvbox Dark${NC}" ;;
            2) echo -e "  Seçili Tema: ${CYAN}Dracula${NC}" ;;
            3) echo -e "  Seçili Tema: ${CYAN}Nord${NC}" ;;
            4) echo -e "  Seçili Tema: ${CYAN}Solarized Dark${NC}" ;;
        esac
        echo -e "${BLUE}-------------------------------------------------------${NC}"
    fi
    
    echo -e "Kısayollar: ${YELLOW}'a'${NC} (Hepsini Seç/Bırak) | ${RED}'q'${NC} (Çıkış)"
    echo -e "${BLUE}-------------------------------------------------------${NC}"
    echo -n "Seçiminiz (1-10, t, a, i, q): "
}

# İnteraktif Seçim Döngüsü
while true; do
    show_menu
    read -r opt
    case $opt in
        1) INSTALL_SYSTEM=$((1 - INSTALL_SYSTEM)) ;;
        2) INSTALL_BREW=$((1 - INSTALL_BREW)) ;;
        3) INSTALL_CASKS=$((1 - INSTALL_CASKS)) ;;
        4) INSTALL_CLI=$((1 - INSTALL_CLI)) ;;
        5) INSTALL_RAILS=$((1 - INSTALL_RAILS)) ;;
        6) INSTALL_JAVA=$((1 - INSTALL_JAVA)) ;;
        7) INSTALL_FLUTTER=$((1 - INSTALL_FLUTTER)) ;;
        8) INSTALL_RUST=$((1 - INSTALL_RUST)) ;;
        9) INSTALL_NODE=$((1 - INSTALL_NODE)) ;;
        10) INSTALL_TERMINAL=$((1 - INSTALL_TERMINAL)) ;;
        t|T) toggle_theme ;;
        a|A) toggle_all ;;
        i|I) break ;;
        q|Q) 
            echo -e "\n${RED}Kurulum iptal edildi. Çıkış yapılıyor...${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Geçersiz seçenek!${NC}" 
            sleep 1 
            ;;
    esac
done

clear
echo -e "${GREEN}Seçimleriniz alındı! Kurulum başlıyor...${NC}"
echo -e "${BLUE}=======================================================${NC}\n"

# 1. Sistem Gereksinimleri
if [ $INSTALL_SYSTEM -eq 1 ]; then
    echo -e "${YELLOW}>> Sistem gereksinimleri kontrol ediliyor...${NC}"
    # Xcode Command Line Tools
    echo "Xcode Command Line Tools kontrol ediliyor..."
    xcode-select -p >/dev/null 2>&1 || xcode-select --install

    # Rosetta 2 kurulumu (Apple Silicon için)
    if /usr/bin/pgrep oahd >/dev/null 2>&1; then
        echo "Rosetta 2 zaten kurulu."
    else
        sudo softwareupdate --install-rosetta --agree-to-license
    fi
    echo -e "${GREEN}✓ Sistem gereksinimleri tamamlandı.${NC}\n"
fi

# 2. Homebrew Kurulumu
if [ $INSTALL_BREW -eq 1 ]; then
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
if [ $INSTALL_CASKS -eq 1 ]; then
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
if [ $INSTALL_CLI -eq 1 ]; then
    echo -e "${YELLOW}>> CLI araçları, Go ve Ruby kuruluyor...${NC}"
    brew install bash git curl unzip zip go ruby helm k9s cocoapods
    brew link --overwrite kubernetes-cli 2>/dev/null || true

    # Xcode gelişmiş kurulum ayarları (Flutter iOS/macOS derlemeleri için)
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
if [ $INSTALL_RAILS -eq 1 ]; then
    echo -e "${YELLOW}>> Ruby & Rails kurulumu yapılıyor...${NC}"
    echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zprofile
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
    
    echo "Rails kuruluyor..."
    gem install rails
    echo -e "${GREEN}✓ Ruby & Rails kurulumu tamamlandı.${NC}\n"
fi

# 6. Java & SDKMAN
if [ $INSTALL_JAVA -eq 1 ]; then
    echo -e "${YELLOW}>> Java & SDKMAN kurulumu yapılıyor...${NC}"
    if [ ! -d "$HOME/.sdkman" ]; then
        # Yüklenen modern bash'i kullanmasını zorlayarak sdkman bash 4 hatasını aşıyoruz
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
if [ $INSTALL_FLUTTER -eq 1 ]; then
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
if [ $INSTALL_RUST -eq 1 ]; then
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
if [ $INSTALL_NODE -eq 1 ]; then
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
if [ $INSTALL_TERMINAL -eq 1 ]; then
    echo -e "${YELLOW}>> Terminal Özelleştirmesi ve Tema Kurulumu Başlatılıyor...${NC}"
    
    echo "Starship ve JetBrains Mono Nerd Font kuruluyor..."
    brew install starship
    brew install --cask font-jetbrains-mono-nerd-font
    
    # Tema Detayları
    case $THEME_CHOICE in
        1)
            THEME_NAME="Gruvbox-dark"
            THEME_URL="https://raw.githubusercontent.com/morhetz/gruvbox-contrib/master/osx-terminal/Gruvbox-dark.terminal"
            THEME_FILE="Gruvbox-dark.terminal"
            FONT_NAME="JetBrainsMonoNerdFont-Regular"
            STARSHIP_PRESET="gruvbox-rainbow"
            ;;
        2)
            THEME_NAME="Dracula"
            THEME_URL="https://raw.githubusercontent.com/dracula/terminal-app/main/Dracula.terminal"
            THEME_FILE="Dracula.terminal"
            FONT_NAME="JetBrainsMonoNerdFont-Regular"
            STARSHIP_PRESET="tokyo-night"
            ;;
        3)
            THEME_NAME="Nord"
            THEME_URL="https://raw.githubusercontent.com/nordtheme/terminal-app/refs/heads/develop/src/xml/Nord.terminal"
            THEME_FILE="Nord.terminal"
            FONT_NAME="JetBrainsMonoNerdFont-Regular"
            STARSHIP_PRESET="no-runtime-versions"
            ;;
        4)
            THEME_NAME="Solarized Dark"
            THEME_URL="https://raw.githubusercontent.com/altercation/solarized/master/osx-terminal.app-colors-solarized/Solarized%20Dark%20ansi.terminal"
            THEME_FILE="Solarized-Dark.terminal"
            FONT_NAME="JetBrainsMonoNerdFont-Regular"
            STARSHIP_PRESET="plain-text-symbols"
            ;;
    esac

    echo "$THEME_NAME terminal renk profili indiriliyor..."
    THEME_PATH="$HOME/$THEME_FILE"
    curl -fsSL "$THEME_URL" -o "$THEME_PATH"

    if [[ -f "$THEME_PATH" ]]; then
        open "$THEME_PATH"
        sleep 2 # Terminal'in profili tanıması için kısa bir süre bekle
        
        # AppleScript ile yazı tipi ve boyutunu ayarla
        osascript -e "tell application \"Terminal\" to set font name of settings set \"$THEME_NAME\" to \"$FONT_NAME\""
        osascript -e "tell application \"Terminal\" to set font size of settings set \"$THEME_NAME\" to 13"

        # macOS defaults ile varsayılan ve başlangıç profilini ayarla
        defaults write com.apple.Terminal "Default Window Settings" -string "$THEME_NAME"
        defaults write com.apple.Terminal "Startup Window Settings" -string "$THEME_NAME"
        echo -e "${GREEN}✓ $THEME_NAME profili varsayılan yapıldı.${NC}"
    else
        echo -e "${RED}DİKKAT: Tema dosyası indirilemedi, tema adımı atlanıyor.${NC}"
    fi

    # Zsh Yapılandırmasının Güncellenmesi (.zshrc)
    echo "Starship için .zshrc yapılandırması güncelleniyor..."
    ZSHRC_FILE="$HOME/.zshrc"
    touch "$ZSHRC_FILE"

    if ! grep -q "starship init zsh" "$ZSHRC_FILE"; then
        echo -e "\n# Initialize Starship Prompt\neval \"\$(starship init zsh)\"" >> "$ZSHRC_FILE"
    fi

    # Starship Teması Preset Oluşturulması
    echo "Starship teması ($STARSHIP_PRESET) yapılandırılıyor..."
    mkdir -p "$HOME/.config"
    starship preset "$STARSHIP_PRESET" -o "$HOME/.config/starship.toml"
    echo -e "${GREEN}✓ Terminal özelleştirmeleri başarıyla uygulandı.${NC}\n"
fi

# Temizlik işlemleri
brew cleanup

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
