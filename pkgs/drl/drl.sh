#!@bash@/bin/bash
set -e
enable -f @bash@/lib/bash/realpath realpath
destDir="${XDG_DATA_HOME:-$HOME/.local/share}/drl"
oldPath="$PATH"
PATH="@coreutils@/bin"
mkdir -p "$destDir"
shopt -s extglob
for file in @out@/share/drl/!(drl); do
	baseFile="${file##*/}"
	destFile="$destDir/$baseFile"
	if [[ -L "$destFile" && "$(realpath "$destFile")" == "$NIX_STORE"* ]]; then
		rm "$destFile"
	fi
	if [[ ! -e "$destFile" ]]; then
		if [[ "$baseFile" == @(config.lua|colors.lua|screenshot|mortem|backup) ]]; then
			cp -Lr --no-preserve=all "$file" "$destFile"
		elif [[ "$baseFile" == 'modules' ]]; then
			mkdir -p "$destFile"
			for subFile in "$file"/*; do
				baseSubFile="${subFile##*/}"
				destSubFile="$destFile/$baseSubFile"
				if [[ -L "$destSubFile" && "$(realpath "$destSubFile")" == "$NIX_STORE"* ]]; then
					rm "$destSubFile"
				fi
				if [[ ! -e "$destSubFile" ]]; then
					ln -s "$subFile" "$destFile"/
				fi
			done
		else
			ln -s "$file" "$destDir"/
		fi
	fi
done
shopt -u extglob
PATH="$oldPath"
cd "$destDir"
exec -a drl @out@/share/drl/drl "$@"
