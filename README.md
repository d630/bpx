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

##### USAGE

First execute `bpx.bash` with `.` or `source` in your configuraton file for interactive bash sessions. This will set up two indexed array variables called `BPX_PRECMD_FUNC` and `BPX_PREEXEC_FUNC` respectively, which need to be filled with function names. The members of `precmd` are executed before each prompting (see `PROMPT_COMMAND`); `preexec` members are executed in a command substitution when `PS0` is beeing expanded. Both will send its output to stderr. Any earlier assignment to `PROMPT_COMMAND` will be overwritten with `__bpx_precmd` and `PSO` gets the value `$(__bpx_preexec)`; the earlier assignments will be stored as `BPX_PROMPT_COMMAND_OLD` and `BPX_PS0_OLD`.

A senseless example:

```sh
source bpx.bash

function __preexec0 {
    read -r _ h1 < <(
        HISTTIMEFORMAT= history 1
    );
}
function __preexec1 { echo BEGIN; }
function __preexec2 { printf '%s\n\r' SPEAK; }
function __precmd0  { echo STOP; }
function __precmd1 { echo END ; }

BPX_PREEXEC_FUNC=(__preexec0 __preexec1 __preexec2)
BPX_PRECMD_FUNC=(__precmd0 __precmd1)
```

`$?` will be inherited as `BPX_ERR` to the `precmd` mechanism.

```sh
function __preexec3 {
echo "I typed '${h1}', but it is an alias in my conf file.
I could check that by comparing \${BASH_ALIASES[${h1}]},which is '${BASH_ALIASES[${h1}]}', with '${h1}'.

PS: Here is the output of '${h1}':"

printf '%s\n\r'
}

BPX_PREEXEC_FUNC+=(__preexec3)
```

Now we get:

```sh
% ls
> BEGIN
> SPEAK
> I typed 'ls', but it is an alias in my conf file.
> I could check that by comparing ${BASH_ALIASES[ls]} with 'ls --color=auto'.

> PS: Here is the output of 'ls':
> README.md  bpx.bash
> STOP
> END
```

##### NOTICE

bpx has been written in [GNU bash 4.4.0(1)-release](http://www.gnu.org/software/bash/) on [Debian GNU/Linux 9 (stretch/sid)](https://www.debian.org).

##### LICENCE

GNU GPLv3
