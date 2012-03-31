__bundler_status() {

  local red='\['`tput sgr0; tput setaf 1`'\]'
  local green='\['`tput sgr0; tput setaf 2`'\]'
  local colors_reset='\['`tput sgr0`'\]'

  [[ -x `which bundle` ]] || return 1

  bundle check >/dev/null 2>/dev/null

  local rc="$?"

  local status

  if [[ "$rc" == "0" ]]; then
    status="${green}bundled${color_reset}"
  elif [[ "$rc" == "1" ]]; then
    status="${red}bundle now!${color_reset}"
  else
    status=""
  fi

  echo $status
}
