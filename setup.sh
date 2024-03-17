#!/usr/bin/env bash

# Source bash config
cat >>"$HOME/.bashrc" <<'EOF'
[[ -f "$HOME/dotfiles/bash/.bash_common" ]] && . "$HOME/dotfiles/bash/.bash_common"
EOF

mkdir -p "$HOME/Downloads/setup"
. /etc/os-release

# Install required dependencies
sudo apt install -y ca-certificates curl git gnupg software-properties-common wget

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
  dest="$HOME/.local/share/fonts/$name"
  mkdir -p "$dest"
  tar -xf "$font" --directory="$dest"
done

# Enable additional repos
if [[ "$ID" == ubuntu ]]; then
  sudo add-apt-repository -y universe multiverse restricted
  sudo apt update
fi

# Remove bloat
# shellcheck disable=SC2046
sudo apt remove -y $(cat ./pkg.remove)
[[ "$ID" == ubuntu ]] && sudo snap remove firefox

# Install packages from repo
# shellcheck disable=SC2046
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
curl -sS https://webi.sh/webi | sh
# shellcheck disable=SC2046
webi $(cat ./webi.add)

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

# Set up Firefox APT repo from Mozilla
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null
echo 'deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main' | sudo tee -a /etc/apt/sources.list.d/mozilla.list >/dev/null

sudo tee /etc/apt/preferences.d/mozilla <<EOF
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
sudo apt update
sudo apt install -y firefox

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
deb http://apt.insync.io/$ID "${VERSION_CODENAME/\"//}" non-free contrib
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
curl -sSLo "$HOME/Downloads/setup/wezterm.deb" \
  "$(
    curl -sSLH 'Accept: application/vnd.github+json' https://api.github.com/repos/wez/wezterm/releases/latest \
      | jq -r \
        ".assets[] | select(.browser_download_url | match(\"${ID^}${VERSION_ID/\"//}.deb$\")) | .browser_download_url"
  )"
sudo apt install -yf "$HOME/Downloads/setup/wezterm.deb"

# Clean up
rm -rf "$HOME/Downloads/setup"
