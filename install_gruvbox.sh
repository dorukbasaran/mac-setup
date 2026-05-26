#!/usr/bin/env bash

# ==============================================================================
# macOS Terminal Gruvbox & Starship Installer & Configurator
# ==============================================================================
# Bu betik, macOS Terminal.app uygulamasını popüler Gruvbox renk paletine geçirir,
# Starship durum çubuğunu kurar, Nerd Font fontunu tanımlar ve hepsini yapılandırır.
# ==============================================================================

# Renk tanımlamaları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # Renk sıfırlama

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}   Gruvbox & Starship Terminal Kurulum Sihirbazı      ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# 1. Homebrew Kontrolü ve Kurulumu
echo -e "\n${YELLOW}[1/6] Homebrew Paket Yöneticisi kontrol ediliyor...${NC}"
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew bulunamadı. Kurulum başlatılıyor...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Homebrew'i PATH'e ekle (Apple Silicon Mac'ler için varsayılan konum)
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}✓ Homebrew zaten kurulu.${NC}"
fi

# 2. Starship ve JetBrains Mono Nerd Font Kurulumu
echo -e "\n${YELLOW}[2/6] Starship ve JetBrains Mono Nerd Font kuruluyor...${NC}"
brew install starship
brew install --cask font-jetbrains-mono-nerd-font
echo -e "${GREEN}✓ Kurulumlar tamamlandı.${NC}"

# 3. Gruvbox Renk Profilinin İndirilmesi ve İçe Aktarılması
echo -e "\n${YELLOW}[3/6] Gruvbox Dark terminal renk profili indiriliyor...${NC}"
THEME_URL="https://raw.githubusercontent.com/morhetz/gruvbox-contrib/master/osx-terminal/Gruvbox-dark.terminal"
THEME_PATH="$HOME/Gruvbox-dark.terminal"

curl -fsSL "$THEME_URL" -o "$THEME_PATH"

if [[ -f "$THEME_PATH" ]]; then
    echo -e "${GREEN}✓ Tema başarıyla indirildi. Terminal'e aktarılıyor...${NC}"
    open "$THEME_PATH"
    sleep 2 # Terminal'in profili tanıması için kısa bir süre bekle
else
    echo -e "${RED}✗ Tema dosyası indirilemedi!${NC}"
    exit 1
fi

# 4. Yazı Tipi ve Varsayılan Profil Ayarlarının Yapılması
echo -e "\n${YELLOW}[4/6] Yazı tipi ve varsayılan profil ayarları yapılıyor...${NC}"
# AppleScript ile yazı tipi ve boyutunu ayarla
osascript -e 'tell application "Terminal" to set font name of settings set "Gruvbox-dark" to "JetBrainsMonoNerdFont-Regular"'
osascript -e 'tell application "Terminal" to set font size of settings set "Gruvbox-dark" to 13'

# macOS defaults ile varsayılan ve başlangıç profilini Gruvbox-dark yap
defaults write com.apple.Terminal "Default Window Settings" -string "Gruvbox-dark"
defaults write com.apple.Terminal "Startup Window Settings" -string "Gruvbox-dark"
echo -e "${GREEN}✓ Profil ve font ayarları uygulandı.${NC}"

# 5. Zsh Yapılandırmasının Güncellenmesi (.zshrc)
echo -e "\n${YELLOW}[5/6] .zshrc yapılandırma dosyası güncelleniyor...${NC}"
ZSHRC_FILE="$HOME/.zshrc"

if ! grep -q "starship init zsh" "$ZSHRC_FILE"; then
    # SDKMAN veya NVM ayarlarını bozmamak için dosyayı güvenli bir şekilde güncelle
    # Eğer nvm veya sdkman satırları varsa araya ekleyelim yoksa en sona ekleyelim.
    # Bu betik için zshrc dosyasına satırı ekliyoruz:
    echo -e "\n# Initialize Starship Prompt\neval \"\$(starship init zsh)\"" >> "$ZSHRC_FILE"
    echo -e "${GREEN}✓ .zshrc dosyasına Starship başlatıcı eklendi.${NC}"
else
    echo -e "${GREEN}✓ Starship zaten .zshrc içinde tanımlı.${NC}"
fi

# 6. Starship Gruvbox Rainbow Temasının Oluşturulması
echo -e "\n${YELLOW}[6/6] Starship Gruvbox Rainbow yapılandırması oluşturuluyor...${NC}"
mkdir -p "$HOME/.config"
starship preset gruvbox-rainbow -o "$HOME/.config/starship.toml"
echo -e "${GREEN}✓ Starship teması ~/.config/starship.toml dosyasına uygulandı.${NC}"

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}   TÜM İŞLEMLER BAŞARIYLA TAMAMLANDI! 🎉              ${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo -e "${BLUE}Yeni ayarların etkinleşmesi için terminalinizi tamamen kapatıp${NC}"
echo -e "${BLUE}yeniden açabilir veya yeni bir sekme başlatabilirsiniz.${NC}"
echo -e "${BLUE}=====================================================${NC}"
