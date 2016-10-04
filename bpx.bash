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
                        1>/dev/null builtin typeset -f "$__"
                then
                        "$__"
                else
                        1>&2 builtin printf "bash: bpx: function '%s' is not declared\n\r" "$__"
                fi
        done
}

__bpx_preexec ()
{
        builtin typeset __

        for __ in "${BPX_PREEXEC_FUNC[@]}"
        do
                if
                        1>/dev/null builtin typeset -f "$__"
                then
                        "$__"
                else
                        1>&2 builtin printf "bash: bpx: function '%s' is not declared\n\r" "$__"
                fi
        done
}

__bpx_main ()
if
        [[ -v BPX_ERR ]]
then
        builtin return 1
else
        builtin unset -v \
                BPX_ERR \
                BPX_PRECMD_FUNC \
                BPX_PREEXEC_FUNC \
                BPX_PROMPT_COMMAND_DEFAULT \
                BPX_PROMPT_COMMAND_ORIG \
                BPX_PS0_DEFAULT \
                BPX_PS0_ORIG;
        [[ -v PROMPT_COMMAND ]] && \
                builtin typeset -g BPX_PROMPT_COMMAND_ORIG="$PROMPT_COMMAND";
        [[ -v PS0 ]] && builtin typeset -g BPX_PS0_ORIG="$PS0";
        builtin unset -v \
                PROMPT_COMMAND \
                PS0;
        builtin typeset -gi BPX_ERR=
        builtin typeset -g \
                BPX_PROMPT_COMMAND_DEFAULT=__bpx_precmd \
                BPX_PS0_DEFAULT='$(
                        # {
                        # 0
                        builtin unset -v BPX_PROMPT;
                        builtin unset -f typeset;
                        builtin unalias typeset 2>/dev/null;
                        typeset -A BPX_PROMPT=(
                                [A]="\A"
                                [T]="\T"
                                [\\!]="\!"
                                [\\@]="\@"
                                [d]="\d"
                                [t]="\t"
                                [unixtime]="\D{%s}"
                        );
                        # 0
                        # }
                        # {
                        # 1
                        __bpx_preexec
                        # 1
                        # }
                )';
        builtin typeset -g \
                PROMPT_COMMAND="$BPX_PROMPT_COMMAND_DEFAULT" \
                PS0="$BPX_PS0_DEFAULT";
        builtin typeset -g -a \
                BPX_PRECMD_FUNC="()" \
                BPX_PREEXEC_FUNC="()";
fi

# -- MAIN.

__bpx_main

# vim: set ts=8 sw=8 tw=0 et :
