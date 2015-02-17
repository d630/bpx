#!/usr/bin/env bash

# bpx -- bash-pre-execution
# Copyright (C) 2015 D630, GNU GPLv3
# <https://github.com/D630/bpx>

# Forked from Ryan Caloras (ryan@bashhub.com)
# <https://github.com/rcaloras/bash-preexec>
# original by Glyph Lefkowitz

# -- FUNCTIONS.

__bpx_precmd ()
{
    declare f=
    for f in "${X_BPX_PRECMD_FUNC[@]}"
    do
        declare -F "$f" 1>/dev/null && $f
    done
    X_BPX_INTERACTIVE_MODE=on
}

__bpx_preexec ()
if [[ $COMP_LINE || -z $X_BPX_INTERACTIVE_MODE || $BASH_COMMAND == __bpx_prompt ]]
then
    return 0
else
    ((BASH_SUBSHELL == 0)) && X_BPX_INTERACTIVE_MODE=
    declare h1=
    read -r _ h1 < <(HISTTIMEFORMAT= history 1)
    [[ $h1 ]] || return 0
    declare f=
    for f in "${X_BPX_PREEXEC_FUNC[@]}"
    do
        declare -F "$f" 1>/dev/null && $f "$h1"
    done
fi

__bpx_prompt () { return "$?" ; }

__bpx_main ()
if [[ $PROMPT_COMMAND == __bpx_prompt\;*__bpx_precmd\; ]]
then
    return 1
else
    shopt -u extdebug
    declare -g \
        X_BPX_INTERACTIVE_MODE= \
        X_BPX_PROMPT_COMMAND_OLD=$PROMPT_COMMAND \
        PROMPT_COMMAND="__bpx_prompt;${PROMPT_COMMAND%%;}${PROMPT_COMMAND:+;}__bpx_precmd;"
    declare -ga \
        X_BPX_PRECMD_FUNC=() \
        X_BPX_PREEXEC_FUNC=()
    trap '__bpx_preexec' DEBUG
fi

# -- MAIN.

__bpx_main
