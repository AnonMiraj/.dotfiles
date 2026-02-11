if status is-interactive
    # Starship custom prompt
    starship init fish | source

    # Direnv + Zoxide
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

    # Better ls
    alias ls='eza --icons --group-directories-first -1'

    # Abbrs
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end
end

function set_kitty_colors
    set color_file ~/.cache/ags/user/generated/kitty-colors.conf
    if test -f $color_file
        kitty @ set-colors --all --configured $color_file
    else
        echo "Color scheme file not found: $color_file"
    end
end

alias pamcan=pacman
export EDITOR=nvim
export VISUAL=nvim

fish_vi_key_bindings
# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")

    set paths
    for arg in $argv
        if string match -q 'file://*' $arg
            set paths $paths (string replace -r '^file://' '' $arg)
        else
            set paths $paths $arg
        end
    end

    yazi $paths --cwd-file="$tmp"

    if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end

    rm -f -- "$tmp"
end

fzf --fish | source

function edit_cmdline_in_nvim
    set -l tmpfile (mktemp)
    commandline > $tmpfile
    $EDITOR $tmpfile > /dev/null 2>&1
    commandline -r (string trim --right (cat $tmpfile))
    rm -f $tmpfile > /dev/null 2>&1
end

bind \ce edit_cmdline_in_nvim

zoxide init fish | source

