#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --header='Select an action.'"
if [[ -z "$1" ]]; then
    if [ -x "$(command -v pstree)" ]; then
        action=$(printf "display\ntree\nterminate\nkill\ninterrupt\ncontinue\nstop\nquit\nhangup" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS")
    else
        action=$(printf "display\nterminate\nkill\ninterrupt\ncontinue\nstop\nquit\nhangup" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS")
    fi
else
    action="$1"
fi

[[ -z "$action" ]] && exit

FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --header='    PID USER      NI STAT COMMAND                     %CPU %MEM    VSZ   RSS     TIME'"
ps_list="$(ps -eo pid,user,nice,stat,command,%cpu,%mem,vsize,rssize,time | sed '1d')"
ps_selected=$(printf "$ps_list" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS")
[[ -z "$ps_selected" ]] && exit
ps_id="$(echo $ps_selected | sed -e 's/^ *//' -e 's/ .*//')"
ps_user="$(echo $ps_selected | sed -e 's/^ *[[:digit:]]* *//' -e 's/ .*//')"
_kill() { #{{{ _kill SIG PID USER
    if [[ "$3" == "root" ]]; then
        if [ -x "$(command -v sudo)" ]; then
            tmux split-window -v -p 30 -b -c '#{pane_current_path}' "bash -c 'sudo kill -s $1 $2'"
        elif [ -x "$(command -v doas)" ]; then
            tmux split-window -v -p 30 -b -c '#{pane_current_path}' "bash -c 'doas kill -s $1 $2'"
        fi
    else
        kill -s $1 $2
    fi
} #}}}
if [[ "$action" == "display" ]]; then
    tmux split-window -v -p 50 -b -c '#{pane_current_path}' "top -p $ps_id"
elif [[ "$action" == "tree" ]]; then
    pstree -p "$ps_id"
elif [[ "$action" == "terminate" ]]; then
    _kill TERM $ps_id $ps_user
elif [[ "$action" == "kill" ]]; then
    _kill KILL $ps_id $ps_user
elif [[ "$action" == "interrupt" ]]; then
    _kill INT $ps_id $ps_user
elif [[ "$action" == "continue" ]]; then
    _kill CONT $ps_id $ps_user
elif [[ "$action" == "stop" ]]; then
    _kill STOP $ps_id $ps_user
elif [[ "$action" == "quit" ]]; then
    _kill QUIT $ps_id $ps_user
elif [[ "$action" == "hangup" ]]; then
    _kill HUP $ps_id $ps_user
fi
