#!/usr/bin/env bash

# TODO(D630): finish etc.

# Don't forget to configure *PS1*!

# Analyse the command line with ShellCheck.
function preexec1 {
	_[2]=$(
		shellcheck \
		 --color=always \
		 --format=tty \
		 --shell=bash - <<< "$rl0";
	) || {
		echo "${_[2]}";
		__bpx_read_abort;
	};
};
preexec_functions=(preexec1);

# Copy the command line into the primary selection buffer.
function preexec2 {
	xsel \
	 -l /dev/null \
	 --primary \
	 --input <<< "$rl0" >/dev/null 2>&1;
};
preexec_functions=(preexec2);

# Reformat the command line with shfmt.
function preread1 {
	READLINE_LINE=$(shfmt <<< "$rl0");
};
preread_functions=(preread1);

# Change the command line into a function definition.
function preread2 {
	READLINE_LINE=$(declare -f __bpx_command_line);
	READLINE_POINT=${#READLINE_LINE};
	__bpx_read_abort;
};
preread_functions=(preread2);

# Show the command line as function and colorize it.
function preread3 {
	declare -f __bpx_command_line |
	# pygmentize -l bash;
	source-highlight \
	 --failsafe \
	 -f esc256 \
	 -o STDOUT \
	 --tab=4 \
	 --line-number=0 \
	 --lang-def=sh.lang \
	 --style-file=esc256.style;
	echo;
	__bpx_read_abort;
};
preread_functions=(preread3);

# Insert the reserved word *time*.
function preread4 {
	READLINE_LINE="time $rl0";
};
preread_functions=(preread4);

# Make the command line verbose.
function preexec3 { set -v; set -x; };
function postread1 { set +v; set +x; };
preexec_functions=(preexec3);
postread_functions=(postread1);

# Print a horizontal line above the prompt.
function postread2 {
	local h;
	printf -v h %\*s $COLUMNS '';
	printf %s\\n ${h// /-};
};
postread_functions=(postread2);

# Go to the Terminal's first line and clear screen before execution.
function preread5 { tput cup 0 0; tput ed; };
preread_functions=(preread5);

# Fake a multiline prompt.
bind 'set emacs-mode-string ""';
PS1='${_[bpx_var=0, bpx_var[2]=0, 1]}> ';
function preread6 { tput cup 2 0; tput ed; };
preread_functions=(preread6);
ps1b='\#,\! \t';
ps1c='\u@\h:\w';
function postread3 {
	ps1a="($?)";
	tput sc;
	tput cup 0 0;
	printf "${ps1a}%*s\n%s" "$((COLUMNS - ${#ps1a}))" "${ps1b@P}" "${ps1c@P}";
	tput rc;
};
postread_functions=(postread3 postread2);

# Describe the command line with *wc*.
PS0='${ps0#9999}';
PS1='${_[ps0=9999, bpx_var=0, bpx_var[2]=0, 1]}\u@\h \w \$ ';
function preexec4 {
	ps0=wc:\ $(wc <<< "$rl0")$'\n\r';
};
preexec_functions=(preexec4);

# Execute the command line, and after that put it again into the new buffer.
function postread4 {
	READLINE_LINE=$rl0;
	READLINE_POINT=${#rl0};
};
postread_functions=(postread4);

# If file is readable, replace the buffer with it, and reread the buffer.
function preread6 {
	[[ -r /tmp/file.sh ]] && {
			READLINE_LINE=$(< /tmp/file.sh);
			rm -f /tmp/file.sh;
			__bpx_read_again;
	};
};
preread_functions=(preread6);

# vim: set ts=2 sw=2 tw=0 noet :
