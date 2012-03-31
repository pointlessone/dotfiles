# vim: filetype=sh

# This code originally taken from https://github.com/lvv/git-prompt
# Copyright belongs to corresponding authors.
# All modifications (c) Alexander [cheba] Mankuta

__git_prompt_module() {

  [[ $git_ignore_dir_list =~ $PWD ]] && return

  ###################################################################   CONFIG

  local init_git_color clean_git_color
  local modified_git_color added_git_color addmoded_git_color untracked_git_color unmerged_git_color op_git_color detached_git_color hex_git_color

  #conf=git-prompt.conf;                   [[ -r $conf ]]  && . $conf
  #conf=/etc/git-prompt.conf;              [[ -r $conf ]]  && . $conf
  #conf=~/.git-prompt.conf;                [[ -r $conf ]]  && . $conf
  #conf=~/.config/git-prompt.conf;         [[ -r $conf ]]  && . $conf
  #unset conf


  #####  set defaults if not set

  local error_bell=${error_bell:-off}

  #### git colors
          init_git_color=${init_git_color:-WHITE}        # initial
          clean_git_color=${clean_git_color:-blue}        # nothing to commit (working directory clean)
      modified_git_color=${modified_git_color:-orange}      # Changed but not updated:
          added_git_color=${added_git_color:-green}       # Changes to be committed:
      addmoded_git_color=${addmoded_git_color:-yellow}
      untracked_git_color=${untracked_git_color:-BLUE}    # Untracked files:
      unmerged_git_color=${unmerged_git_color:-red}
            op_git_color=${op_git_color:-MAGENTA}
      detached_git_color=${detached_git_color:-RED}

            hex_git_color=${hex_git_color:-BLACK}         # gray


  local max_file_list_length=${max_file_list_length:-100}
  local count_only=${count_only:-on}
  local rawhex_len=${rawhex_len:-6}


  #####################################################################  post config

  ################# terminfo colors-16
  #
  #       black?    0 8
  #       red       1 9
  #       green     2 10
  #       yellow    3 11
  #       blue      4 12
  #       magenta   5 13
  #       cyan      6 14
  #       white     7 15
  #
  #       terminfo setaf/setab - sets ansi foreground/background
  #       terminfo sgr0 - resets all attributes
  #       terminfo colors - number of colors
  #
  #################  Colors-256
  #  To use foreground and background colors:
  #       Set the foreground color to index N:    \033[38;5;${N}m
  #       Set the background color to index M:    \033[48;5;${M}m
  # To make vim aware of a present 256 color extension, you can either set
  # the $TERM environment variable to xterm-256color or use vim's -T option
  # to set the terminal. I'm using an alias in my bashrc to do this. At the
  # moment I only know of two color schemes which is made for multi-color
  # terminals like urxvt (88 colors) or xterm: inkpot and desert256,

  ### if term support colors,  then use color prompt, else bold

  local      black='\['`tput sgr0; tput setaf 0`'\]'
  local        red='\['`tput sgr0; tput setaf 1`'\]'
  local      green='\['`tput sgr0; tput setaf 2`'\]'
  local     yellow='\['`tput sgr0; tput setaf 3`'\]'
  local       blue='\['`tput sgr0; tput setaf 4`'\]'
  local    magenta='\['`tput sgr0; tput setaf 5`'\]'
  local       cyan='\['`tput sgr0; tput setaf 6`'\]'
  local      white='\['`tput sgr0; tput setaf 7`'\]'
  local     orange='\e[38;5;214m'

  local      BLACK='\['`tput setaf 0; tput bold`'\]'
  local        RED='\['`tput setaf 1; tput bold`'\]'
  local      GREEN='\['`tput setaf 2; tput bold`'\]'
  local     YELLOW='\['`tput setaf 3; tput bold`'\]'
  local       BLUE='\['`tput setaf 4; tput bold`'\]'
  local    MAGENTA='\['`tput setaf 5; tput bold`'\]'
  local       CYAN='\['`tput setaf 6; tput bold`'\]'
  local      WHITE='\['`tput setaf 7; tput bold`'\]'

  local        dim='\['`tput sgr0; tput setaf p1`'\]'  # half-bright

  local    bw_bold='\['`tput bold`'\]'

  local on=''
  local off=': '
  local bell="\[`eval ${!error_bell} tput bel`\]"
  local colors_reset='\['`tput sgr0`'\]'

  # replace symbolic colors names to raw treminfo strings
        init_git_color=${!init_git_color}
    modified_git_color=${!modified_git_color}
    unmerged_git_color=${!unmerged_git_color}
  untracked_git_color=${!untracked_git_color}
      clean_git_color=${!clean_git_color}
      added_git_color=${!added_git_color}
          op_git_color=${!op_git_color}
    addmoded_git_color=${!addmoded_git_color}
    detached_git_color=${!detached_git_color}
        hex_git_color=${!hex_git_color}

  #######  work around for MC bug.
  #######  specifically exclude emacs, want full when running inside emacs
  #if   [[ -z "$TERM"   ||  ("$TERM" = "dumb" && -z "$INSIDE_EMACS")  ||  -n "$MC_SID" ]];   then
  #        unset PROMPT_COMMAND
  #        PS1="\w$prompt_char "
  #        return 0
  #fi

  ####################################################################  MARKERS
  if [[ $LC_CTYPE =~ "UTF" && $TERM != "linux" ]]; then
    local elipses_marker="…"
  else
    local elipses_marker="..."
  fi


  local   file_list modified_files deleted_files untracked_files staged_added_files unmerged_files staged_deleted_files
  local   git_info
  local   status modified untracked added init detached

  # TODO add status: LOCKED (.git/index.lock)

  local git_dir=`git rev-parse --git-dir 2> /dev/null`

  [[ -n ${git_dir/./} ]] || return  1

  ##########################################################   GIT STATUS
  local file_regex='\(.*\)' # '\([^/ ]*\/\{0,1\}\).*'
  staged_added_files=()
  staged_deleted_files=()
  modified_files=()
  deleted_files=()
  unmerged_files=()
  untracked_files=()
  local freshness="$dim"
  local branch status modified added clean init added mixed untracked op detached

  # quoting hell
  eval " $(
    git status 2>/dev/null |
      sed -n '
        s/^# On branch /branch=/p
        s/^nothing to commi.*/clean=clean/p
        s/^# Initial commi.*/init=init/p

        s/^# Your branch is ahead of .[/[:alnum:]]\+. by [[:digit:]]\+ commit.*/freshness=${WHITE}↑/p
        s/^# Your branch is behind .[/[:alnum:]]\+. by [[:digit:]]\+ commit.*/freshness=${YELLOW}↓/p
        s/^# Your branch and .[/[:alnum:]]\+. have diverged.*/freshness=${YELLOW}↕/p

        /^# Changes to be committed:/,/^# [A-Z]/ {
          s/^# Changes to be committed:/added=added;/p

          s/^#	modified:   '"$file_regex"'/	[[ \" ${staged_added_files[*]} \" =~ \" \1 \" ]] || staged_added_files[${#staged_added_files[@]}]=\"\1\"/p
          s/^#	new file:   '"$file_regex"'/	[[ \" ${staged_added_files[*]} \" =~ \" \1 \" ]] || staged_added_files[${#staged_added_files[@]}]=\"\1\"/p
          s/^#	renamed:[^>]*> '"$file_regex"'/	[[ \" ${staged_added_files[*]} \" =~ \" \1 \" ]] || staged_added_files[${#staged_added_files[@]}]=\"\1\"/p
          s/^#	copied:[^>]*> '"$file_regex"'/ 	[[ \" ${staged_added_files[*]} \" =~ \" \1 \" ]] || staged_added_files[${#staged_added_files[@]}]=\"\1\"/p
          s/^#	deleted:    '"$file_regex"'/	[[ \" ${staged_deleted_files[*]} \" =~ \" \1 \" ]] || staged_deleted_files[${#staged_deleted_files[@]}]=\"\1\"/p
        }

        /^# Changed but not updated:/,/^# [A-Z]/ {
          s/^# Changed but not updated:/modified=modified;/p
          s/^#	modified:   '"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
          s/^#	unmerged:   '"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
          s/^#	deleted:    '"$file_regex"'/	[[ \" ${deleted_files[*]} \" =~ \" \1 \" ]] || deleted_files[${#deleted_files[@]}]=\"\1\"/p
        }

        /^# Changes not staged for commit:/,/^# [A-Z]/ {
          s/^# Changes not staged for commit:/modified=modified;/p
          s/^#	modified:   '"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
          s/^#	unmerged:   '"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
          s/^#	deleted:    '"$file_regex"'/	[[ \" ${deleted_files[*]} \" =~ \" \1 \" ]] || deleted_files[${#deleted_files[@]}]=\"\1\"/p
        }

        /^# Unmerged paths:/,/^[^#]/ {
          s/^# Unmerged paths:/modified=modified;/p
          s/^#	both modified:\s*'"$file_regex"'/	[[ \" ${unmerged_files[*]} \" =~ \" \1 \" ]] || unmerged_files[${#unmerged_files[@]}]=\"\1\"/p
        }

        /^# Untracked files:/,/^[^#]/{
          s/^# Untracked files:/untracked=untracked;/p
          s/^#	'"$file_regex"'/		[[ \" ${untracked_files[*]} ${modified_files[*]} ${added_files[*]} \" =~ \" \1 \" ]] || untracked_files[${#untracked_files[@]}]=\"\1\"/p
        }
      '
  )"

  if  ! grep -q "^ref:" $git_dir/HEAD  2>/dev/null;   then
    detached=detached
  fi


  #################  GET GIT OP

  unset op
  local op

  if [[ -d "$git_dir/.dotest" ]] ;  then
    if [[ -f "$git_dir/.dotest/rebasing" ]] ;  then
      op="rebase"
    elif [[ -f "$git_dir/.dotest/applying" ]] ; then
      op="am"
    else
      op="am/rebase"
    fi
  elif  [[ -f "$git_dir/.dotest-merge/interactive" ]] ;  then
    op="rebase -i"
    # ??? branch="$(cat "$git_dir/.dotest-merge/head-name")"

  elif  [[ -d "$git_dir/.dotest-merge" ]] ;  then
    op="rebase -m"
    # ??? branch="$(cat "$git_dir/.dotest-merge/head-name")"

  # lvv: not always works. Should  ./.dotest  be used instead?
  elif  [[ -f "$git_dir/MERGE_HEAD" ]] ;  then
    op="merge"
    # ??? branch="$(git symbolic-ref HEAD 2>/dev/null)"
  elif  [[ -f "$git_dir/index.lock" ]] ;  then
    op="locked"
  else
    [[  -f "$git_dir/BISECT_LOG"  ]]   &&  op="bisect"
    # ??? branch="$(git symbolic-ref HEAD 2>/dev/null)" || \
    #    branch="$(git describe --exact-match HEAD 2>/dev/null)" || \
    #    branch="$(cut -c1-7 "$git_dir/HEAD")..."
  fi


  ####  GET GIT HEX-REVISION
  local rawhex
  if  [[ $rawhex_len -gt 0 ]] ;  then
    rawhex=`git rev-parse HEAD 2>/dev/null`
    rawhex=${rawhex/HEAD/}
    rawhex="$white=$hex_git_color${rawhex:0:$rawhex_len}"
  else
    rawhex=""
  fi

  #### branch
  local branch=${branch/master/M}

  # another method of above:
  # branch=$(git symbolic-ref -q HEAD || { echo -n "detached:" ; git name-rev --name-only HEAD 2>/dev/null; } )
  # branch=${branch#refs/heads/}

  ### compose git_info

  local git_info

  if [[ $init ]];  then
    git_info=${white}init
  else
    if [[ "$detached" ]] ;  then
      branch="<detached:`git name-rev --name-only HEAD 2>/dev/null`"
    elif [[ "$op" ]];  then
      branch="$op:$branch"
      if [[ "$op" == "merge" ]] ;  then
        branch+="<--$(git name-rev --name-only $(<$git_dir/MERGE_HEAD))"
      fi
      #branch="<$branch>"
    fi
    git_info="$branch$freshness$rawhex"
  fi


  ### status:  choose primary (for branch color)
  unset status
  local status
  status=${op:+op}
  status=${status:-$detached}
  status=${status:-$clean}
  status=${status:-$modified}
  status=${status:-$added}
  status=${status:-$untracked}
  status=${status:-$init}
                          # at least one should be set
                          : ${status?prompt internal error: git status}
  eval local git_color="\${${status}_git_color}"
                          # no def:  git_color=${git_color:-$WHITE}    # default


  ### file list
  unset file_list
  local file_list
  if [[ $count_only = "on" ]] ; then
    [[ ${staged_added_files[0]}   ]]  &&  file_list+=" "${added_git_color}+${#staged_added_files[@]}
    [[ ${staged_deleted_files[0]} ]]  &&  file_list+=" "${added_git_color}-${#staged_deleted_files[@]}
    [[ ${modified_files[0]}       ]]  &&  file_list+=" "${modified_git_color}*${#modified_files[@]}
    [[ ${deleted_files[0]}        ]]  &&  file_list+=" "${modified_git_color}-${#deleted_files[@]}
    [[ ${unmerged_files[0]}       ]]  &&  file_list+=" "${unmerged_git_color}${#unmerged_files[@]}!
    [[ ${untracked_files[0]}      ]]  &&  file_list+=" "${untracked_git_color}${#untracked_files[@]}?
  else
    [[ ${staged_added_files[0]}   ]]  &&  file_list+=" "$added_git_color${staged_added_files[@]}
    [[ ${staged_deleted_files[0]} ]]  &&  file_list+=" "$added_git_color${staged_deleted_files[@]/#/-}
    [[ ${modified_files[0]}       ]]  &&  file_list+=" "$modified_git_color${modified_files[@]}
    [[ ${deleted_files[0]}        ]]  &&  file_list+=" "$modified_git_color${deleted_files[@]/#/-}
    [[ ${unmerged_files[0]}       ]]  &&  file_list+=" "$unmerged_git_color${unmerged_files[@]}
    [[ ${untracked_files[0]}      ]]  &&  file_list+=" "$untracked_git_color${untracked_files[@]}
  fi

  if [[ ${#file_list} -gt $max_file_list_length ]]  ;  then
    file_list=${file_list:0:$max_file_list_length}
    if [[ $max_file_list_length -gt 0 ]]  ;  then
      file_list="${file_list% *} $elipses_marker"
    fi
  fi


  local head_local="$git_color${git_info}$git_color${file_list}$git_color$colors_reset"

  echo $head_local
}
