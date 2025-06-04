function set_kitty_colors
    set color_file ~/.cache/ags/user/generated/kitty-colors.conf
    if test -f $color_file
        kitty @ set-colors --all --configured $color_file
    else
        echo "Color scheme file not found: $color_file"
    end
end


if status is-interactive
    set fish_greeting
    
    # Only run starship init if it exists
    # type -q starship; and starship init fish | source

    # Only try to read sequences if the file exists
    # set -l seq_file ~/.cache/ags/user/generated/terminal/sequences.txt
    # if test -f $seq_file
    #     cat $seq_file
    # end
end

starship init fish | source
# if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
#     cat ~/.cache/ags/user/generated/terminal/sequences.txt
# end

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
	yazi $argv --cwd-file="$tmp"
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



# Your aliases here
alias pamcan=pacman
alias settings="gjs ~/.config/ags/assets/settings.js"
alias bar="nvim ~/.config/ags/modules/bar/main.js"
alias barmodes="nvim ~/.config/ags/modules/bar/modes"
alias config="nvim ~/.ags/config.json"
alias default="micro ~/.config/ags/modules/.configuration/user_options.default.json"
alias colors="kitty @ set-colors -a -c ~/.cache/ags/user/generated/kitty-colors.conf"
