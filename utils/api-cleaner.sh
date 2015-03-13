#!/usr/bin/env bash

# What files have API's in their config that need to be cleaned prior to a git push?
files=("convert.sh" "define.sh" "goo.gl.sh" "url-title-get.sh" "wolfram.sh")
# What's the path to Pudding's dir?
path="${HOME}/PuddingBot"
# Place to store module backups
tmp="${HOME}/modules-tmp"

case "${1,,}" in
	--clean|--backup)
		if ! [ -d "${tmp}" ]; then
			mkdir "${tmp}"
		fi
		for i in "${files[@]}"; do
			find "${path}/modules" "${path}/contrib" -name "${i}" | while read q; do
				cp "${q}" "${tmp}"
				sed -i "s/^apiKey=\".*\"$/apiKey=\"\"/" "${q}"
				sed -i "s/^apiKeyToken=\".*\"$/apiKeyToken=\"\"/" "${q}"
			done
		done
	;;
	--restore)
		if ! [ -d "${tmp}" ]; then
			echo "No backups to restore from!"
			exit 255
		fi
		for i in "${files[@]}"; do
			find "${tmp}" -name "${i}" | while read q; do
				x="$(find "${path}/modules" "${path}/contrib" -name "${i}")"
				cp "${q}" "${x}"
				rm "${q}"
			done
		done
		rmdir "${tmp}"
	;;
	*)
		echo "Invalid parameter. Choices are: --clean/--backup, and --restore"
		exit 255
	;;
esac
