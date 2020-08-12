#!/bin/bash
mkdir -p ~/Downloads/temp
version_num=$(grep VERSION_ID /etc/os-release | cut -d "=" -f 2 | sed -e s/\"//g)
version_code=$(grep UBUNTU_CODENAME /etc/os-release | cut -d "=" -f 2)

# Configure GNOME settings
[[ $XDG_CURRENT_DESKTOP == 'GNOME' ]] && ./config-gnome.sh

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

# Symlink fontconfig
rm -rf $HOME/.config/fontconfig
ln -s $HOME/dotfiles/fontconfig $HOME/.config/fontconfig

# Enable additional repos
sudo add-apt-repository ppa:mmstick76/alacritty -y
sudo add-apt-repository ppa:teejee2008/timeshift -y
sudo apt update

# Remove bloat
sudo apt remove $(cat ./pkg.remove) -y
#sudo snap remove $(cat ./snap.remove)

# Install packages from repo
sudo apt install $(cat ./pkg.add) -y

# Install Google Chrome
wget -q -O ~/Downloads/temp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ~/Downloads/temp/chrome.deb -y

# Add VS Code repo and install
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > ~/Downloads/temp/packages.microsoft.gpg
sudo install -o root -g root -m 644 ~/Downloads/temp/packages.microsoft.gpg /usr/share/keyrings/
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install apt-transport-https code -y

# Add Insync repo and install
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ACCAF35C
echo "deb http://apt.insync.io/ubuntu $version_code non-free contrib" | sudo tee /etc/apt/sources.list.d/insync.list
sudo apt update
sudo apt install insync insync-dolphin -y

# Install Viber
wget -q -O ~/Downloads/temp/viber.deb https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb
sudo apt install ~/Downloads/temp/viber.deb -y

# Clean up
rm -rf ~/Downloads/temp

