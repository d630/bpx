##### README

[bpx](https://github.com/D630/bpx) is my modification of [bash-preexec](https://github.com/rcaloras/bash-preexec), a set of `preexec` and `precmd` hook functions for `GNU bash >= 4.4`.

##### BUGS & REQUESTS

Feel free to open an issue or put in a pull request on https://github.com/D630/bpx

##### GIT

To download the very latest source code:

```
git clone https://github.com/D630/bpx
```

In order to use the latest tagged version, do also something like this:

```
cd -- ./bpx
git checkout $(git describe --abbrev=0 --tags)
```

##### INSTALL

Just put `bpx.bash` elsewhere on your `PATH` and then execute it with `.` or `source` in your configuraton file for interactive bash sessions (usually `.bashrc`).

##### DESCRIPTION

bpx will set up two indexed array variables called `BPX_PRECMD_FUNC` and `BPX_PREEXEC_FUNC` respectively, which need to be filled with function names. The members of `precmd` are executed before each prompting (see `PROMPT_COMMAND`); `preexec` members are executed in a command substitution when `PS0` is beeing expanded. Both will send its output to stderr. Any earlier assignment to `PROMPT_COMMAND` and `PSO` will be overwritten with `__bpx_precmd` and the value of `BPX_PS0`, and be stored as `BPX_PROMPT_COMMAND_ORIG` and `BPX_PS0_ORIG`.

`preexec` functions have access to an associative array variable called `BPX_PROMPT` with the following keys (see the [manual](https://www.gnu.org/software/bash/manual/bash.html#Controlling-the-Prompt) for a description)):

```
Regular:
! # $ @ A H T V W d h j l s t u v w

Further:
unixtime (seconds since 1970-01-01 00:00:00 UTC; set via "\D{%s}")
```

The current exit status (`$?`) will be inherited as `BPX_ERR` to the `precmd` mechanism and is available as "last" status in `preexec` functions.

##### EXAMPLES

###### Some nonsens

```sh
function func0 { echo BEGIN; }
function func1 { printf '%s\n\r' SPEAK; }
BPX_PREEXEC_FUNC=(func0 func1)

function func2  { echo STOP; }
function func3 { echo END; }
BPX_PRECMD_FUNC=(func2 func3)
```

After typing a command like `echo hello world!` you can see then:

```sh
% echo hello world
BEGIN
SPEAK
hello world!
STOP
END
```

Now let's use all of the keys from `BPX_PROMPT` in `preexec`

```sh
function func4 {
    for i in "${!BPX_PROMPT[@]}"
    do
        printf '\t%s -> %s\n' "$i" "${BPX_PROMPT[$i]}"
    done
    printf '\r'
}

BPX_PREEXEC_FUNC+=(func4)
```

After typing the command `true` I get:

```sh
% true
BEGIN
SPEAK
    ! -> 1447
    # -> 4
    $ -> $
    unixtime -> 1475509325
    @ -> 04:42 PM
    A -> 16:42
    H -> ME
    T -> 04:42:05
    V -> 4.4.0
    W -> ~
    d -> Mon Oct 03
    h -> ME
    j -> 0
    l -> 6
    s -> bash
    t -> 16:42:05
    u -> user1
    v -> 4.4
    w -> ~
STOP
END
```

###### Setting PS{1..4}

The best way to customize the prompt, is to set its variables in a function:

```sh
function __prompt_command {
    PS1='\t \$ '
    PS2='> '
}

BPX_PRECMD_FUNC[0]=__prompt_command
```

###### Using the history

The history thing in Bash depends really on your configuration. In both mechanisms you can get the commands from the line by running `history 1`. In `preexec` you may also use the keys `BPX_PROMPT[#]` and `BPX_PROMPT[!]`. Remember, that `preexec` functions will be executed in a subshell and cannot be passed directly to `precmd` functions.


```sh
function func4 {
    read -r my_command < <(
        fc -ln "${BPX_PROMPT[\!]}" "${BPX_PROMPT[\!]}"
    );

    read -r _ my_line < <(
        HISTTIMEFORMAT= history 1
    );
}

function func5 {
echo "I typed '${my_line}', but it is an alias in my conf file.
I could check that by comparing \${BASH_ALIASES[\${my_line}]}, which is '${BASH_ALIASES[${my_line}]}', with 'alias ${my_line}' ($(alias ls)).

PS: fc showed me, that '${BPX_PROMPT[\!]}' is beeing mapped to '${my_command}'!

PPS: Here is the output of '${my_line}':"

printf '%s\n\r'
}

BPX_PREEXEC_FUNC=(func4 func5)
```

My output after typing `ls`:

```sh
% ls
I typed 'ls', but it is an alias in my conf file.
I could check that by comparing ${BASH_ALIASES[${my_line}]}, which is 'ls -h --color=auto', with 'alias ls' (alias ls='ls -h --color=auto').

PS: fc showed me, that '1449' is beeing mapped to 'ls'!

PPS: Here is the output of 'ls':

README.md  bpx.bash
```

###### Setting PS0 via `precmd`

Say, we want to reset `PS0` in an interactive session, because the default value isn't good enough or we need to react on our `precmd` functions.

```sh
function reset_ps0 {
    if ((BPX_ERR > 0))
    then
        echo resetting PS0
        PS0='Nice try\n'${BPX_PS0}
    else
        PS0=$BPX_PS0
    fi
}

BPX_PRECMD_FUNC+=(reset_ps0)

function use_my_own {
    ((USE_MY_OWN)) || {
        PS0=$(sed -n '/# 0/,/# 0/d;p' <<< "$BPX_PS0");
        USE_MY_OWN=1
    }
}

BPX_PRECMD_FUNC[0]=use_my_own
```

###### Don't wanna use `preexec` at all

Just unset or edit PS0. You may switch it on again by setting `PS0=$BPX_PS0`.

##### NOTICE

bpx has been written in [GNU bash 4.4.0(1)-release](http://www.gnu.org/software/bash/) on [Debian GNU/Linux 9 (stretch/sid)](https://www.debian.org).

##### LICENCE

GNU GPLv3
