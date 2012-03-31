# root colors & prompt
C1="\[\033[0;31m\]"
C2="\[\033[1;30m\]"
C3="\[\033[0m\]"
C4="\[\033[0;36m\]"

for f in $HOME/.bash/exts/prompt/*; do
  source $f
done

__modular_prompt() {

  local LAST_EXIT_CODE="$?"

  local default_prompt_modules="exit_code who_and_where time pwd git"
  PROMP_MODULES=${PROMP_MODULES:-$default_prompt_modules}

  #write to history whenever the prompt is displayed
  history -a


  local ps=""
  for mod in $PROMP_MODULES; do
    if [[ "x$(type -t "__${mod}_prompt_module")" != 'x' ]]; then
      local result="$(__${mod}_prompt_module)"

      if [[ -n $result ]]; then
        if [[ -z $ps ]]; then
          ps="$C2(${result}$C2)"
        else
          ps="${ps}$C2*(${result}$C2)"
        fi
      fi
    fi
  done

  PS1="$ps\n${C2}-${C1}=>>${C3} "
}

PROMPT_COMMAND=__modular_prompt
PS2="  $C2-${C1}>${C3} "
