#!/bin/sh
set -eu
# Substitute the runtime API URL in the JSON template.
export API_URL="${API_URL:-http://localhost:8080/books-api/}"
envsubst '${API_URL}' < /usr/share/nginx/html/assets/env.template.json > /usr/share/nginx/html/assets/env.json
# Run Nginx in the foreground.
exec nginx -g 'daemon off;'
