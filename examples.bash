#!/usr/bin/env bash

# TODO(D630: finish etc.


function preread1 {
    _[2]=$(
        shellcheck \
            --color=always \
            --format=tty \
            --shell=bash - <<< "$rl0";
    ) || {
        echo "${_[2]}";
        __bpx_read_abort;
    };
};
preread_functions=(preread1);

function preread2 {
    xsel \
        -l /dev/null \
        --primary \
        --input \
        <<< "$rl0" >/dev/null 2>&1;
};
preread_functions=(preread2);

function preread3 {
    READLINE_LINE=$(shfmt <<< "$rl0");
};
preread_functions=(preread3);

function preread4 {
    READLINE_LINE=$(declare -f __bpx_command_line);
    __bpx_read_abort;
};
preread_functions=(preread4);

function preread5 {
    declare -f __bpx_command_line |
    # pygmentize -l bash;
    source-highlight \
        --failsafe \
        -f esc256 \
        -o STDOUT \
        --tab=4 \
        --line-number=0 \
        --lang-def=sh.lang \
        --style-file=esc256.style;
    echo;
    __bpx_read_abort;
};
preread_functions=(preread5);

function preread6 {
    READLINE_LINE="time $rl0";
};
preread_functions=(preread6);

function preread7 { set -v; set -x; };
function postread1 { set +v; set +x; };
preread_functions=(preread7);
postread_functions=(postread1);

function postread2 {
    local h;
    printf -v h %\*s $COLUMNS '';
    printf %s\\n ${h// /-};
};
postread_functions=(postread2);

function preread8 { tput cup 0 0; tput ed; };
preread_functions=(preread8);

bind 'set emacs-mode-string ""';
PS1='${_[bpx_var=0, bpx_var[2]=0, 1]}> ';

function preread9 { tput cup 2 0; tput ed; };
preread_functions=(preread9);

ps1b='\#,\! \t';
ps1c='\u@\h:\w';

function postread3 {
    ps1a="($?)";
    tput sc; tput cup 0 0;
    printf "${ps1a}%*s\n%s" "$((COLUMNS - ${#ps1a}))" "${ps1b@P}" "${ps1c@P}";
    tput rc;
};
postread_functions=(postread3 postread2);

# vim: set ts=2 sw=2 tw=0 noet :
