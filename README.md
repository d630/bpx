## README

[bpx](https://github.com/D630/bpx) is a bash shell procedure/script which simulates the zsh hook functions *preexec* and *precmd*, (like [bash-preexec](https://github.com/rcaloras/bash-preexec)) but in an unsual manner: instead of doing the preexecution hook with the *DEBUG trap*, bpx involves Readline by using the *bind* builtin command to work with the readline buffer. That's why bpx defines the hook functions *preexec* and *precmd* as well as *preread* and *postread*.

bpx is, though, still a hacky business, no doubt. But it remembers the real bahviour of zsh: preexec functions are executed after the command line (aka. command list) has been read and is about to be executed; they are **not** beeing executed before each command execution of the list. Actually, the second and third parameters of its functions don't even obtain the whole expansion; alias expansion in command and process substitution, for example, is not performed. That is: one command line, one preexec hook!

bpx works best in bash 4.4 (*PS0*) and has been tested with the emacs line editing mode in an interactive instance that was not running in an Emacs shell buffer. Please let me know, how to do it with the vi mode (which is, btw, also the POSIX line editing mode). bash must run without its *--noediting* option, of course.

## BUGS & REQUESTS

Feel free to open an issue or put in a pull request on https://github.com/D630/bpx. See also the comments in the script.

## GIT

To download the very latest source code:

```
git clone https://github.com/D630/bpx
```

In order to use the latest tagged version, do also something like this:

```
cd -- ./bpx
git checkout $(git describe --abbrev=0 --tags)
```

## INSTALL

Just put *bpx.bash* elsewhere on your *PATH* and then execute it with `.` or `source` in your configuraton file for interactive bash sessions (usually *.bashrc*).

## USAGE

A hook function executes functions in an array, which has the same name as the function + "_functions" appended (like "preread_functions"). All functions redirect to stderr. It makes sense to use *preread* with *PS0*.

1. *preread* is executed in a "keyseq:shell-command" binding before the readline-function *accept-line* is called (*READLINE_{LINE,POINT}* available). The status code of the last command line execution is in the *?* parameter. Array functions have also access to two indexed array variables with different lengths:
    - *rl1* holds the strings that the user has typed (regardless of command history). If the index is greater than zero, the value holds a line, that was typed in on the secondary prompt (*PS2*);
    - *rl2* contains the full command line in the style of function definitions. Alias expansion is performed outside of command and process substitutions; history expansion is performed just once.
2. *preexec* works with the *DEBUG trap* and is executed for every command in the command list (*BASH_COMMAND* available). If command history is active, the parameter *histcmd* holds the output of `HISTTIMEFORMAT= history 1` with the history number removed, otherwise it's the empty string. (**not recommended**)
3. *precmd* works with the *PROMPT_COMMAND* variable and is executed before each prompting of the primary prompt (*PS1*).
4. *postread* is executed in a "keyseq:shell-command" binding after the readline-function *accept-line* has been executed. There is access to the status code of the most recently executed command line (like *precmd* has).

In *preread* (and then also in *preexec*) you can use the function *__bpx_define_rl3* to get a third indexed array variable: *rl3* holds the command line that will be executed (like *rl2*), but each index only points to one word.

bpx sets also the following global variables:

```
bpx_var
    Integer attributed indexed array variable
    [0] number of the current input line; if gt zero, we are using the
        secondary prompt
    [1] is one when complete command line has been read (no PS2 anymore)
    [2] number of *BASH_COMMAND* in a command line
    [3] last status code

rl0
    Normal scalar variable. Used to see, whether an input line has been
    history expanded.
```

### preread and postread

Internally, bpx binds six key sequences, which have to be bind as macro to a key or key sequence of your choice:

* *\C-x\C-x1* binds the important internal variable *rl0*
* *\C-x\C-x2* invokes *history-expand-line*
* *\C-x\C-x3* executes *__bpx_read_line*
* *\C-x\C-x4* executes *__bpx_read_line* and *__bpx_preread* in a shell command list
* *\C-x\C-x5* invokes *accept-line*
* *\C-x\C-x6* executes *__bpx_postread*

If you only want to use *preread*, at first bind the macro `\C-x\C-x1\C-x\C-x2\C-x\C-x4\C-x\C-x5` to a key seq like in `bind 'C-j: "macro"'`. Then make sure bpx has sane internal variables, when the next hook takes place:

```sh
# set bpx_var to 0
PS1='${_[ bpx_var=0, 1 ]}\u@\h \w \$ '

# increment bpx_var
PS2='${_[ bpx_var+=1, 1 ]}> '
```

If you only want to use *postread*, bind the following macro as shown in `bind 'C-j: "\C-x\C-x1\C-x\C-x2\C-x\C-x3\C-x\C-x5\C-x\C-x6"` and reset *bpx_var*.

And in order to define both of them, run `bind 'C-j: "\C-x\C-x1\C-x\C-x2\C-x\C-x4\C-x\C-x5\C-x\C-x6"`.

In summary (lol):

- *preread*: `\C-x\C-x1\C-x\C-x2\C-x\C-x4\C-x\C-x5`
- *postread*: `\C-x\C-x1\C-x\C-x2\C-x\C-x3\C-x\C-x5\C-x\C-x6`
- *both*: `\C-x\C-x1\C-x\C-x2\C-x\C-x4\C-x\C-x5\C-x\C-x6`

### preexec and precmd

If you really desire *preexec*, set the *DEBUG trap* like `trap __bpx_preexec DEBUG`. Then play around with the following settings

```sh
shopt -s extdebug
set +o functrace
set +o errtrace
```

and reset *bpx_var[2]* to zero

```sh
PS1='${_[ bpx_var[2]=0, 1 ]}\u@\h \w \$ '
```

*precmd* can be used, for example, like so: `PROMPT_COMMAND=__bpx_precmd`. If you define *PROMPT_COMMAND* in a different way, make sure *precmd* functions have access to the *?* parameter to work properly. Your other things belonging to *PROMPT_COMMAND* can be executed by doing:

```sh
function _my_stuff {
    ...
}

precmd_functions=(_my_stuff)
```

### Notice

If you started the session with *preexec* and *preread*/*postread* and you want to disable *preread*/*postread* in the same session, do this: rebind/unbind your key or key sequence and unset *bpx_var[3]*:

```sh
unset -v bpx_var[3]
```

## EXAMPLE

The following test configuration makes use of all hook mechanisms and *extdebug*; it's also appended to *bpx.bash*. Comment it out and test it like:

```sh
env -i HOME=$HOME INPUTRC=/dev/null TERM=$TERM HISTFILE=/tmp/bash_history~ \
    bash --rcfile bpx.bash -i
```

Type and abort some simple and complex commands (with aliases and history expansion), let it read empty lines on the primary and secondary prompt. You will also see, that *preread* and *postread* never print below the old and new prompt respectively.

```sh
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
    '__bpx_define_rl3';

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
};
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
# used as helper in *preread*. Make also *PS2* a bit nicer for our test and put
# a newline into *PS1* to see what happens.
export PS1='${_[ ps0=9999, bpx_var=0, bpx_var[2]=0, 1 ]}--PS1--\n\u@\h \w \$ '
export PS2='${bpx_var[ bpx_var+=1, 0 ]}> '
export PS0='${ps0#9999}'

# Make *precmd* running.
PROMPT_COMMAND='__bpx_precmd'

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
```

## NOTICE

bpx has been written on [Debian GNU/Linux stretch/sid (4.8.11-1 x86-64)](https://www.debian.org) in/with [GNU bash 4.4.5(1)-release](http://www.gnu.org/software/bash/).

## LICENCE

GNU GPLv3
