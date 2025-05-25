#!/bin/sh

# USAGE: ./$0 <backup_name> <dest> <filelist>

duplicity "${HOME}" \
	  --name "$1" \
	  --progress \
	  --asynchronous-upload \
	  --backend-retry-delay 45 \
	  --copy-links \
	  --include-filelist "$3" \
	  "$2"
