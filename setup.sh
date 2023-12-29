#!/usr/bin/env bash

# Source bash config
cat >> "$HOME/.bashrc" <<'EOF'
[[ -f "$HOME/dotfiles/bash/.bash_common" ]] && . "$HOME/dotfiles/bash/.bash_common"
EOF

mkdir -p "$HOME/Downloads/setup"
version_num=$(grep VERSION_ID /etc/os-release | cut -d "=" -f 2 | sed -e s/\"//g)
version_code=$(grep UBUNTU_CODENAME /etc/os-release | cut -d "=" -f 2)

# Install required dependencies
sudo apt install -y ca-certificates curl git gnupg software-properties-common

# Clone dotfiles and setup symlinks
git clone https://github.com/kdien/dotfiles.git "$HOME/dotfiles"
configs=(
    alacritty
    nvim
    powershell
    tmux
    wezterm
)
for config in "${configs[@]}"; do
    ln -sf "$HOME/dotfiles/$config" "$HOME/.config/$config"
done

# Copy base git config
cp "$HOME/dotfiles/git/config" "$HOME/.gitconfig"

# Configure GNOME settings
if command -v gnome-shell &>/dev/null; then
    sudo apt install -y gnome-tweaks gnome-shell-extensions gnome-shell-extension-appindicator
    ./config-gnome.sh
    mkdir -p "$HOME/bin"
    for file in "$HOME"/dotfiles/gnome/*; do
        ln -sf "$file" "$HOME/bin/$(basename "$file")"
    done
fi

# Install fonts
for font in "$HOME"/dotfiles/fonts/*.tar.gz; do
    name=$(basename "$font" | cut -d '.' -f 1)
    tar -xf "$font"
    sudo chown root:root ./*.ttf
    sudo mkdir -p "/usr/share/fonts/$name"
    sudo mv ./*.ttf "/usr/share/fonts/$name"
done

curl -sSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz -o nf-symbols.tar.xz
tar -xf nf-symbols.tar.xz --wildcards '*.ttf'
sudo chown root:root ./*.ttf
sudo mkdir -p /usr/share/fonts/nf-symbols
sudo mv ./*.ttf /usr/share/fonts/nf-symbols
rm -f nf-symbols.tar.xz

# Enable additional repos
sudo add-apt-repository -y universe multiverse restricted
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
sudo tee /etc/apt/sources.list.d/nodesource.list <<EOF
deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main
EOF
sudo apt update

# Remove bloat
sudo apt remove -y $(cat ./pkg.remove)
sudo snap remove firefox

# Install packages from repo
sudo apt install -y $(cat ./pkg.add)

# Build and install Neovim
OGPWD=$(pwd)
mkdir "$HOME/code"
cd "$HOME/code" || return
git clone https://github.com/neovim/neovim
cd neovim || return
git checkout stable
make CMAKE_BUILD_TYPE=Release
sudo make install
cd "$OGPWD" || return

# Install webi packages
webi_pkgs=(
    bat
    delta
    golang
    rg
    shellcheck
)
for pkg in "${webi_pkgs[@]}"; do
    curl -sS "https://webi.sh/$pkg" | sh
done

# Install fzf
curl -sSLo "$HOME/Downloads/setup/fzf.tar.gz" "$(curl -sSLH 'Accept: application/vnd.github+json' https://api.github.com/repos/junegunn/fzf/releases/latest | jq -r ".assets[] | select(.browser_download_url | match(\"linux_amd64.tar.gz$\")) | .browser_download_url")"
tar -xf "$HOME/Downloads/setup/fzf.tar.gz"
sudo mkdir -p /usr/local/bin
sudo install -o root -g root -m 755 fzf /usr/local/bin
rm -f fzf

# Set up interception-tools
git clone https://gitlab.com/interception/linux/tools.git interception-tools
cd interception-tools || return
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cp build/{intercept,mux,udevmon,uinput} /usr/local/bin
sed -i 's|/usr/bin/udevmon|/usr/local/bin/udevmon|' udevmon.service
sudo cp udevmon.service /usr/lib/systemd/system
sudo systemctl daemon-reload
cd ..
rm -rf interception-tools

# Set up caps2esc
git clone https://gitlab.com/interception/linux/plugins/caps2esc.git
cd caps2esc || return
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cp build/caps2esc /usr/local/bin
cd ..
rm -rf caps2esc

sudo mkdir -p /etc/interception/udevmon.d
sudo install -o root -g root -m 644 caps2esc.yaml /etc/interception/udevmon.d/caps2esc.yaml
sudo systemctl enable --now udevmon

# Install Firefox from Mozilla
curl -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-CA" -o "$HOME/Downloads/firefox.tar.bz2"
tar -xf "$HOME/Downloads/firefox.tar.bz2"
sudo rm -rf /opt/firefox
sudo chown -R root:root firefox
sudo mv firefox /opt/firefox
sudo mkdir -p /usr/local/bin
sudo ln -s /opt/firefox/firefox /usr/local/bin/firefox
sudo install -o root -g root -m 644 desktop-entries/firefox.desktop /usr/local/share/applications/firefox.desktop
rm -f "$HOME/Downloads/firefox.tar.bz2"
echo MOZ_ENABLE_WAYLAND=1 | sudo tee -a /etc/environment

# Install Brave browser
sudo curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg -o /usr/share/keyrings/brave-browser-archive-keyring.gpg
sudo tee /etc/apt/sources.list.d/brave-browser-release.list <<EOF
deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main
EOF
sudo apt update
sudo apt install -y brave-browser

# Install Google Chrome
curl -sSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o "$HOME/Downloads/setup/chrome.deb"
sudo apt install -yf "$HOME/Downloads/setup/chrome.deb"

# Install tfenv and Terraform
git clone --depth=1 https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
"$HOME/.tfenv/bin/tfenv" install latest
"$HOME/.tfenv/bin/tfenv" use latest

# Environment variables for HiDPI for Qt apps
sudo tee -a /etc/environment <<EOF
QT_AUTO_SCREEN_SCALE_FACTOR=1
QT_ENABLE_HIGHDPI_SCALING=1
EOF

# Add Insync repo and install
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ACCAF35C
sudo tee /etc/apt/sources.list.d/insync.list <<EOF
deb http://apt.insync.io/ubuntu $version_code non-free contrib
EOF
sudo apt update
sudo apt install -y insync
for filemgr in nautilus dolphin; do
    if command -v "$filemgr" &>/dev/null; then
        sudo apt install -y insync-"$filemgr"
    fi
done

# Install Zoom
curl -sSL https://zoom.us/client/latest/zoom_amd64.deb -o "$HOME/Downloads/setup/zoom.deb"
sudo apt install -yf "$HOME/Downloads/setup/zoom.deb"

# Install WezTerm
curl -sSLo "$HOME/Downloads/setup/wezterm.deb" "$(curl -sSLH 'Accept: application/vnd.github+json' https://api.github.com/repos/wez/wezterm/releases/latest | jq -r ".assets[] | select(.browser_download_url | match(\"Ubuntu$version_num.deb$\")) | .browser_download_url")"
sudo apt install -yf "$HOME/Downloads/setup/wezterm.deb"

# Clean up
rm -rf "$HOME/Downloads/setup"
