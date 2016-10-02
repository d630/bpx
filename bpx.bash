#!/usr/bin/env bash

# bpx -- bash-pre-execution
# Copyright (C) 2015f. D630, GNU GPLv3
# <https://github.com/D630/bpx>

# Forked from Ryan Caloras (ryan@bashhub.com)
# <https://github.com/rcaloras/bash-preexec>
# Original by Glyph Lefkowitz

# -- FUNCTIONS.

__bpx_precmd ()
{
        BPX_ERR=$?

        builtin typeset __

        for __ in "${BPX_PRECMD_FUNC[@]}"
        do
                if
                        1>/dev/null builtin typeset -F "$__"
                then
                        "$__"
                else
                        printf 'bash: bpx: function %s is not declared\n' "$__"
                fi
        done
}

__bpx_preexec ()
{
        builtin typeset __

        for __ in "${BPX_PREEXEC_FUNC[@]}"
        do
                if
                        1>/dev/null builtin typeset -F "$__"
                then
                        "$__"
                else
                        printf 'bash: bpx: function %s is not declared\n' "$__"
                fi
        done
}

__bpx_main ()
if
        [[ $PROMPT_COMMAND == __bpx_precmd || -v BPX_ERR ]]
then
        builtin return 1
else
        builtin unset -v \
                BPX_PROMPT_COMMAND_OLD \
                BPX_PS0_OLD;
        builtin typeset -g +i \
                BPX_PROMPT_COMMAND_OLD="$PROMPT_COMMAND" \
                BPX_PS0_OLD="$PS0";
        builtin unset -v \
                BPX_ERR \
                BPX_PRECMD_FUNC \
                BPX_PREEXEC_FUNC \
                PROMPT_COMMAND \
                PS0;
        builtin typeset -gi BPX_ERR
        builtin typeset -g +i \
                PROMPT_COMMAND=__bpx_precmd \
                PS0='$(__bpx_preexec)';
        builtin typeset -g +i -a \
                BPX_PRECMD_FUNC="()" \
                BPX_PREEXEC_FUNC="()";
fi

# -- MAIN.

__bpx_main

# vim: set ts=8 sw=8 tw=0 et :
