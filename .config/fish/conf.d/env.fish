
if test -d "$HOME/.local/bin"
    for dir in (find $HOME/.local/bin -type d)
        set -gx PATH $PATH $dir
    end
end


# Default programs:
export EDITOR="nvim"
export TERMINAL="kitty"
export TERMINAL_PROG="kitty"
export BROWSER="zen-browser"
export READER="zathura"
export FILE="lf"

# ~/ Clean-up:
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export WINEPREFIX=/home/nir/.local/share/wineprefixes/default 
export WINEDLLPATH="/usr/lib/wine/x86_64-unix wine64"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export GOPATH="$XDG_DATA_HOME/go"
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"

export FZF_DEFAULT_OPTS="--layout=reverse --height 40%"
export LANG="en_US.UTF-8"
export LESS=-R
export LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"
export LESS_TERMCAP_md="$(printf '%b' '[1;36m')"
export LESS_TERMCAP_me="$(printf '%b' '[0m')"
export LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"
export LESS_TERMCAP_se="$(printf '%b' '[0m')"
export LESS_TERMCAP_us="$(printf '%b' '[1;32m')"
export LESS_TERMCAP_ue="$(printf '%b' '[0m')"
export LESSOPEN="| /usr/bin/highlight -O ansi %s 2>/dev/null"


# TSP settings
# https://aur.archlinux.org/packages/task-spooler/
export TS_SLOTS=10		# the maximum number of jobs running at once with task-spooler.
export TS_ONFINISH=tsp_onfinish	# run by the client after the  queued  job.

