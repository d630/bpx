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
        BPX_ERR=$?

        builtin typeset f

        for f in "${BPX_PRECMD_FUNC[@]}"
        do
                1>/dev/null builtin typeset -F "$f" && {
                        ${f} "$BPX_ERR"
                }
        done

        #builtin wait

        BPX_INTERACTIVE_MODE=1
}

__bpx_preexec ()
if
        builtin typeset c="$BASH_COMMAND"
        [[
                $BPX_INTERACTIVE_MODE -eq 0 ||
                $c =~ ^__bpx_pre(cmd|exec)$ ||
                -n $COMP_LINE
        ]]
then
        builtin return 0
else
        builtin typeset \
                f \
                h1;
        ((
                BPX_INTERACTIVE_MODE =
                BASH_SUBSHELL == 0
                ? 1
                : 0
        ))
        if
                (( ${#BPX_PREEXEC_FUNC[@]} ))
        then
                builtin read -r _ h1 < <(
                        HISTTIMEFORMAT= builtin history 1
                )
                for f in "${BPX_PREEXEC_FUNC[@]}"
                do
                        1>/dev/null builtin typeset -F "$f" && {
                                ${f} "$c" "$h1"
                        }
                done
                #builtin wait
        fi
fi

__bpx_main ()
if
        [[ $PROMPT_COMMAND == __bpx_precmd || -n $BPX_ERR ]]
then
        builtin return 1
else
        builtin unset -v \
                BPX_ERR \
                BPX_INTERACTIVE_MODE \
                BPX_PRECMD_FUNC \
                BPX_PREEXEC_FUNC \
                BPX_PROMPT_COMMAND_OLD;
        builtin typeset -gi \
                BPX_ERR \
                BPX_INTERACTIVE_MODE=1 \
                BPX_USE_PREEXEC=$BPX_USE_PREEXEC;
        builtin typeset -g +i BPX_PROMPT_COMMAND_OLD="$PROMPT_COMMAND"
        builtin unset -v PROMPT_COMMAND
        builtin typeset -g +i PROMPT_COMMAND=__bpx_precmd
        builtin typeset -g +i -a \
                BPX_PRECMD_FUNC="()" \
                BPX_PREEXEC_FUNC="()";
        (( BPX_USE_PREEXEC )) && {
                builtin shopt -u extdebug
                builtin trap '__bpx_preexec' DEBUG
        }
fi

# -- MAIN.

__bpx_main

# vim: set ts=8 sw=8 tw=0 et :
