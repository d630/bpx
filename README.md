## bpx v0.1.0.1 [GNU GPLv3]

`bpx`(1) is my modification of [bash-preexec](https://github.com/rcaloras/bash-preexec), a set of `preexec` and `precmd` hook functions for `GNU bash`(1) >= 3.2.

### Install

```
% git clone https://github.com/D630/bpx.git
% md5sum bpx.bash
288b84e69f152e9614f54cce2a7185d4  bpx.bash
```

### Usage

First source `bpx.bash` into your configuraton file for interactive `bash`(1) sessions, wisely after any declaration of the shell variable `PROMPT_COMMAND`. This will set up two indexed array variables called `X_BPX_PRECMD_FUNC` and `X_BPX_PREEXEC_FUNC` respectively, which need to be filled with function names. The members of `precmd` are executed before each prompting (see `PROMPT_COMMAND`); `preexec` members are executed after a command has been read and is about to be executed (see the `SIGNAL_SPEC` called `DEBUG`, used via `trap`). The output of both will go to stderr.

A senseless example:

```sh
% function _preexec0 () { echo BEGIN ; }
% function _preexec1 () { echo DO; }
% function _precmd0 () { echo DONE; }
% function _precmd1 () { echo END ; }
% X_BPX_PREEXEC_FUNC=(_preexec0 _preexec1) ; X_BPX_PRECMD_FUNC=(_precmd0 _precmd1)
```

When command history is enabled, the last typed entry will be passed as the first argument to the `preexec` mechanism:

```sh
% function _preexec2 () { echo OUTPUT OF: "'${1}'" IS: ; }
% X_BPX_PREEXEC_FUNC+=(_preexec2)
```

Now we have:

```sh
% ls
> BEGIN
> DO
> OUTPUT OF: 'ls' IS:
> README.md  bpx.bash
> DONE
> END
```

### Bugs & Requests

Report it on https://github.com/D630/bpx/issues
