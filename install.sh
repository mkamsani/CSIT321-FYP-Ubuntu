#!/bin/sh -eux
# shellcheck shell=dash

#
# Non-interactive Ubuntu 22.04.3 LTS installation.
# This is the Ubuntu server variant:
# https://ubuntu.com/download/server
#

#echo () { printf "%s\n" "$*" ; }
fail() {
  echo "$*"
  exit 1
}

[ "$(id -u)" = "0" ] && fail "Do not run this script as root."
export echo
export fail
export source_patch
echo "Defaults timestamp_timeout=60" | sudo tee -a /etc/sudoers
cd "$(mktemp -d)" || fail "Could not cd to temporary directory."
cp ~/.profile ~/.profile.bak

# Update apt sources, install fetch packages.
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y  -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq apt-transport-https ca-certificates curl git gnupg gpg wget

# Create required directories.
mkdir -p \
  ~/.cache \
  ~/.config/git \
  ~/.config/zsh \
  ~/.config/helix \
  ~/.local/bin \
  ~/.local/share \
  ~/.local/state \
  ~/.local/share/go \
  ~/go

# Create required files.
touch \
  ~/.config/git/config \
  ~/.config/zsh/.zshrc \
  ~/.config/zsh/.zprofile \
  ~/.config/zsh/.zsh_history \
  ~/.config/helix/config.toml

# Update the default .profile with required environment variables.
cat >>~/.profile <<EOF
export XDG_CACHE_HOME=~/.cache
export XDG_CONFIG_HOME=~/.config
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state
export ZDOTDIR=~/.config/zsh
export EDITOR=nano
export VISUAL=nano
export PAGER=less
export MANPAGER='less -R -J --use-color -DSY -Du+G -S --mouse --wheel-lines=1'
export HISTSIZE=65536
export GOPROXY=direct
export GOSUMDB=off
export GOTELEMETRY=off
export GOTOOLCHAIN=local
EOF
BASH_VERSION=$(/usr/bin/bash -lc 'echo $BASH_VERSION')
. ~/.profile

#
# Add required repositories and install packages.
# https://code.visualstudio.com/docs/setup/linux
# https://docs.docker.com/engine/install/ubuntu/
# https://docs.helix-editor.com/install.html#ubuntu
# https://go.dev/doc/install
# https://www.rust-lang.org/tools/install
# https://github.com/nodesource/distributions#installation-instructions
#

# Add Helix (editor) repository.
sudo add-apt-repository --yes ppa:maveonair/helix-editor >/dev/null

# Add VSCode repository.
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Add Docker repository.
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

# Add Node.js repository.
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=18 # https://hyperledger.github.io/fabric-gateway/#compatibility
NODE_MAJOR=20 # https://hyperledger.github.io/fabric-gateway/#compatibility
export NODE_MAJOR
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

# -----------------------------------------------------------------------------

DOCKER_PACKAGES='docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras'
# Install apt packages.
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y jq zsh
echo 'VERY LONG COMMAND'

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  code helix $DOCKER_PACKAGES nodejs python3-venv python3-pip 

# Enable Docker.
sudo systemctl disable --now docker.service docker.socket
# TODO: Rootless Docker.
sudo systemctl enable --now docker.service docker.socket

# Handle required updates/restarts.
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y -qq --no-install-recommends ubuntu-advantage-tools
sudo systemctl restart dbus.service                  # NEEDRESTART-SVC: dbus.service               
sudo systemctl restart ModemManager.service          # NEEDRESTART-SVC: ModemManager.service       
sudo systemctl restart networkd-dispatcher.service   # NEEDRESTART-SVC: networkd-dispatcher.service
sudo systemctl restart packagekit.service            # NEEDRESTART-SVC: packagekit.service         
sudo systemctl restart polkit.service                # NEEDRESTART-SVC: polkit.service             
sudo systemctl restart ssh.service                   # NEEDRESTART-SVC: ssh.service                
sudo systemctl restart systemd-logind.service        # NEEDRESTART-SVC: systemd-logind.service     
sudo /etc/needrestart/restart.d/systemd-manager      # NEEDRESTART-SVC: systemd-manager            
sudo systemctl restart udisks2.service               # NEEDRESTART-SVC: udisks2.service            
sudo systemctl restart unattended-upgrades.service   # NEEDRESTART-SVC: unattended-upgrades.service
sudo systemctl restart user@1000.service             # NEEDRESTART-SVC: user@1000.service          

# Install Go.
_GOVERSION=go1.21.4
wget https://go.dev/dl/${_GOVERSION}.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf ${_GOVERSION}.linux-amd64.tar.gz

# Install Rust.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rustup_init.sh && chmod +x rustup_init.sh && ./rustup_init.sh -y --profile default

# Update the default .profile with required environment variables.
# shellcheck disable=SC2016
{
  echo 'export PATH="$PATH:/usr/local/go/bin"' ; # Go.
  echo 'export PATH="$HOME/.cargo/bin:$PATH"'  ; # Rust.
  echo 'export PATH="$HOME/.local/bin:$PATH"'  ; # User-installed binaries come first.
} >>~/.profile
. ~/.profile

# Configure Git.
git config --global user.name "$(whoami)"
git config --global user.email "$(whoami)@$(hostname)"
git config --global color.ui true
git config --global color.status.added "178"
git config --global color.status.changed "178"
git config --global color.status.untracked "39"
git config --global alias.graph "log --graph"
git config --global core.autocrlf false # https://hyperledger-fabric.readthedocs.io/en/release-2.5/prereqs.html
git config --global core.longpaths true # https://hyperledger-fabric.readthedocs.io/en/release-2.5/prereqs.html

# Configure zsh.
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
cat >>~/.config/zsh/.zshrc <<EOF
source ~/powerlevel10k/powerlevel10k.zsh-theme
alias ls='ls -AF --color=auto'
alias recent='ls -ltch'
alias chmod='chmod -c'
alias chown='chown -c'
alias cp='cp -iv'
alias grep='grep --color=auto'
alias ln='ln -v'
alias mkdir='mkdir -pv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
setopt beep nomatch interactivecomments hist_ignore_dups hist_ignore_space noflowcontrol
unsetopt autocd extendedglob notify
bindkey -e # emacs. -v for vi-style.
autoload -Uz compinit; compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' menu select=2
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion:*:descriptions' format '%U%F{cyan}%d%f%u'
zstyle ':completion:*' rehash true
EOF
echo 'source ~/.profile' >>~/.config/zsh/.zprofile
curl -o ~/.config/zsh/.p10k.zsh https://raw.githubusercontent.com/mkamsani/CSIT321-FYP-Ubuntu/main/.p10k.zsh

sudo sed -i '$d' /etc/sudoers
exit 0
