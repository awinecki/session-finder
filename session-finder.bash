#!/usr/bin/env bash
set -e
cmd=$1
prompt="find/create session> "
tmux='/usr/bin/env tmux'
debug=
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$cmd" = "debug" ]; then
	debug=true
	cmd=$2
fi

session_status() {
	MAX=10
	counter=0
	colors=(yellow red green blue magenta cyan white)
	$tmux ls -F '#{session_attached} #{session_last_attached}#{?session_last_attached,,0} #{session_created} #{session_id} #{session_windows} #{session_name}' \
		| sort -r | cut -d' ' -f6- | head -n $MAX | while read line; do
		local colori=$(expr $counter % ${#colors})
		# TODO consider width of current window
		if [ "$counter" = 0 ]; then
			echo -n "#[bg=${colors[$colori]},fg=default]${line}#[bg=default]"
		else
			# Uncomment this string to show other session names as well
			echo -n "|#[fg=${colors[$colori]}]${line}#[fg=default,bg=default]"
		fi
		local counter=$((counter + 1))
	done
}

session_last() {
	$tmux switch-client -l && {
		sleep 0.1
		$tmux refresh-client -S
	} || true
}

session_prev() {
	$tmux switch-client -p && {
		sleep 0.1
		$tmux refresh-client -S
	} || true
}

session_next() {
	$tmux switch-client -n && {
		sleep 0.1
		$tmux refresh-client -S
	} || true
}

get_fzf_out() {
	fzf_out=$(
		$tmux ls -F '#{?session_attached,◎, } #{session_name}' \
		| sort -r \
    | fzf --print-query --prompt="$prompt" --border=rounded \
        --margin=15% --padding=3% --prompt='  ◎ ' --pointer=' ' \
				--info=hidden \
        --color='bg+:-1,fg+:114,hl+:36,fg:248,hl:243,info:239,header:65' \
				--preview='fortune | cowsay -f moose | lolcat' \
	|| true)
	echo "$fzf_out"
}

session_finder() {
	local fzf_out=$(get_fzf_out)
	line_count=$(echo "$fzf_out" | wc -l)
	session_name="$(echo "$fzf_out" | tail -n1 | perl -pe 's/^[\* ] //')"
	command=$(echo "$session_name" | awk '{ print $1 }')

	if [ $line_count -eq 1 ]; then
		unset TMUX
		word_count=$(echo "$fzf_out" | wc -w)
		if [ $word_count -eq 1 ]; then
			$tmux new-session -d -s "$session_name"
			$tmux switch-client -t "$session_name"
		else
			session_name="$(echo "$fzf_out" | tail -n1 | awk '{ print $2 }')"
			case "$command" in
				":new")
					$tmux new-session -d -s "$session_name"
					$tmux switch-client -t "$session_name"
					;;
				":rename")
					$tmux rename-session "$session_name"
					;;
			esac
		fi
	else
		$tmux switch-client -t "$session_name"
	fi
	sleep 0.1
	$tmux refresh-client -S
}

case "$cmd" in
	status)
		session_status
		;;
	finder)
		session_finder
		;;
	next)
		session_next
		;;
	prev)
		session_prev
		;;
	last)
		session_last
		;;
	*)
		exit 1
		;;
esac
