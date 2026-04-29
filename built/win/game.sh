#!/bin/sh
printf '\033c\033]0;%s\a' dugeon_generator
base_path="$(dirname "$(realpath "$0")")"
"$base_path/game" "$@"
