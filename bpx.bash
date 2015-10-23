#!/usr/bin/env bash

# bpx -- bash-pre-execution
# Copyright (C) 2015 D630, GNU GPLv3
# <https://github.com/D630/bpx>

# Forked from Ryan Caloras (ryan@bashhub.com)
# <https://github.com/rcaloras/bash-preexec>
# Original by Glyph Lefkowitz

# -- FUNCTIONS.

__bpx_precmd ()
{
        X_BPX_ERR=$?

        typeset f

        for f in "${X_BPX_PRECMD_FUNC[@]}"
        do
                1>/dev/null typeset -F "$f" && {
                        ${f} "$X_BPX_ERR"
                }
        done

        wait

        X_BPX_INTERACTIVE_MODE=1
}

__bpx_preexec ()
if
        typeset c=$BASH_COMMAND
        [[
                $X_BPX_INTERACTIVE_MODE -eq 0 ||
                $c =~ __bpx_pre(cmd|exec) ||
                -n $COMP_LINE
        ]]
then
        return 0
else
        typeset \
                f \
                h1;
        ((
                X_BPX_INTERACTIVE_MODE =
                BASH_SUBSHELL == 0
                ? 1
                : 0
        ))
        if
                (( ${#X_BPX_PREEXEC_FUNC[@]} != 0 ))
        then
                read -r _ h1 < <(
                        HISTTIMEFORMAT= history 1
                )
                for f in "${X_BPX_PREEXEC_FUNC[@]}"
                do
                        1>/dev/null typeset -F "$f" && {
                                ${f} "$c" "$h1"
                        }
                done
                wait
        fi
fi

__bpx_main ()
if
        [[
                $PROMPT_COMMAND == __bpx_precmd ||
                -n $X_BPX_ERR
        ]]
then
        return 1
else
        unset -v \
                X_BPX_ERR \
                X_BPX_INTERACTIVE_MODE \
                X_BPX_PRECMD_FUNC \
                X_BPX_PREEXEC_FUNC \
                X_BPX_PROMPT_COMMAND_OLD;
        typeset -gi \
                X_BPX_ERR \
                X_BPX_INTERACTIVE_MODE=1;
        typeset -g X_BPX_PROMPT_COMMAND_OLD=$PROMPT_COMMAND
        unset -v PROMPT_COMMAND
        typeset -g PROMPT_COMMAND=__bpx_precmd
        typeset -ga \
                X_BPX_PRECMD_FUNC \
                X_BPX_PREEXEC_FUNC;
        shopt -u extdebug
        trap '__bpx_preexec' DEBUG
fi

# -- MAIN.

__bpx_main
