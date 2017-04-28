### README

[bpx](https://github.com/D630/bpx) is a bash shell procedure/script, which
simulates the zsh hook functions **preexec** and **precmd**, (like
[bash-preexec](https://github.com/rcaloras/bash-preexec)) but in an unsual
manner: instead of doing the preexecution hook with the *DEBUG trap*, bpx also
involves Readline by using the *bind* builtin command to work with the readline
buffer and to define the additional hook functions **preread** and
**postread**.

bpx is, though, still a hacky business, no doubt. But it remembers the real
bahviour of zsh: preexec functions in zsh are executed after the command line
(aka. command list or parse tree) has been read and is about to be executed;
they are **not** beeing executed before each command execution of the list.
Actually, the second and third parameters of its functions don't even obtain
the whole expansion; alias expansion in command and process substitution, for
example, is not performed. That is: one command line, one zsh like preexec hook!

bpx works best in bash 4.4 (*PS0*) and has been tested with the emacs line
editing mode in an interactive instance that was not running in an Emacs shell
buffer. Please let me know, how to do it with the vi mode (which is, btw, also
the POSIX line editing mode). bash must run without its *--noediting* option,
of course.

![](https://raw.githubusercontent.com/D630/bpx/master/bpx.gif)

### BUGS & REQUESTS

Feel free to open an issue or put in a pull request on
https://github.com/D630/bpx. See also the comments in the script.

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

Just put *bpx.bash* elsewhere on your *PATH* and then execute it with `.` or
`source` in your configuraton file for interactive bash sessions (usually
*.bashrc*).

### HOOKS

A hook function executes functions in an array, which has the same name as the
function + "_functions" appended (like "preread_functions"). All functions
redirect to stderr. It makes sense to use *preread* with *PS0*.

| Hook | Method | Variables |
| --- | --- | --- |
| preread | bind | ?; READLINE_{LINE,POINT}; rl{1,2,3} |
| preexec | trap | ?; BASH_COMMAND; histcmd; rl{1,2,3} |
| precmd | variable | ? |
| postread | bind | ? |

**preread** is executed in a "keyseq:shell-command" binding before the
readline-function *accept-line* is called (*READLINE_{LINE,POINT}* available).
The status code of the last command line execution is in the *?* parameter.
Array functions have also access to two indexed array variables with different
lengths: *rl1* holds the strings that the user has typed (regardless of command
history). If the index is greater than zero, the value holds a line, that was
typed in on the secondary prompt (*PS2*); *rl2* contains the full command line
in the style of function definitions. Alias expansion is performed outside of
command and process substitutions; history expansion is performed just once.

**preexec** works with the *DEBUG trap* and is executed for every command in
the command list (*BASH_COMMAND* available). If command history is active, the
parameter *histcmd* holds the output of `HISTTIMEFORMAT= history 1` with the
history number removed, otherwise it's the empty string. (**not recommended**)

**precmd** works with the *PROMPT_COMMAND* variable and is executed before each
prompting of the primary prompt (*PS1*).

**postread** is executed in a "keyseq:shell-command" binding after the
readline-function *accept-line* has been executed. There is access to the
status code of the most recently executed command line (like *precmd* has).

In *preread* (and then also in *preexec*) you can use the function
*__bpx_define_rl3* to get a third indexed array variable: *rl3* holds the
command line that will be executed (like *rl2*), but each index only points to
one word.

bpx sets also some global variables for internal purposes:

| Variable | Description |
| --- | --- |
| bpx_var | Integer attributed indexed array variable |
| ""[0] | number of the current input line; if gt zero, we are using the secondary prompt |
| ""[1] | is one when complete command line has been read (no *PS2* anymore) |
| ""[2] | number of *BASH_COMMAND* in a command line |
| ""[3] | last status code |
| rl0 | Normal scalar variable. Used to see, whether an input line has been history expanded. |

#### preread and postread

Internally, bpx binds six key sequences, which have to be bound as macro to
a key or key sequence of your choice:

| Keyseq | Function |
| --- | --- |
| `\C-x\C-x1` | binds the important internal variable *rl0* |
| `\C-x\C-x2` | invokes *history-expand-line* |
| `\C-x\C-x3` | executes *__bpx_read_line* |
| `\C-x\C-x4` | executes *__bpx_read_line* and *__bpx_preread* in a shell command list |
| `\C-x\C-x5` | invokes *accept-line* |
| `\C-x\C-x6` | executes *__bpx_postread* |

If you only want to use *preread*, at first bind the macro
`\C-x\C-x1\C-x\C-x2\C-x\C-x4\C-x\C-x5` to a key seq like in `bind 'C-j:
"macro"'`. Then make sure bpx has sane internal variables, when the next hook
takes place:

```sh
# set bpx_var to 0
PS1='${_[ bpx_var=0, 1 ]}\u@\h \w \$ '

# increment bpx_var
PS2='${_[ bpx_var+=1, 1 ]}> '
```

If you only want to use *postread*, bind the macro as shown in `bind 'C-j:
"\C-x\C-x1\C-x\C-x2\C-x\C-x3\C-x\C-x5\C-x\C-x6"` and reset *bpx_var* like
above.

And in order to define both of them, run `bind 'C-j:
"\C-x\C-x1\C-x\C-x2\C-x\C-x4\C-x\C-x5\C-x\C-x6"`.

In summary (lol):

| Hook | Macro |
| --- | --- |
| preread | `\C-x\C-x1\C-x\C-x2\C-x\C-x4\C-x\C-x5` |
| postread | `\C-x\C-x1\C-x\C-x2\C-x\C-x3\C-x\C-x5\C-x\C-x6` |
| both | `\C-x\C-x1\C-x\C-x2\C-x\C-x4\C-x\C-x5\C-x\C-x6` |

#### preexec

If you really desire *preexec*, set the *DEBUG trap* like `trap __bpx_preexec
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

#### precmd

*precmd* can be used, for example, like so: `PROMPT_COMMAND=__bpx_precmd`. If
you define *PROMPT_COMMAND* in a different way, make sure *precmd* functions
have access to the *?* parameter to work properly. Everything else belonging
to *PROMPT_COMMAND* can be executed by doing:

```sh
function _my_stuff {
    ...
}

precmd_functions=(_my_stuff)
```

#### Notice

If you started the session with *preexec* and *preread*/*postread* and you want
to disable *preread*/*postread* in the same session, do this: rebind/unbind
your key or key sequence and unset *bpx_var[3]* like

```sh
unset -v bpx_var[3]
```

### EXAMPLE

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

Then type and abort some simple and complex commands (with aliases and history
expansion), let it read empty lines on the primary and secondary prompt. You
will also see, that *preread* and *postread* never print below the old and new
prompt respectively.

### NOTICE

bpx has been written on [Debian GNU/Linux stretch/sid (4.8.11-1
x86-64)](https://www.debian.org) in/with [GNU bash
4.4.5(1)-release](http://www.gnu.org/software/bash/).

### LICENCE

GNU GPLv3
