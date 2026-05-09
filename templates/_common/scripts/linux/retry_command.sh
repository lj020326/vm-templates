#!/bin/bash

# retry_command.sh: A script to retry a given command multiple times.

# Configuration
MAX_RETRIES=${RETRY_MAX_ATTEMPTS:-5}  # Max number of attempts, default to 5
RETRY_DELAY=${RETRY_SLEEP_SECONDS:-10} # Delay between retries in seconds, default to 10

# Check if a command was provided using the argument count
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <command_to_retry> [args...]"
  echo "  Example: $0 ansible-galaxy collection install -r requirements.yml"
  exit 1
fi

COMMAND_TO_RUN="${*}"
CURRENT_RETRY=0

echo "Starting retry wrapper for: '$COMMAND_TO_RUN'"

while [ $CURRENT_RETRY -lt $MAX_RETRIES ]; do
  echo "Attempt $((CURRENT_RETRY + 1))/$MAX_RETRIES..."
  if eval "$COMMAND_TO_RUN"; then
    echo "Command '$COMMAND_TO_RUN' succeeded."
    exit 0 # Success
  else
    echo "Command '$COMMAND_TO_RUN' failed. Retrying in $RETRY_DELAY seconds..."
    CURRENT_RETRY=$((CURRENT_RETRY + 1))
    sleep "$RETRY_DELAY"
  fi
done

echo "Command '$COMMAND_TO_RUN' failed after $MAX_RETRIES attempts."
exit 1 # Failure
