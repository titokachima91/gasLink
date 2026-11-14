#!/bin/zsh
# Sends the current build status to 0714604777 every 10 minutes until the
# final flag is present. The final message is sent explicitly by the operator.
set -u
cd /Users/apple/gaslink_app
GATEWAY="/Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox"
while true; do
  sleep 600
  if [ -f build_logs/progress_done.flag ]; then
    break
  fi
  STATUS="$(cat build_logs/progress_status.txt 2>/dev/null || print 'GasLink: still working.')"
  node "$GATEWAY/scripts/send-operator-sms.js" "$STATUS" >> build_logs/progress_sms.log 2>&1
done
