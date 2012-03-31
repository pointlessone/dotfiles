__exit_code_prompt_module() {
  if [[ "$LAST_EXIT_CODE" != "0" ]]; then
    echo "$C1$LAST_EXIT_CODE"
  fi
}
