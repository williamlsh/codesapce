#!/usr/bin/env bash

set -e

EMAIL="williamlsh@protonmail.com"
MOLD_VERSION="2.32.1"
HELIX_VERSION="24.07"
GO_VERSION="1.22.0"

sudo apt-get update && sudo apt-get upgrade -y

# Set up zsh
echo "Set up zsh"
sudo chsh -s $(which zsh) $(whoami)

# Set up git
echo "Set up git"
git config --global user.name "William"
git config --global user.email $EMAIL
git config --global init.defaultBranch master
git config --global core.editor hx

# Set up ssh keys
echo "Set up ssh keys"
ssh-keygen -q -t ed25519 -C $EMAIL -N '' <<<$'\ny' >/dev/null 2>&1
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

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
sed -i 's/_THEME=\"devcontainers\"/_THEME=\"powerlevel10k\/powerlevel10k\"/g' ~/.zshrc

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

# Set up rust
echo "Set up rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env

# Set up mold
echo "Set up mold"
curl -sL "https://github.com/rui314/mold/releases/download/v${MOLD_VERSION}/mold-${MOLD_VERSION}-x86_64-linux.tar.gz" | tar -xvz
sudo mv "mold-${MOLD_VERSION}-x86_64-linux" /usr/local/mold
cat <<EOF >~/.cargo/config.toml
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=/usr/local/mold/bin/mold"]
EOF

# Install just
echo "Install just\n"
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin

# Install Helix editor
echo "Install Helix editor\n"
curl -sL "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-x86_64-linux.tar.xz" | tar -xJ
pushd "helix-${HELIX_VERSION}-x86_64-linux"
sudo mv hx /usr/local/bin/
mkdir -p $HOME/.config/helix && mv runtime $HOME/.config/helix
popd
rm -rf "helix-${HELIX_VERSION}-x86_64-linux"
cat <<EOF >~/.config/helix/config.toml
theme = "onedark"

[editor]
line-number = "relative"
mouse = false
auto-save = true

[editor.cursor-shape]
insert = "bar"
normal = "bar"
select = "underline"

[editor.file-picker]
hidden = false
EOF
rustup component add rust-analyzer

# Set up Go
curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm "go${GO_VERSION}.linux-amd64.tar.gz"

# Setup path environment variable
echo PATH=\$PATH:/usr/local/mold/bin:/usr/local/go/bin:$HOME/go/bin >>~/.zshrc
zsh -c "source ~/.zshrc"
