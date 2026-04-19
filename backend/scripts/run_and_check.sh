#!/usr/bin/env bash
set -euo pipefail

ROOT=${1:-http://localhost:${PORT:-3000}}
LOG=/tmp/spl_app.log

echo "Using ROOT=$ROOT"

# kill any running node src/app.js
pids=$(pgrep -f "node src/app.js" || true)
if [ -n "$pids" ]; then
  echo "Killing previous node process(es): $pids"
  kill $pids || true
  sleep 1
fi

# start server
export NODE_ENV=${NODE_ENV:-development}
export PORT=${PORT:-3000}
echo "Starting server (NODE_ENV=$NODE_ENV PORT=$PORT)"
NODE_ENV=$NODE_ENV PORT=$PORT node src/app.js >$LOG 2>&1 &
server_pid=$!
sleep 1

# wait for server to become responsive
for i in $(seq 1 15); do
  if curl -sSf "$ROOT/" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# convenience: show last server log lines
echo "--- Server log (tail) ---"
tail -n 40 $LOG || true

failures=()

# 1) Register
REG_BODY='{"full_name":"Test User","department":"CSE","registration_number":"REG123","university_email":"test@example.com","phone_number":"0123456789"}'
echo "Registering user..."
reg_resp=$(curl -sS -X POST -H "Content-Type: application/json" -d "$REG_BODY" "$ROOT/api/auth/register" || true)
reg_code=$(echo "$reg_resp" | awk 'END{print NR}' )
# check if JSON has user_id or message
if echo "$reg_resp" | grep -q "user_id"; then
  echo "Register OK: $reg_resp"
else
  echo "Register unexpected response: $reg_resp"
fi

# 2) Send OTP and capture it from response (non-prod returns otp field)
SEND_BODY='{"phone_or_email":"test@example.com","purpose":"register"}'
echo "Sending OTP..."
otp_raw=$(curl -sS -X POST -H "Content-Type: application/json" -d "$SEND_BODY" "$ROOT/api/otp/send" || true)
otp_val=$(node -e "try{const j=JSON.parse(require('fs').readFileSync(0,'utf8')); console.log(j.otp||'');}catch(e){process.exit(0);}" <<< "$otp_raw")
if [ -n "$otp_val" ]; then
  echo "Captured OTP: $otp_val"
else
  echo "No OTP returned in response (in production this is expected) - call failed or not in dev mode: $otp_raw"
  failures+=("OTP send or capture failed")
fi

# 3) Verify OTP
if [ -n "$otp_val" ]; then
  VERIFY_BODY=$(jq -n --arg pe "test@example.com" --arg o "$otp_val" --arg p "register" '{phone_or_email:$pe, otp:$o, purpose:$p}')
  echo "Verifying OTP..."
  verify_resp=$(curl -sS -X POST -H "Content-Type: application/json" -d "$VERIFY_BODY" "$ROOT/api/otp/verify" || true)
  if echo "$verify_resp" | grep -q "OTP verified"; then
    echo "OTP verified OK"
  else
    echo "OTP verify failed: $verify_resp"
    failures+=("OTP verify failed")
  fi
fi

# 4) Set credentials
SET_BODY='{"registration_number":"REG123","username":"testuser","password":"newpassword"}'
echo "Setting credentials..."
set_resp=$(curl -sS -X POST -H "Content-Type: application/json" -d "$SET_BODY" "$ROOT/api/user/set-credentials" || true)
if echo "$set_resp" | grep -q "Credentials set"; then
  echo "Set credentials OK"
else
  echo "Set credentials response: $set_resp"
  failures+=("set-credentials failed")
fi

# 5) Login
LOGIN_BODY='{"username":"testuser","password":"newpassword"}'
echo "Logging in..."
login_resp=$(curl -sS -X POST -H "Content-Type: application/json" -d "$LOGIN_BODY" "$ROOT/api/auth/login" || true)
if echo "$login_resp" | grep -q "token"; then
  echo "Login OK: $login_resp"
else
  echo "Login failed: $login_resp"
  failures+=("login failed")
fi

# 6) Reset password
RESET_BODY='{"registration_number":"REG123","newPassword":"mynewpass"}'
echo "Resetting password..."
reset_resp=$(curl -sS -X POST -H "Content-Type: application/json" -d "$RESET_BODY" "$ROOT/api/user/reset-password" || true)
if echo "$reset_resp" | grep -q "Password updated"; then
  echo "Reset OK"
else
  echo "Reset response: $reset_resp"
  failures+=("reset-password failed")
fi

# report
if [ ${#failures[@]} -eq 0 ]; then
  echo "All checks passed ✅"
  exit 0
else
  echo "Failures:"
  for f in "${failures[@]}"; do
    echo "- $f"
  done
  echo "--- Server log (tail) ---"
  tail -n 200 $LOG || true
  exit 2
fi
