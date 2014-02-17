#!/usr/bin/env bash

clear
echo "Please enter password to hash:"
read -p "> " pass
echo ""
hash="$(echo "${pass}" | md5sum | awk '{print $1}')"
echo "MD5 hash of \"${pass}\": ${hash}"
echo ""
exit 0
