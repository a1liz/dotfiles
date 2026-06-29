#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
info()  { echo -e "${CYAN}==>${NC} $*"; }
ok()    { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${RED}==>${NC} $*"; }

prompt() {
    read -rp "$(echo -e "${CYAN}==>${NC} $* [y/N] ")" yn
    case $yn in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# ── system: zsh ───────────────────────────────────────

install_zsh_pkg() {
    if command -v zsh &>/dev/null; then
        ok "zsh already installed: $(zsh --version)"
        return
    fi

    info "Installing zsh..."

    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y zsh
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y zsh
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm zsh
    elif command -v brew &>/dev/null; then
        brew install zsh
    else
        warn "Unsupported package manager. Install zsh manually and re-run."
        exit 1
    fi

    ok "zsh installed"
}

set_default_shell() {
    local zsh_bin
    zsh_bin="$(which zsh)"

    if [ "$SHELL" = "$zsh_bin" ]; then
        ok "Default shell is already zsh"
        return
    fi

    if prompt "Change default shell to $zsh_bin?"; then
        chsh -s "$zsh_bin"
        ok "Default shell changed to zsh (re-login to take effect)"
    fi
}

# ── oh-my-zsh ─────────────────────────────────────────

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        ok "oh-my-zsh already installed"
        return
    fi

    info "Installing oh-my-zsh..."
    if command -v curl &>/dev/null; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    ok "oh-my-zsh installed"
}

# ── zsh plugins & theme ───────────────────────────────

install_zsh_extras() {
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        info "Installing powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
        ok "powerlevel10k installed"
    else
        ok "powerlevel10k already installed"
    fi

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        ok "zsh-autosuggestions installed"
    else
        ok "zsh-autosuggestions already installed"
    fi

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        ok "zsh-syntax-highlighting installed"
    else
        ok "zsh-syntax-highlighting already installed"
    fi
}

# ── dotfiles symlinks ─────────────────────────────────

deploy_dotfiles() {
    info "Deploying dotfiles..."

    local backup_suffix=".backup.$(date +%Y%m%d-%H%M%S)"

    for target in "$HOME/.zshrc" "$HOME/.my_zshrc" "$HOME/.tmux.conf"; do
        if [ -f "$target" ] && [ ! -L "$target" ]; then
            cp "$target" "${target}${backup_suffix}"
            warn "Backed up existing $target → ${target}${backup_suffix}"
        fi
    done

    ln -sf "$DOTFILES/zsh/zshrc"      "$HOME/.zshrc"
    ln -sf "$DOTFILES/zsh/my_zshrc"   "$HOME/.my_zshrc"
    ln -sf "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

    ok "Dotfiles symlinked"
}

# ── tmux ──────────────────────────────────────────────

install_tmux_extras() {
    if [ ! -f "$HOME/.tmux.conf" ]; then
        return
    fi

    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        info "Installing tpm..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        ok "tpm installed"
    else
        ok "tpm already installed"
    fi

    if [ -f "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
        info "Installing tmux plugins..."
        "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
    fi
}

# ── local secrets ─────────────────────────────────────

setup_local() {
    if [ -f "$HOME/.zshrc.local" ]; then
        ok "~/.zshrc.local already exists, skipping"
        return
    fi

    info "Creating ~/.zshrc.local for machine-specific config..."
    cat > "$HOME/.zshrc.local" <<'EOF'
# Machine-specific config — NOT tracked by git
# Paths, secrets, toolchains, locale go here.

# ── tools ─────────────────────────────────────────────
# export PATH="$PATH:/opt/nvim-linux64/bin"
# [ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"

# ── conda ─────────────────────────────────────────────
# ... conda initialize block ...

# ── locale ────────────────────────────────────────────
# export LANG=en_US.UTF-8

# ── secrets ───────────────────────────────────────────
# export ANTHROPIC_AUTH_TOKEN=sk-...

EOF
    warn "Edit ~/.zshrc.local to add your machine-specific config."
}

# ── p10k template ──────────────────────────────────────

setup_p10k() {
    if [ -f "$HOME/.p10k.zsh" ]; then
        ok "~/.p10k.zsh already exists, skipping"
        return
    fi

    info "Copying p10k template to ~/.p10k.zsh..."
    cp "$DOTFILES/zsh/p10k.zsh" "$HOME/.p10k.zsh"
    ok "p10k template copied — run 'p10k configure' to customize for this machine"
}

# ── main ───────────────────────────────────────────────

echo ""
info "dotfiles installer"
info "------------------"
echo ""

install_zsh_pkg
echo ""
install_oh_my_zsh
echo ""
set_default_shell
echo ""
install_zsh_extras
echo ""
deploy_dotfiles
echo ""
setup_p10k
echo ""
install_tmux_extras
echo ""
setup_local

echo ""
ok "All done!"
echo ""
echo "  Next steps:"
echo "    1. Re-login or run: exec zsh"
echo "    2. Run 'p10k configure' to customize your prompt for this machine"
echo "    3. Edit ~/.zshrc.local to add machine-specific secrets"
echo "    4. In tmux: prefix + I to install plugins"
echo ""
