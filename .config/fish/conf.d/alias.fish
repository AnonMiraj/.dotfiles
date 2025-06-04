# Use neovim for vimdiff if present
if type -q nvim
    alias vimdiff='nvim -d'
end

# Use $XINITRC if file exists
if test -f "$XINITRC"
    alias startx="startx $XINITRC"
end

# Custom mbsync config
if test -f "$MBSYNCRC"
    alias mbsync="mbsync -c $MBSYNCRC"
end

# Use sudo with system commands
for command in mount umount sv pacman updatedb su shutdown poweroff reboot
    alias $command="sudo $command"
end

# Function to edit scripts from ~/.local/bin
function se
    set choice (find ~/.local/bin -mindepth 1 -printf '%P\n' | fzf)
    if test -f "$HOME/.local/bin/$choice"
        $EDITOR "$HOME/.local/bin/$choice"
    end
end

# Sensible default flags
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -vI"
alias bc="bc -ql"
alias rsync="rsync -vrPlu"
alias mkd="mkdir -pv"
alias yt="yt-dlp --embed-metadata -i"
alias yta="yt -x -f bestaudio/best"
alias ytt="yt --skip-download --write-thumbnail"
alias ffmpeg="ffmpeg -hide_banner"
alias :q="exit"

# Colorized and enhanced commands
alias ls="eza -a --icons --group-directories-first"
alias ll="eza -al --icons"
alias lt="eza -a --tree --level=1 --icons"
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias ccat="highlight --out-format=ansi"
alias ip="ip -color=auto"

# Abbreviations for long commands
alias ka="killall"
alias g="git"
alias trem="transmission-remote"
alias YT="youtube-viewer"
alias p="paru -S"
alias ps="paru -Ss"
alias prns="paru -Rns"
alias pr="paru -R"
alias z="zathura"

# Misc
alias genpasswd="openssl rand -base64 21"
alias pom="tatsumato -d -t 20 -b 4 -l 8"
alias opennewterm="kitty >/dev/null 2>&1 & disown"
