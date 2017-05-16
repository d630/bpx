### README

[bpx](https://github.com/D630/bpx) fakes a zsh-like hook function system for
interactive bash shells by involving the *bind* builtin command to work with
the readline buffer. See [Examples](../master/examples.bash).

bpx works best in bash 4.4 (*PS0*) and has been tested with the emacs line
editing mode in an interactive instance, that was not running in an Emacs shell
buffer. Please let me know, how to do it with the vi mode (which is, btw, also
the POSIX line editing mode). bash must run without its *--noediting* option,
of course.

### BUGS & REQUESTS

Feel free to open an issue or put in a pull request on
https://github.com/D630/bpx. See also the comments in the script.

bpx suppresses bash from using the secondary prompt, when more input is needed
to complete the command line. Instead, bpx runs its own emulation of Readline's
*edit-and-execute-command*. In order to use your preferred editor, modify the
function *__bpx_edit*, that is:

```sh
function __bpx_edit {
    command vim -f \
     '+set ft=sh' \
     "+call cursor(1,$READLINE_POINT+1)" \
     "${1?}" < /dev/tty > /dev/tty;
};
```

### GIT

To download the very latest source code:

```
git clone https://github.com/D630/bpx
```

In order to use the latest tagged version, do also something like this:

```
cd -- ./bpx
git checkout $(git describe --abbrev=0 --tags)
```

### INSTALL

Just put the shell procedure/script *bpx.bash* elsewhere on your *PATH* and
then execute it with `.` or `source` in your configuraton file for interactive
bash sessions (usually *.bashrc*).

### HOOK FUNCTIONS

Bash is able to handle signals and other conditions (*trap*), to invoke the
function *command_not_found_handle*, and to expand special variables at special
times (*prompting*). But it has no "real" hooking mechanism like you can see
working in [tcsh's special aliases](http://www.tcsh.org), in [zsh's hook
functions](http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions)
or [fish's event
handling](https://fishshell.com/docs/current/commands.html#function).

Because of that, the usual way to emulate zsh-like *preexec* and *precmd* hook
functions is to set a trap on *DEBUG* and a special value in *PROMPT_COMMAND*
respectively. But the *DEBUG* trap has many
[pitfalls](https://github.com/rcaloras/bash-preexec/issues?utf8=%E2%9C%93&q=is%3Aissue),
and it aims badly the real bahviour of zsh: preexec functions in zsh are
executed after the command line (aka. command list or parse tree) has been read
and is about to be executed; they are **not** beeing executed before each
command/pipeline execution of the list. Actually, the second and third
parameters of its functions don't even obtain the whole expansion; alias
expansion in command and process substitutions, for example, is not performed.
That is: one command line, one zsh like preexec hook!

The variable *PS0*, that was introcuced in bash 4.4, can be a replacement for
the *DEBUG* trap, if the user is satisfied with running commands in command
subtitution (a corresponding *PRE_PROMPT_COMMAND* is missing). The alternative
(but still hacky) way used in bpx is to involve Readline by using the *bind*
builtin command to work with the readline buffer. The *preexec* hook is then
plugged into a wrapper around the Readline command *accept-line*. As
a by-product, we are able to define some additional hooks:

| Order | Hook | Method | Description |
| --- | --- | --- | --- |
| 1 | preread | bind | Executed in a "keyseq:shell-command" binding before the readline-function *accept-line* is invoked. *READLINE_{LINE,POINT}* may be modified |
| 2 | preexec | bind | Executed in a "keyseq:shell-command" binding before the readline-function *accept-line* is invoked. *READLINE_{LINE,POINT}* may not be modified anymore |
| 3 | debug | trap | Works with *DEBUG* and is executed for every command in the command list; *BASH_COMMAND* available (**not recommended**) |
| 4 | prompt | variable | Works with the *PROMPT_COMMAND* variable and is executed before each prompting of the primary prompt (*PS1*) |
| 5 | postread | bind | Executed in a "keyseq:shell-command" binding after the readline-function *accept-line* has been invoked |

Similar to zsh, those hook functions execute function names in an array, which
has the same name as the hook + "_functions" appended: `preread_functions=(foo
bar)`. bpx takes care to redirect to stderr and to pass the correct status
codes to them (*$?*). Your settings to history expansion will also be
respected.

#### internal variables

bpx sets some global variables for internal purposes:

| Variable | Description |
| --- | --- |
| bpx_var | Integer attributed indexed array variable |
| "[0] | Is one when command line isn't valid |
| "[1] | Is one when complete command line has been read |
| "[2] | Number of *BASH_COMMAND* in a command line (*debug*) |
| "[3] | Last status code |

#### preread, preexec, and postread

As part of the wrapper, bpx binds a number of key sequences
(*__bpx_set_binds*), which will be running after entering the key
sequence `\C-x\C-x1`. Simply use this key or bind it to a key or key sequence
of your choice:

```sh
bind 'C-j: "\C-x\C-x1"'
```

Then make sure bpx has sane internal variables, when the next hooking takes
place:

```sh
# set bpx_var to 0
PS1='${_[ bpx_var=0, 1 ]}\u@\h \w \$ '
```

Before *preread*, *preexec*, and *postread* hook functions are about to be
executed, the wrapper provides some functions and variables for them:

| Name | Object | Description |
| --- | --- | --- |
| __bpx_command_line | Normal function | The body contains the full command line with aliases expanded outside of command and process substitutions |
| __bpx_set_rl1 | Normal function | Assigns to *rl1* |
| __bpx_set_rl2 | Normal function | Assign to *rl2*; implies *__bpx_set_rl1* |
| __bpx_read_again | Normal function | Forces rereading and editing of the command line from start |
| __bpx_read_abort | Normal function | Stops the editing and execution of the current command line |
| __bpx_read_accept | Normal function | Undoes *__bpx_read_{again,abort}* |
| rl0 | Normal scalar variable | Holds the the full command line without alias expanded |
| rl1 | Normal indexed array | Contains the body of *__bpx_command_line* |
| rl2 | Normal indexed array | Contains the body of *__bpx_command_line*, but each index only points to one word (+ operator) |

#### debug

If you really desire *debug*, set the *DEBUG trap* like `trap __bpx_debug
DEBUG`. Then play around with the following settings

```sh
shopt -s extdebug
set +o functrace
set +o errtrace
```

and reset *bpx_var[2]* to zero

```sh
PS1='${_[ bpx_var[2]=0, 1 ]}\u@\h \w \$ '
```

If command history is active, the parameter *histcmd* holds the output of
`HISTTIMEFORMAT= history 1` with the history number removed, otherwise it's the
empty string.

#### prompt

*prompt* can be used, for example, like so: `PROMPT_COMMAND=__bpx_prompt`. If
you define *PROMPT_COMMAND* in a different way, make sure *prompt* functions
have access to the *?* parameter to work properly. Everything else belonging to
*PROMPT_COMMAND* can be executed by doing:

```sh
function my_stuff {
    ...
}

prompt_functions=(my_stuff)
```

#### Notice

If you started the session with *debug* and *preread*/*preexec*/*postread* and
you want to disable *preread*/*preexec*/*postread* in the same session, do this:
rebind/unbind your key or key sequence if wanted and unset *bpx_var[3]* like

```sh
unset -v bpx_var[3]
```

### TESTING

The [test configuration](../master/test.bash) makes use of all hook mechanisms
and *extdebug*. Run bash like

```sh
env -i \
    HOME=$HOME \
    INPUTRC=/dev/null \
    TERM=$TERM \
    HISTFILE=/tmp/bash_history~ \
    bash --rcfile bpx.bash -i
```

and execute the test file

```sh
. test.bash
```

### NOTICE

bpx has been written on [Debian GNU/Linux stretch/sid (4.9.0-2
x86-64)](https://www.debian.org) in/with [GNU bash
4.4.11(1)-release](http://www.gnu.org/software/bash/).

### LICENCE

GNU GPLv3
