#!/usr/bin/bash

__help() {
	echo "usage: \"$1 [-h/-i/-b]\" or \"$1\""
	echo "   -h  --help   display this help message"
	echo "   -i  --info   get jekyll-theme-chirpy info"
	echo "   -b  --bund   bundle neccesary packages"
	echo "         null   exec jekyll"
}

if [ x"$1" != x ]; then
	opt="$1"
	case $opt in
	-h | --help)
		__help $0
		exit 0
		;;
	-i | --info)
		bundle info --path jekyll-theme-chirpy
		exit 0
		;;
	-b)
		bundle
		exit 0
		;;
	*)
		__help $0
		exit 0
		;;
	esac
fi

bundle exec jekyll s