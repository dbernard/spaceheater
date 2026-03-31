# bash completion for spaceheater

_spaceheater() {
  local cur prev words cword
  _init_completion || return

  local commands="create list start stop clean delete config schedule version help"

  # Complete first argument (command)
  if [ $cword -eq 1 ]; then
    COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
    return
  fi

  # Complete based on command
  case "${words[1]}" in
    create)
      # Suggest numbers for create command
      if [ $cword -eq 2 ]; then
        COMPREPLY=( $(compgen -W "1 2 3" -- "${cur}") )
      fi
      ;;
    clean)
      # Suggest common day values for clean command
      if [ $cword -eq 2 ]; then
        COMPREPLY=( $(compgen -W "7 14 30 60 90" -- "${cur}") )
      fi
      ;;
    start|stop|delete)
      # Could potentially list codespace names here
      # For now, just return empty
      COMPREPLY=()
      ;;
    schedule)
      if [ $cword -eq 2 ]; then
        COMPREPLY=( $(compgen -W "set list remove status help" -- "${cur}") )
      elif [ $cword -eq 3 ] && [ "${words[2]}" = "set" ]; then
        COMPREPLY=( $(compgen -W "1 2 3" -- "${cur}") )
      elif [ "${prev}" = "--preset" ]; then
        COMPREPLY=( $(compgen -W "weekday-morning weekday-evening weekday-hourly hourly daily twice-daily" -- "${cur}") )
      elif [[ "${cur}" == --* ]]; then
        COMPREPLY=( $(compgen -W "--preset --hour --minute --weekday --json" -- "${cur}") )
      fi
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}

complete -F _spaceheater spaceheater
