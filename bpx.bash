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
    'return' "${1:-0}";
};

function __bpx_postread {
    'set' '--' "$?";

    ((bpx_var[1] && ${#rl1[@]})) ||
        'return' "$1";

    'typeset' '__';

    for __ in "${postread_functions[@]}"; do
        1>'/dev/null' 'typeset' '-F' "$__" ||
            'continue';

        '__bpx_return' "$1";

        bpx_var='' rl1='' rl2='' rl3='' "$__" ||
            'break';
    done 1>&2;

    'return' "$1";
};

function __bpx_precmd {
    'set' '--' "$?";

    'typeset' '__';

    for __ in "${precmd_functions[@]}"; do
        1>'/dev/null' 'typeset' '-F' "$__" ||
            'continue';

         '__bpx_return' "$1";

        bpx_var='' rl1='' rl2='' rl3='' "$__" ||
            'break';
    done;

    'return' "$1";
};

function __bpx_preexec {
    [[
        'BASHPID' -ne "$$" ||
        'BASH_SUBSHELL' -gt 0 ||
        'bpx_var[1]' -eq 0 ||
        -n "$COMP_LINE" ||
        -v READLINE_LINE ||
        -z "${rl2[0]}"
    ]] &&
        'return' '0';

    case "$BASH_COMMAND" in
        (''|'__bpx_postread'|'__bpx_precmd'|'__bpx_return')
            'return' '0';;
    esac;

    case "${FUNCNAME[1]}" in
        ('__bpx_postread'|'__bpx_precmd'|'__bpx_return')
            'return' '0';;
    esac;

    case "${FUNCNAME[2]}" in
        ('__bpx_postread'|'__bpx_precmd'|'__bpx_return')
            'return' '0';;
    esac;

    'typeset' \
        '__' \
        'histcmd';

    # TODO(D630): HISTCMD and parameter transformation of \! expands always to
    # one, when they are running in a trap.
    # h='\!';
    # h="${h@P}";

    [[ "$SHELLOPTS" == *'history'* ]] && {
        IFS=$' \t' 'read' '-r' '_' 'histcmd' < <(
            HISTTIMEFORMAT= 'history' '1'
        );
    };

    for __ in "${preexec_functions[@]}"; do
        1>'/dev/null' 'typeset' '-F' "$__" ||
            'continue';

        '__bpx_return' "${bpx_var[2]}";

        bpx_var='' histcmd="$histcmd" BASH_COMMAND="$BASH_COMMAND" "$__" ||
            'break';
    done;
};

function __bpx_preread {
    'typeset' '__';

    for __ in "${preread_functions[@]}"; do
        1>'/dev/null' 'typeset' '-F' "$__" ||
            'continue';

        '__bpx_return' "${bpx_var[2]}";

        bpx_var='' "$__" ||
            'break';
    done 1>&2;
};

function __bpx_define_rl3 {
    IFS=$' \t\n' 'read' '-r' '-d' '' '-a' 'rl3' <<< "${rl2[@]}";
};

function __bpx_read_line {
    bpx_var[bpx_var[1]=0,2]="$?";

    # If line buffer is empty, then test also, whether we're in the primary or
    # secondary prompt.
    ((${#rl0})) || {
        (((bpx_var[0]-=1) < 0)) &&
            rl1=();

        'return' '1';
    };

    # Test, if history expansion has been performed.
    [[ "$rl0" == "$READLINE_LINE" ]] || {
        bpx_var='bpx_var[0]-=1';

        READLINE_LINE="$rl0";

        'return' '1';
    };

    if
        ((bpx_var[0]));
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
    'mapfile' '-t' '-s' '2' 'rl2' < <(
        IFS=$'\n';

        # '.'  '/dev/stdin' <<< "
        'eval' "
            function f {
                ${rl1[*]}
            } &&
                'typeset' '-f' 'f';
        " 2>'/dev/null';
    );

    ((${#rl2[@]})) ||
        'return' '1';

    'unset' '-v' rl2[-1];

    bpx_var[1]='1';
};

function __bpx_main {
    # internal integer indexed array variable *bpx_var*:
    # 0 number of the current input line; if gt zero, we are using the
    #   secondary prompt
    # 1 is one when complete command line has been read (no PS2 anymore)
    # 2 last status code
    #
    # Don't mess around with it.

    'unset' '-v' \
        'rl0' \
        'rl1' \
        'rl2' \
        'rl3' \
        'bpx_var' \
        'postread_functions' \
        'preread_functions';

    # 'unset' '-v' \
    #     'precmd_functions' \
    #     'preexec_functions';

    # 'typeset' '-g' '-a' \
    #     'precmd_functions' \
    #     'preexec_functions';

    'typeset' '-g' 'rl0';

    'typeset' '-g' '-a' \
        'rl1' \
        'rl2' \
        'rl3' \
        'postread_functions' \
        'preread_functions';

    'typeset' '-g' '-a' '-i' 'bpx_var=(0 0 0)';

    'bind' '-x' '"\C-x\C-x1": rl0="$READLINE_LINE";';
    'bind' '"\C-x\C-x2": history-expand-line';

    'bind' '-x' '"\C-x\C-x3": "'__bpx_read_line'"';
    'bind' '-x' '"\C-x\C-x4": "'__bpx_read_line' && '__bpx_preread'"';

    'bind' '"\C-x\C-x5": accept-line';
    'bind' '-x' '"\C-x\C-x6": "'__bpx_postread'"';
};

# -- MAIN.

'__bpx_main';

# -- TEST CONFIGURATION

# # At first, guarantee some options to be set.
# set -o emacs
# set -o histexpand
# set -o history
# shopt -s cmdhist
# shopt -s expand_aliases
# shopt -s promptvars

# # Then we define four hook functions:
# function preread {
#     typeset s=$?

#     # The following strings will be shown above your prompt.
#     tput setaf 1
#     printf "%sPREREAD%s\nlast def of READLINE_LINE was:\n\t<%s>\n" \
#         -- -- "$READLINE_LINE"
#     printf "last def of READLINE_POINT was:\n\t<%d>\n" "$READLINE_POINT"
#     tput sgr0

#     # Define also array *rl3*. Also usable in *preexec*
#     '__bpx_define_rl3';

#     # Some strings shall be printed below your prompt. To achieve this, we
#     # assign the *PSO* parameter (see below). We cannot set *PSO* directly in
#     # *preread*, so let's use a workaround.
#     ps0=$(
#         tput setaf 2
#         printf "%sps0%s\nlast status code was:\n\t<%d>\n" -- -- $s

#         # Print what has been typed on the prompt. Go and reference *rl{1,2,3}*.

#         printf "%s\n" rl1:
#         for i in "${!rl1[@]}"; do
#             printf '\tln %d := <%s>\n' "$i" "${rl1[i]}"
#         done

#         # Remove first indentation level, which is always (?) four spaces.
#         printf "%s\n" rl2:
#         for i in "${!rl2[@]}"; do
#             printf '\tln %d := <%s>\n' "$i" "${rl2[i]/????/}"
#         done

#         printf "%s\n" rl3:
#         for i in "${!rl3[@]}"; do
#             printf '\tword %d := <%s>\n' "$i" "${rl3[i]}"
#         done

#         # Make sure bash doesn't make silly rubbish.
#         printf 'output:\n\r'

#         tput sgr0
#     );
# };
# function preexec {
#     tput setaf 3

#     printf '%sPREEXEC%s\n\thist 1 is: <%s>\n' -- -- "$histcmd"
#     printf '\tbash_cmd is: <%s>\n' "$BASH_COMMAND"
#     printf '\tlength of rl{1,2,3}: <%d> <%d> <%d>\n' \
#         "${#rl1[@]}" "${#rl2[@]}" "${#rl3[@]}"

#     tput sgr0
# };
# function precmd {
#     typeset s=$?

#     tput setaf 4
#     printf '%sPRECMD%s\nstatus code is:\n\t<%d>\n' -- -- $s
#     tput sgr0
# };
# function postread {
#     typeset s=$?

#     tput setaf 5
#     printf '%sPOSTREAD%s\nstatus code was really:\n\t<%d>\n' -- -- $s

#     tput sgr0
# };

# # Now put the functions into the arrays.
# preread_functions=(preread)
# preexec_functions=(preexec)
# precmd_functions=(precmd)
# postread_functions=(postread)

# # Turn on *preread* and *postread*. Use Control-j for them.
# bind 'C-j: "\C-x\C-x1\C-x\C-x2\C-x\C-x4\C-x\C-x5\C-x\C-x6"'

# # Make sure internal variables are set on time, when using the macro. *ps0* is
# # used as helper in *preread*. Make also *PS2* a bit nicer for our test and put
# # a newline into *PS1* to see what happens.
# export PS1='${_[ ps0=9999, bpx_var=0, 1 ]}--PS1--\n\u@\h \w \$ '
# export PS2='${bpx_var[ bpx_var+=1, 0 ]}> '
# export PS0='${ps0#9999}'

# # Make *precmd* running.
# PROMPT_COMMAND='__bpx_precmd'

# # Use smaller tabs, please.
# tabs -4

# # Define some aliases for the test:
# alias ls='ls -l'
# alias command='command '
# alias fgrep='grep -F'

# # In the end, run also *preexec*. Turn on the extended debugging mode. Let's
# # see what is gonna happen.
# shopt -s extdebug
# trap __bpx_preexec DEBUG
# # set +o functrace
# # set +o errtrace

# vim: set ts=4 sw=4 tw=0 et :
