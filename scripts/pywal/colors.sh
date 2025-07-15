#!/bin/bash

input_file="$HOME/.cache/wal/colors.sh"

background=$(grep 'background=' "$input_file" | cut -d'=' -f2 | tr -d '"')
foreground=$(grep 'foreground=' "$input_file" | cut -d'=' -f2 | tr -d '"')
cursor=$(grep 'cursor=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color0=$(grep 'color0=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color1=$(grep 'color1=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color2=$(grep 'color2=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color3=$(grep 'color3=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color4=$(grep 'color4=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color5=$(grep 'color5=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color6=$(grep 'color6=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color7=$(grep 'color7=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color8=$(grep 'color8=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color9=$(grep 'color9=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color10=$(grep 'color10=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color11=$(grep 'color11=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color12=$(grep 'color12=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color13=$(grep 'color13=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color14=$(grep 'color14=' "$input_file" | cut -d'=' -f2 | tr -d '"')
color15=$(grep 'color15=' "$input_file" | cut -d'=' -f2 | tr -d '"')

# Poistetaan ylimääräiset lainausmerkit
background=${background//\'/}
foreground=${foreground//\'/}
cursor=${cursor//\'/}
color0=${color0//\'/}
color1=${color1//\'/}
color2=${color2//\'/}
color3=${color3//\'/}
color4=${color4//\'/}
color5=${color5//\'/}
color6=${color6//\'/}
color7=${color7//\'/}
color8=${color8//\'/}
color9=${color9//\'/}
color10=${color10//\'/}
color11=${color11//\'/}
color12=${color12//\'/}
color13=${color13//\'/}
color14=${color14//\'/}
color15=${color15//\'/}

printf "\n"
printf "{background} %s\n" "$background"
printf "{foreground} %s\n" "$foreground"
printf "{cursor}     %s\n" "$cursor"
printf "\n"
printf "{color0}     \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 0 "$color0"
printf "{color1}     \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 1 "$color1"
printf "{color2}     \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 2 "$color2"
printf "{color3}     \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 3 "$color3"
printf "{color4}     \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 4 "$color4"
printf "{color5}     \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 5 "$color5"
printf "{color6}     \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 6 "$color6"
printf "{color7}     \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 0 7 "$color7"
printf "{color8}     \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 8 "$color8"
printf "{color9}     \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 9 "$color9"
printf "{color10}    \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 10 "$color10"
printf "{color11}    \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 11 "$color11"
printf "{color12}    \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 12 "$color12"
printf "{color13}    \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 13 "$color13"
printf "{color14}    \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 15 14 "$color14"
printf "{color15}    \033[38;5;%dm\033[48;5;%dm%s\033[0m\n" 0 15 "$color15"
