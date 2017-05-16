#!/usr/bin/env bash
#
# bpx -- bash-pre-execution
# Copyright (C) 2015,2016f. D630, GNU GPLv3
# <https://github.com/D630/bpx>
#
# Forked from Ryan Caloras (ryan@bashhub.com)
# <https://github.com/rcaloras/bash-preexec>

# -- FUNCTIONS.

## -- HOOKS.

function __bpx_hook_debug {
    set -- $?;

    # Test, if *preread*, *preexec* and *postread* is hooking.
    # To avoid subshells, test also: 'BASHPID' -ne "$$"
    if
        [[ -v bpx_var[3] ]];
    then
        [[
            bpx_var[1] -eq 0 ||
            -v COMP_LINE ||
            -v READLINE_LINE ||
            -z "$rl0"
        ]] &&
            return 0;
    else
        [[ -v COMP_LINE || -v READLINE_LINE ]] &&
            return 0;
    fi;

    case $BASH_COMMAND in
        (''|__bpx_hook_postread|*__bpx_hook_prompt|*__bpx_return)
            return 0;;
    esac;

    case ${FUNCNAME[1]} in
        (__bpx_hook_postread|*__bpx_hook_prompt|*__bpx_return)
            return 0;;
    esac;

    case ${FUNCNAME[2]} in
        (__bpx_hook_postread|*__bpx_hook_prompt|*__bpx_return)
            return 0;;
    esac;

    bpx_var[2]+=1;

    declare +x __;

    # TODO(D630): HISTCMD and parameter transformation of \! expands always to
    # one, when they are running in a trap.
    # h='\!';
    # h="${h@P}";
    [[ bpx_var[2] -eq 1 && -o history ]] &&
        IFS=$' \t' read -r _ histcmd < <(
            HISTTIMEFORMAT= history 1;
        );

    for __ in "${debug_functions[@]}"; do
        > /dev/null declare -F "$__" ||
            continue;

        \__bpx_return $1;

        histcmd=$histcmd "$__" ||
            break;
    done;
};

function __bpx_hook_postread {
    set -- $?;

    declare +x __;

    ((bpx_var[1] && ${#rl0})) ||
        return $1;

    for __ in "${postread_functions[@]}"; do
        > /dev/null declare -F "$__" ||
            continue;

        \__bpx_return $1;

        "$__" ||
            break;
    done 1>&2;

    return $1;
};

function __bpx_hook_preexec {
    declare +x \
     READLINE_LINE= \
     READLINE_POINT= \
     __ \
     rl0=$rl0;

    for __ in "${preexec_functions[@]}"; do
        > /dev/null declare -F "$__" ||
            continue;

        \__bpx_return ${bpx_var[3]};

        "$__" ||
            break;
    done 1>&2;
};

function __bpx_hook_preread {
    declare +x \
     __ \
     rl0=$rl0;

    for __ in "${preread_functions[@]}"; do
        > /dev/null declare -F "$__" ||
            continue;

        \__bpx_return ${bpx_var[3]};

        "$__" ||
            break;
    done 1>&2;
};

function __bpx_hook_prompt {
    set -- $?;

    declare +x __;

    for __ in "${prompt_functions[@]}"; do
        > /dev/null declare -F "$__" ||
            continue;

         \__bpx_return $1;

        "$__" ||
            break;
    done;

    return $1;
};


## -- MISC.

function __bpx_command_line {
    :;
};

function __bpx_edit {
    command vim -f \
     '+set ft=sh' \
     "+call cursor(1,$READLINE_POINT+1)" \
     "${1?}" < /dev/tty > /dev/tty;
};

function __bpx_edit_and_execute_command {
    READLINE_LINE=$(
        n=${TMPDIR:-/tmp}/bash-bpx.$RANDOM;
        printf '%s\n' "$rl0" > "$n";
        command chmod 600 "$n" > /dev/null 2>&1;

        __bpx_edit "$n";

        if
            command cmp -s <(printf '%s\n' "$rl0") "$n";
        then
            printf '%s\n' "$rl0";
            exit 1;
        else
            command cat "$n" 2>&1;
        fi;
    );
};

function __bpx_set_binds {
    set -o emacs;

    bind '"\C-x\C-x1": "\C-x\C-x2\C-x\C-x6"';

    bind '"\C-x\C-x2": "\C-x\C-x3\C-x\C-x4\C-x\C-x5"';
    bind -x '"\C-x\C-x3": rl0=$READLINE_LINE';
    bind '"\C-x\C-x4": history-expand-line';
    bind -x '"\C-x\C-x5": \__bpx_read_line && {
            \__bpx_hook_preread;
            \__bpx_hook_preexec;
        };
    ';

    bind '"\C-x\C-x6": "\C-x\C-x7"';

    bind '"\C-x\C-x7": "\C-x\C-x8\C-x\C-x9"';
    bind '"\C-x\C-x8": accept-line';
    bind -x '"\C-x\C-x9": \__bpx_hook_postread';
};

function __bpx_set_rl1 {
    mapfile -t -s 2 rl1 < <(
        declare -f __bpx_command_line 2> /dev/null;
    );

    ((${#rl1[@]})) ||
        return 0;

    unset -v rl1[-1];
};

function __bpx_set_rl2 {
    ((${#rl1[@]})) ||
        \__bpx_set_rl1 ||
            return 0;

    IFS=$' \t\n' read -r -d '' -a rl2 <<< "${rl1[@]}";
};

function __bpx_read_abort {
    bpx_var=1;
    bind '"\C-x\C-x8": abort';
};

function __bpx_read_accept {
    bpx_var=0;
    bind '"\C-x\C-x6": "\C-x\C-x7"';
    bind '"\C-x\C-x8": accept-line';
};

function __bpx_read_again {
    bpx_var=1;
    bind '"\C-x\C-x6": "\C-x\C-x1"';
};

function __bpx_read_line {
    bpx_var[bpx_var[1]=0,3]=$?;

    ((bpx_var)) &&
        \__bpx_read_accept;

    ((${#rl0})) ||
        return 1;

    # Test, if history expansion has been performed.
    [[ $rl0 != "$READLINE_LINE" && -o histexpand ]] &&
            READLINE_LINE=$rl0 &&
                return 1;

    #source <()
    #bash -n
    # TODO(D630)
    eval "
        function __bpx_command_line {
            $rl0
        };
    " 2> /dev/null ||
        if
            \__bpx_edit_and_execute_command;
        then
            \__bpx_read_again;
            return 1;
        else
            \__bpx_read_abort;
            return 1;
        fi;

    bpx_var[1]=1;
};

function __bpx_return {
    return $1;
};

# -- MAIN.

function __bpx_main {
    # internal integer indexed array variable *bpx_var*:
    # 0 is one when command line isn't valid
    # 1 is one when complete command line has been read
    # 2 number of *BASH_COMMAND* in a command line (*debug*)
    # 3 last status code
    #
    # Don't mess around with it.

    unset -v \
        bpx_var \
        histcmd \
        debug_functions \
        postread_functions \
        preexec_functions \
        preread_functions \
        prompt_functions \
        rl0 \
        rl1 \
        rl2;

    declare -g \
        histcmd \
        rl0;

    declare -g -a \
        debug_functions \
        postread_functions \
        preexec_functions \
        preread_functions \
        prompt_functions \
        rl1 \
        rl2;

    declare -g -a -i bpx_var=(0 0 0);

    \__bpx_set_binds;
};

\__bpx_main;

# -- TEST CONFIGURATION

#. src/bpx/test.bash;

# vim: set ts=4 sw=4 tw=0 et :

