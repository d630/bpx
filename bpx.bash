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

        builtin typeset f

        for f in "${X_BPX_PRECMD_FUNC[@]}"
        do
                1>/dev/null builtin typeset -F "$f" && {
                        ${f} "$X_BPX_ERR"
                }
        done

        builtin wait

        X_BPX_INTERACTIVE_MODE=1
}

__bpx_preexec ()
if
        builtin typeset c="$BASH_COMMAND"
        [[
                $X_BPX_INTERACTIVE_MODE -eq 0 ||
                $c =~ __bpx_pre(cmd|exec) ||
                -n $COMP_LINE
        ]]
then
        builtin return 0
else
        builtin typeset \
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
                builtin read -r _ h1 < <(
                        HISTTIMEFORMAT= builtin history 1
                )
                for f in "${X_BPX_PREEXEC_FUNC[@]}"
                do
                        1>/dev/null builtin typeset -F "$f" && {
                                ${f} "$c" "$h1"
                        }
                done
                builtin wait
        fi
fi

__bpx_main ()
if
        [[ $PROMPT_COMMAND == __bpx_precmd || -n $X_BPX_ERR ]]
then
        builtin return 1
else
        builtin unset -v \
                X_BPX_ERR \
                X_BPX_INTERACTIVE_MODE \
                X_BPX_PRECMD_FUNC \
                X_BPX_PREEXEC_FUNC \
                X_BPX_PROMPT_COMMAND_OLD;
        builtin typeset -gi \
                X_BPX_ERR \
                X_BPX_INTERACTIVE_MODE=1 \
                X_BPX_USE_PREEXEC=$X_BPX_USE_PREEXEC;
        builtin typeset -g +i X_BPX_PROMPT_COMMAND_OLD="$PROMPT_COMMAND"
        builtin unset -v PROMPT_COMMAND
        builtin typeset -g +i PROMPT_COMMAND=__bpx_precmd
        builtin typeset -g +i -a \
                X_BPX_PRECMD_FUNC="()" \
                X_BPX_PREEXEC_FUNC="()";
        (( X_BPX_USE_PREEXEC )) && {
                builtin shopt -u extdebug
                builtin trap '__bpx_preexec' DEBUG
        }
fi

# -- MAIN.

__bpx_main

# vim: set ts=8 sw=8 tw=0 et :
