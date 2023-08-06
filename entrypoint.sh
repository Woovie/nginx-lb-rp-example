#!/bin/sh
sed -i "s/PROXY_ID_PLACEHOLDER/$PROXY_ID/g" /usr/share/nginx/html/index.html
nginx -g 'daemon off;'