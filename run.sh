#!/bin/bash

#check if the Fleep webhook URL was provided
if [[ -z "$WERCKER_FLEEP_WEBHOOK_NOTIFY_URL" ]]; then
  fail "Error: \$FLEEP_WEBHOOK_URL not set."
fi

if [[ -n "$DEPLOY" ]]; then
  # it's a deploy!
  export ACTION="deploy"
  export ACTION_URL="${WERCKER_DEPLOY_URL}"
else
  # it's a build!
  export ACTION="build"
  export ACTION_URL="${WERCKER_BUILD_URL}"
fi

if [[ "$WERCKER_RESULT" == "failed" ]]; then
  export RESULT_EMOJI='❌'
elif [[ "$WERCKER_RESULT" == "passed" ]]; then
  export RESULT_EMOJI='✅'
else
  export RESULT_EMOJI=''
fi

export RESULT_UPCASE=$(echo "$WERCKER_RESULT" | tr [:lower:] [:upper:])

export WERCKER_FLEEP_WEBHOOK_NOTIFY_MESSAGE_TEXT="$RESULT_EMOJI  *$RESULT_UPCASE*: $WERCKER_STARTED_BY ran a *$ACTION* step for _'$WERCKER_APPLICATION_NAME'_ which *$WERCKER_RESULT*.  $RESULT_EMOJI
$ACTION_URL"

# curl -d "message=${WERCKER_FLEEP_WEBHOOK_NOTIFY_MESSAGE_TEXT}" -d "user=Wercker" "${WERCKER_FLEEP_WEBHOOK_NOTIFY_URL}"

# post the result to the Fleep webhook
RESULT=$(curl -d "message=${WERCKER_FLEEP_WEBHOOK_NOTIFY_MESSAGE_TEXT}" -d "user=Wercker" -s "$WERCKER_FLEEP_WEBHOOK_NOTIFY_URL" --output "$WERCKER_STEP_TEMP"/result.txt -w "%{http_code}")
cat "$WERCKER_STEP_TEMP/result.txt"

if [ "$RESULT" = "500" ]; then
  if grep -Fqx "No token" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No token is specified."
  fi

  if grep -Fqx "No hooks" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No hook can be found for specified subdomain/token"
  fi

  if grep -Fqx "Invalid channel specified" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "Could not find specified channel for subdomain/token."
  fi

  if grep -Fqx "No text specified" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No text specified."
  fi
fi

if [ "$RESULT" = "404" ]; then
  fail "Subdomain or token not found."
fi

exit 0
