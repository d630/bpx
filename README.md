##### README

[bpx](https://github.com/D630/bpx) is my modification of [bash-preexec](https://github.com/rcaloras/bash-preexec), a set of `preexec` and `precmd` hook functions for `GNU bash`(1) >= 3.2.

##### BUGS & REQUESTS

Feel free to open an issue or put in a pull request on https://github.com/D630/bpx`

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

First execute `bpx.bash` with `.` or `source` in your configuraton file for interactive bash sessions. This will set up two indexed array variables called `BPX_PRECMD_FUNC` and `BPX_PREEXEC_FUNC` respectively, which need to be filled with function names. The members of `precmd` are executed before each prompting (see `PROMPT_COMMAND`); `preexec` members are executed after a command has been read and is about to be executed (see the `SIGNAL_SPEC` called `DEBUG`, used via `trap`). Both will send its output to stderr. Any earlier assignment to `PROMPT_COMMAND` will be overwritten with `__bpx_precmd`, but will also be stored as `BPX_PROMPT_COMMAND_OLD`.

In bpx versions `>= 0.1.6` you need to assign and export the environment variable `BPX_USE_PREEXEC`, if you want to use `preexec`.

##### USAGE


A senseless example:

```sh
export BPX_USE_PREEXEC=1
source bpx.bash
function __preexec0 () { echo BEGIN ; }
function __preexec1 () { echo SPEAK; }
function __precmd0  () { echo STOP; }
function __precmd1 () { echo END ; }
BPX_PREEXEC_FUNC=(__preexec0 __preexec1) ; BPX_PRECMD_FUNC=(__precmd0 __precmd1)
```

When command history has been enabled, its last entry will be passed as the second argument to the `preexec` mechanism. The first argument is the value of `BASH_COMMAND`.

```sh
function __preexec2 () {
echo "I typed '${2}', but it is an alias in my conf file.
I could check that by comparing \${BASH_ALIASES[${2}]} with '${1}'.

PS: Here is the output of '${2}':"
}

BPX_PREEXEC_FUNC+=(__preexec2)
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

bpx has been written in [GNU bash, version 4.3.42(1)-release](http://www.gnu.org/software/bash/) on [Debian GNU/Linux 9 (stretch/sid)](https://www.debian.org).

##### LICENCE

GNU GPLv3
