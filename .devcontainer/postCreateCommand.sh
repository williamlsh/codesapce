#!/usr/bin/env bash

set -e

EMAIL="williamlsh@protonmail.com"
MOLD_VERSION="v1.5.1"
GO_VERSION="1.19.2"

# Set up default editor
echo "Set up default editor"
sudo update-alternatives --set editor /usr/bin/vim.basic

# Set up zsh
echo "Set up zsh"
sudo chsh -s $(which zsh) $(whoami)

# Set up git
echo "Set up git"
git config --global user.name "William"
git config --global user.email $EMAIL
git config --global init.defaultBranch master

# Set up ssh keys
echo "Set up ssh keys"
ssh-keygen -q -t ed25519 -C $EMAIL -N '' <<<$'\ny' >/dev/null 2>&1
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Set up spacevim
echo "Set up spacevim"
curl -sLf https://spacevim.org/install.sh | bash >/dev/null 2>&1

# Set up oh-my-zsh plugins
echo "Set up oh-my-zsh plugins"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting >/dev/null 2>&1
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions >/dev/null 2>&1
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions >/dev/null 2>&1
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search >/dev/null 2>&1
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-completions zsh-autosuggestions zsh-history-substring-search)/g' ~/.zshrc

# Set up powerlevel10k
echo "Set up powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k >/dev/null 2>&1
sed -i 's/_THEME=\"codespaces\"/_THEME=\"powerlevel10k\/powerlevel10k\"/g' ~/.zshrc

# Set up tmux
echo "Set up tmux"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm >/dev/null 2>&1
cat <<'EOF' >~/.tmux.conf
set -g default-terminal "screen-256color"

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

set -g @continuum-restore 'on'

# Other examples:
# set -g @plugin 'github_username/plugin_name'
# set -g @plugin 'git@github.com:user/plugin'
# set -g @plugin 'git@bitbucket.com:user/plugin'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
EOF

# Set up docker
echo "Set up docker"
sudo apt-get update
sudo apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Set up rust
echo "Set up rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env

# Set up mold
echo "Set up mold"
git clone https://github.com/rui314/mold.git >/dev/null 2>&1
mkdir mold/build
pushd mold/build
git checkout ${MOLD_VERSION}
sudo ../install-build-deps.sh
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=c++ ..
cmake --build . -j $(nproc)
sudo cmake --install .
popd && rm -rf mold
cat <<EOF >~/.cargo/config.toml
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=$(which mold)"]
EOF

# Install just
echo "Install just"
cargo install -q just

# Set up Go
curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
echo PATH=$PATH:/usr/local/go/bin:$HOME/go/bin >> $HOME/.zshrc
rm "go${GO_VERSION}.linux-amd64.tar.gz"

zsh -c "source ~/.zshrc"
