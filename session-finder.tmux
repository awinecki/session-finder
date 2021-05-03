#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmux bind -n C-f neww "$CURRENT_DIR/session-finder.bash finder"
