#!/usr/bin/env bash

set -e

EMAIL="williamlsh@protonmail.com"

echo "Install necessary packages"
sudo apt update
sudo apt install -y \
    zsh \
    screenfetch \
    htop \
    tmux \
    git \
    curl \
    lsof

echo "Set up default editor"
sudo update-alternatives --set editor /usr/bin/vim.basic

echo "Set up git"
git config --global user.name "William"
git config --global user.email $EMAIL
git config --global init.defaultBranch master

echo "Set up ssh keys"
ssh-keygen -q -t ed25519 -C $EMAIL -N '' <<<$'\ny' >/dev/null 2>&1
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

echo "Set up spacevim"
curl -sLf https://spacevim.org/install.sh | bash >/dev/null 2>&1

echo "Set up oh-my-zsh"
sudo chsh -s $(which zsh) $(whoami)
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting >/dev/null 2>&1
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions >/dev/null 2>&1
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions >/dev/null 2>&1
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search >/dev/null 2>&1
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-completions zsh-autosuggestions zsh-history-substring-search)/g' ~/.zshrc

echo "Set up powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k >/dev/null 2>&1
sed -i 's/_THEME=\"robbyrussell\"/_THEME=\"powerlevel10k\/powerlevel10k\"/g' ~/.zshrc

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

echo "Install tailscale"
# See: https://tailscale.com/kb/1147/cloud-gce/
curl -fsSL https://tailscale.com/install.sh | sh
# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
