#!/bin/bash

# Xcode Command Line Tools
echo "Xcode Command Line Tools kontrol ediliyor..."
xcode-select -p >/dev/null 2>&1 || xcode-select --install

# Rosetta 2 kurulumu (Apple Silicon için)
if /usr/bin/pgrep oahd >/dev/null 2>&1; then
    echo "Rosetta 2 zaten kurulu."
else
    sudo softwareupdate --install-rosetta --agree-to-license
fi

# Homebrew kurulumu
if ! command -v brew &> /dev/null; then
    echo "Homebrew kuruluyor..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    brew update
fi

# Uygulamalar (Casks)
CASKS=(
    docker
    postman
    ollama
    zed
    spotify
    android-studio
)
echo "Uygulamalar (Casks) kuruluyor..."
brew install --cask "${CASKS[@]}" || true

# Temel CLI ve Yeni Diller (Go, Ruby, vs.)
echo "CLI araçları, Go ve Ruby kuruluyor..."
# docker ve kubectl paketlerini çıkardık çünkü Docker Desktop bunları sağlıyor.
# helm ve k9s bağımlılık olarak kubernetes-cli (kubectl) kurabilir, bu yüzden link conflict olmaması için önlem alıyoruz.
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

# Ruby path ayarı (Homebrew ile kurulan Ruby'nin sistem Ruby'sinin önüne geçmesi için)
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zprofile
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# Rails kurulumu
echo "Rails kuruluyor..."
gem install rails

# SDKMAN ve JDK 25 Temurin
if [ ! -d "$HOME/.sdkman" ]; then
    # Yüklenen modern bash'i kullanmasını zorlayarak sdkman bash 4 hatasını aşıyoruz
    curl -s "https://get.sdkman.io" | /opt/homebrew/bin/bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java 25-tem
else
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java 25-tem
fi

# Flutter Kurulumu
FLUTTER_DIR="$HOME/development/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
    mkdir -p ~/development
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
    echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zprofile
    export PATH="$PATH:$HOME/development/flutter/bin"
    flutter precache
fi

# Flutter ayarlarını (var olan kurulumda da) her ihtimale karşı çalıştır.
echo "Flutter Doctor çalıştırılıyor ve lisanslar onaylanıyor..."
export PATH="$PATH:$HOME/development/flutter/bin"
yes | flutter doctor --android-licenses >/dev/null 2>&1 || true
flutter doctor || true

echo "=========================================================================="
echo "DİKKAT: Android SDK eksik hatası alıyorsanız, uygulamalar klasöründeki"
echo "Android Studio'yu BİR KERE AÇIP, varsayılan Android SDK'sının inmesini"
echo "beklemelisiniz. Ardından lisans hatası almamak için terminalde:"
echo "flutter doctor --android-licenses"
echo "komutunu çalıştırabilirsiniz."
echo "=========================================================================="

# Rust ve Cargo kurulumu
echo "Rust ve Cargo kuruluyor..."
if ! command -v rustc >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" | sh -s -- -y
    source "$HOME/.cargo/env"
    echo 'source "$HOME/.cargo/env"' >> ~/.zprofile
else
    rustup update
fi

# Node.js, NVM, Yarn ve pnpm kurulumu
echo "Node.js (NVM) kuruluyor..."
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

brew cleanup

# Terminal, Gruvbox Tema & Starship Kurulumu ve Yapılandırması
echo "Starship ve JetBrains Mono Nerd Font kuruluyor..."
brew install starship
brew install --cask font-jetbrains-mono-nerd-font

echo "Gruvbox Dark terminal renk profili indiriliyor ve kuruluyor..."
THEME_URL="https://raw.githubusercontent.com/morhetz/gruvbox-contrib/master/osx-terminal/Gruvbox-dark.terminal"
THEME_PATH="$HOME/Gruvbox-dark.terminal"
curl -fsSL "$THEME_URL" -o "$THEME_PATH"

if [[ -f "$THEME_PATH" ]]; then
    open "$THEME_PATH"
    sleep 2 # Terminal'in profili tanıması için kısa bir süre bekle
    
    # AppleScript ile yazı tipi ve boyutunu ayarla
    osascript -e 'tell application "Terminal" to set font name of settings set "Gruvbox-dark" to "JetBrainsMonoNerdFont-Regular"'
    osascript -e 'tell application "Terminal" to set font size of settings set "Gruvbox-dark" to 13'

    # macOS defaults ile varsayılan ve başlangıç profilini Gruvbox-dark yap
    defaults write com.apple.Terminal "Default Window Settings" -string "Gruvbox-dark"
    defaults write com.apple.Terminal "Startup Window Settings" -string "Gruvbox-dark"
else
    echo "DİKKAT: Gruvbox teması indirilemedi, bu adım atlanıyor."
fi

# Zsh Yapılandırmasının Güncellenmesi (.zshrc)
echo "Starship için .zshrc yapılandırması güncelleniyor..."
ZSHRC_FILE="$HOME/.zshrc"
touch "$ZSHRC_FILE"

if ! grep -q "starship init zsh" "$ZSHRC_FILE"; then
    echo -e "\n# Initialize Starship Prompt\neval \"\$(starship init zsh)\"" >> "$ZSHRC_FILE"
fi

# Starship Gruvbox Rainbow Temasının Oluşturulması
echo "Starship Gruvbox Rainbow teması yapılandırılıyor..."
mkdir -p "$HOME/.config"
starship preset gruvbox-rainbow -o "$HOME/.config/starship.toml"

# Key repeat hızlandır (macOS Ayarları)
echo "macOS klavye hızı ayarlanıyor..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

echo "İşlem tamamlandı! Yeni kurulan dillerin ve path ayarlarının aktif olması için terminali kapatıp açın veya source ~/.zshrc komutunu çalıştırın."
