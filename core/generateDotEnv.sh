#! /bin/bash

SERVER_ORIGIN=$1
DOT_ENV_FILE_PATH=$2

function setRandom() {
  RND=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $1 | head -1)
}

setRandom 32
CLIENT_ID=$RND 
setRandom 32
CLIENT_SECRET=$RND 
setRandom 32
SESSION_SECRET=$RND

echo "CLIENT_ID: $CLIENT_ID"
echo "CLIENT_SECRET: $CLIENT_SECRET"

cat <<EOF > ${DOT_ENV_FILE_PATH}
SERVER_PORT=3001
SERVER_ORIGIN=${SERVER_ORIGIN}
TLS_KEY_PATH='cert/server.key'
TLS_CERT_PATH='cert/server.crt'

SESSION_SECRET='${SESSION_SECRET}'
CLIENT_ID='${CLIENT_ID}'
CLIENT_SECRET='${CLIENT_SECRET}'

API_SERVER_ORIGIN='https://xlogin.jp'
AUTH_SERVER_ORIGIN='https://xlogin.jp'
EOF

