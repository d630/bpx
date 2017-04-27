#!/usr/bin/env bash
#
# bpx -- bash-pre-execution
# Copyright (C) 2015,2016f. D630, GNU GPLv3
# <https://github.com/D630/bpx>
#
# Forked from Ryan Caloras (ryan@bashhub.com)
# <https://github.com/rcaloras/bash-preexec>

# -- FUNCTIONS.

function __bpx_return {
    return $1;
};

function __bpx_postread {
    set -- $?;

    ((bpx_var[1] && ${#rl1[@]})) ||
        return $1;

    declare __;

    for __ in "${postread_functions[@]}"; do
        1>/dev/null declare -F "$__" ||
            continue;

        __bpx_return $1;

        bpx_var= rl1= rl2= rl3= "$__" ||
            break;
    done 1>&2;

    return $1;
};

function __bpx_precmd {
    set -- $?;

    declare __;

    for __ in "${precmd_functions[@]}"; do
        1>/dev/null declare -F "$__" ||
            continue;

         __bpx_return $1;

        bpx_var= rl1= rl2= rl3= "$__" ||
            break;
    done;

    return $1;
};

function __bpx_preexec {
    set -- $?;

    # Test, if *preread* and/or *postread* is hooking.
    # To avoid subshells, test also: 'BASHPID' -ne "$$"
    if
        [[ -v bpx_var[3] ]];
    then
        [[
            bpx_var[1] -eq 0 ||
            -v COMP_LINE ||
            -v READLINE_LINE ||
            -z "$rl2"
        ]] &&
            return 0;
    else
        [[ -v COMP_LINE || -v READLINE_LINE ]] &&
            return 0;
    fi;

    case $BASH_COMMAND in
        (''|__bpx_postread|__bpx_precmd|__bpx_return)
            return 0;;
    esac;

    case ${FUNCNAME[1]} in
        (__bpx_postread|__bpx_precmd|__bpx_return)
            return 0;;
    esac;

    case ${FUNCNAME[2]} in
        (__bpx_postread|__bpx_precmd|__bpx_return)
            return 0;;
    esac;

    bpx_var[2]+=1;

    # TODO(D630): HISTCMD and parameter transformation of \! expands always to
    # one, when they are running in a trap.
    # h='\!';
    # h="${h@P}";
    [[ bpx_var[2] -eq 1 && $SHELLOPTS == *history* ]] &&
        IFS=$' \t' read -r _ histcmd < <(
            HISTTIMEFORMAT= history 1;
        );

    declare __;

    for __ in "${preexec_functions[@]}"; do
        1>/dev/null declare -F "$__" ||
            continue;

        __bpx_return $1;

        bpx_var= histcmd=$histcmd BASH_COMMAND=$BASH_COMMAND "$__" ||
            break;
    done;
};

function __bpx_preread {
    declare __;

    for __ in "${preread_functions[@]}"; do
        1>/dev/null declare -F "$__" ||
            continue;

        __bpx_return ${bpx_var[3]};

        bpx_var= "$__" ||
            break;
    done 1>&2;
};

function __bpx_define_rl3 {
    IFS=$' \t\n' read -r -d '' -a rl3 <<< "${rl2[@]}";
};

function __bpx_read_line {
    bpx_var[bpx_var[1]=0,3]=$?;

    # If line buffer is empty, then test also, whether we're in the primary or
    # secondary prompt.
    ((${#rl0})) || {
        (((bpx_var-=1) < 0)) &&
            rl1=();

        return 1;
    };

    # Test, if history expansion has been performed.
    [[ $rl0 == "$READLINE_LINE" ]] || {
        bpx_var=bpx_var-=1;

        READLINE_LINE=$rl0;

        return 1;
    };

    if
        ((bpx_var));
    then
        rl1+=("$rl0");
    else
        rl1=("$rl0");
    fi;

    # TODO(D630): Find another way to figure out, whether the end of an input
    # line completes also the hole command line.
    # Each completed command line should only be evaluated once. But the
    # problem is to determine when a secondary prompt has finished. Thats is:
    # if the secondary prompt is used, one command line undergoes 1 +
    # + n evaluations.
    # One solution is to say: if the user calls keyseq x while in the secondary
    # prompt, then the command line is completed; if she calls keyseq y, then
    # we expect to read the next input line and to stay in the sec prompt.
    mapfile -t -s 2 rl2 < <(
        IFS=$'\n';

        # .  /dev/stdin <<< "";
        eval "
            function f {
                ${rl1[*]}
            } &&
                declare -f f;
        " 2>/dev/null;
    );

    ((${#rl2[@]})) ||
        return 1;

    unset -v rl2[-1];

    bpx_var[1]=1;
};

function __bpx_main {
    # internal integer indexed array variable *bpx_var*:
    # 0 number of the current input line; if gt zero, we are using the
    #   secondary prompt
    # 1 is one when complete command line has been read (no PS2 anymore)
    # 2 number of *BASH_COMMAND* in a command line
    # 3 last status code
    #
    # Don't mess around with it.

    unset -v \
        bpx_var \
        histcmd \
        postread_functions \
        preread_functions \
        rl0 \
        rl1 \
        rl2 \
        rl3;

    # unset -v \
    #     precmd_functions \
    #     preexec_functions;

    # declare -g -a \
    #     precmd_functions \
    #     preexec_functions;

    declare -g \
        histcmd \
        rl0;

    declare -g -a \
        postread_functions \
        preread_functions \
        rl1 \
        rl2 \
        rl3;

    declare -g -a -i bpx_var=(0 0 0);

    bind -x '"\C-x\C-x1": rl0=$READLINE_LINE';
    bind '"\C-x\C-x2": history-expand-line';

    bind -x '"\C-x\C-x3": __bpx_read_line';
    bind -x '"\C-x\C-x4": __bpx_read_line && __bpx_preread';

    bind '"\C-x\C-x5": accept-line';
    bind -x '"\C-x\C-x6": __bpx_postread';
};

# -- MAIN.

__bpx_main;

# -- TEST CONFIGURATION

# . src/bpx/test.bash;

# vim: set ts=4 sw=4 tw=0 et :
