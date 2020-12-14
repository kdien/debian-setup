#!/bin/bash
mkdir -p $HOME/Downloads/temp
version_num=$(grep VERSION_ID /etc/os-release | cut -d "=" -f 2 | sed -e s/\"//g)
version_code=$(grep UBUNTU_CODENAME /etc/os-release | cut -d "=" -f 2)

# Enable additional repos
sudo add-apt-repository universe -y
sudo add-apt-repository ppa:mmstick76/alacritty -y
sudo add-apt-repository ppa:teejee2008/timeshift -y
sudo apt update

# Configure GNOME settings
[[ "$XDG_CURRENT_DESKTOP" == *GNOME* ]] && sudo apt install gnome-tweaks gnome-extensions-app -y && ./config-gnome.sh

# Install required tools for automation
sudo apt install software-properties-common curl wget git -y

# Get pureline bash prompt
git clone https://github.com/chris-marsh/pureline.git $HOME/pureline

# Setup bash symlinks
[[ -f $HOME/.bashrc ]] && mv $HOME/.bashrc $HOME/.bashrc.bak
ln -sf $HOME/ubuntu-setup/bash/.bashrc $HOME/.bashrc
ln -sf $HOME/ubuntu-setup/bash/.bash_aliases $HOME/.bash_aliases
ln -sf $HOME/ubuntu-setup/bash/.bash_functions $HOME/.bash_functions

# Clone dotfiles and setup symlinks
git clone https://github.com/kdien/dotfiles.git $HOME/dotfiles
ln -sf $HOME/dotfiles/tmux/.tmux.conf $HOME/.tmux.conf
ln -sf $HOME/dotfiles/vim/.vimrc $HOME/.vimrc
ln -sf $HOME/dotfiles/alacritty $HOME/.config/alacritty
ln -sf $HOME/dotfiles/pureline/.pureline.conf $HOME/.pureline.conf

# Extract Meslo fonts
mkdir -p $HOME/.fonts/meslo-nf
tar -xzvf meslo-nf.tar.gz -C $HOME/.fonts/meslo-nf

# Remove bloat
sudo apt remove $(cat ./pkg.remove) -y

# Install packages from repo
sudo apt install $(cat ./pkg.add) -y

# Install snap packages
cat snap.add | while read snap; do sudo snap install "$snap"; done

# Install MS Edge
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge-dev.list
sudo rm microsoft.gpg
sudo apt update
sudo apt install microsoft-edge-dev -y

# Install Google Chrome
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O $HOME/Downloads/temp/chrome.deb 
sudo apt install $HOME/Downloads/temp/chrome.deb -y

# Add VS Code repo and install
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install code -y

# Add Insync repo and install
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ACCAF35C
echo "deb http://apt.insync.io/ubuntu $version_code non-free contrib" | sudo tee /etc/apt/sources.list.d/insync.list
sudo apt update
sudo apt install insync insync-nautilus -y

# Add Spotify repo and install
curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | sudo apt-key add - 
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

# Install Viber
wget -q https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb -O $HOME/Downloads/temp/viber.deb 
sudo apt install $HOME/Downloads/temp/viber.deb -y

# Install Zoom
wget -q https://zoom.us/client/latest/zoom_amd64.deb -O $HOME/Downloads/temp/zoom.deb
sudo apt install $HOME/Downloads/temp/zoom.deb -y

# Clean up
rm -rf $HOME/Downloads/temp

