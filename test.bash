#!/usr/bin/env bash

# At first, guarantee some options to be set.
set -o emacs
set -o histexpand
set -o history
shopt -s cmdhist
shopt -s expand_aliases
shopt -s promptvars

# Then we define four hook functions:
function preread {
    typeset s=$?

    # The following strings will be shown above your prompt.
    tput setaf 1
    printf "%sPREREAD%s\nlast def of READLINE_LINE was:\n\t<%s>\n" \
        -- -- "$READLINE_LINE"
    printf "last def of READLINE_POINT was:\n\t<%d>\n" "$READLINE_POINT"
    tput sgr0

    # Define also array *rl3*. Also usable in *preexec*
    __bpx_define_rl3;

    # Some strings shall be printed below your prompt. To achieve this, we
    # assign the *PSO* parameter (see below). We cannot set *PSO* directly in
    # *preread*, so let's use a workaround.
    ps0=$(
        tput setaf 2
        printf "%sps0%s\nlast status code was:\n\t<%d>\n" -- -- $s

        # Print what has been typed on the prompt. Go and reference *rl{1,2,3}*.

        printf "%s\n" rl1:
        for i in "${!rl1[@]}"; do
            printf '\tln %d := <%s>\n' "$i" "${rl1[i]}"
        done

        # Remove first indentation level, which is always (?) four spaces.
        printf "%s\n" rl2:
        for i in "${!rl2[@]}"; do
            printf '\tln %d := <%s>\n' "$i" "${rl2[i]/????/}"
        done

        printf "%s\n" rl3:
        for i in "${!rl3[@]}"; do
            printf '\tword %d := <%s>\n' "$i" "${rl3[i]}"
        done

        # Make sure bash doesn't make silly rubbish.
        printf 'output:\n\r'

        tput sgr0
    );
};
function preexec {
    typeset s=$?

    # We are testing with *extdebug*. If you wanna avoid subshells, uncomment
    # this.
    #((BASHPID == $$)) ||
    #   return 0

    tput setaf 3

    # You will see, that tabs and newlines are removed in the output, if
    # this function runs in a subshell.
    printf '%sPREEXEC%s\n\t$? is: <%d>\n' -- -- "$s"
    printf '\tbash_cmd is: <%s>\n' "$BASH_COMMAND"
    printf '\thist 1 is: <%s>\n' "$histcmd"
    printf '\tlength of rl{1,2,3}: <%d> <%d> <%d>\n' \
        "${#rl1[@]}" "${#rl2[@]}" "${#rl3[@]}"

    tput sgr0

    # if *extdebug* is on and you remove this redirection, you will get the
    # diagnosis: "bash: $'\E[31m<:>': command not found" after commands like:
    # : && $(:)
} >/dev/tty;
function precmd {
    typeset s=$?

    tput setaf 4
    printf '%sPRECMD%s\nstatus code is:\n\t<%d>\n' -- -- $s
    tput sgr0
};
function postread {
    typeset s=$?

    tput setaf 5
    printf '%sPOSTREAD%s\nstatus code was really:\n\t<%d>\n' -- -- $s

    tput sgr0
};

# Now put the functions into the arrays.
preread_functions=(preread)
preexec_functions=(preexec)
precmd_functions=(precmd)
postread_functions=(postread)

# Turn on *preread* and *postread*. Use Control-j for them.
bind 'C-j: "\C-x\C-x1\C-x\C-x2\C-x\C-x4\C-x\C-x5\C-x\C-x6"'

# Make sure internal variables are set on time, when using the macro. *ps0* is
# used as helper in *preread*. Make also *PS2* and *PS4* a bit nicer for our
# test and put a newline into *PS1* to see what happens.
PS1='${_[ ps0=9999, bpx_var=0, bpx_var[2]=0, 1 ]}--PS1--\n\u@\h \w \$ '
PS2='${bpx_var[ bpx_var+=1, 0 ]}> '
PS0='${ps0#9999}'
PS4='+($?) ${BASH_SOURCE}:${FUNCNAME}:${LINENO}:'

# Make *precmd* running.
PROMPT_COMMAND=__bpx_precmd

# Use smaller tabs, please.
tabs -4

# Define some aliases for the test:
alias ls='ls -l'
alias command='command '
alias fgrep='grep -F'

# In the end, run also *preexec*. Turn on the extended debugging mode. Let's
# see what is gonna happen.
shopt -s extdebug
trap __bpx_preexec DEBUG
# set +o functrace
# set +o errtrace

# vim: set ts=4 sw=4 tw=0 et :
