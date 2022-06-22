#!/usr/bin/env bash

# configuration
# -------------

# default number of images to download per class.
DEFAULT_NUM=10

# ImageNet API URL.
API_URL='https://www.image-net.org/api/imagenet.synset.geturls'

# command-line parsing
# --------------------

while getopts 'n:h' opt; do
	case "$opt" in
		n) num="$OPTARG" ;;
		h) { cat <<EOF
Usage: $0 [-n NUM] WNID1 WNID2 ...
Scrapes images from the classes corresponding to the input WordNet IDs.

Examples:
	$0 -n '5' 'n01440764' 'n01443537'
	$0 -n '150' < 'wnids_file.txt'

Options:
	-n	Number of images to download per class (default: 10).
	-h	Print this help message and exit.
EOF
		     exit 0; } ;;
		*) cat <<<"See $0 -h for more details." && exit 1 ;;
	esac
done
shift $((OPTIND - 1))

# check for requirements
# ----------------------

wget --version > /dev/null || {
	cat <<<"Please install Wget and try again."
	exit 1
}
parallel --version > /dev/null || {
	cat <<<"Please install Parallel and try again."
	exit 1
}

# Number of images to download per class.
# If num is not set, use DEFAULT_NUM. Boost this number by a factor of 1.33.
num=$(( 4 * "${num:-$DEFAULT_NUM}" / 3 ))

# download images for the class corresponding to the given WordNet ID
download_wnid() {

	local wnid="$1"    # WordNet ID
	local num="$2"	   # number of images

	# make a directory for this class
	mkdir "$wnid" && cd "$wnid"

	# retrieve a list of image URLs from image-net.org, retain only the flickr URLs (as they are
	# the most reliable), convert the http connections to https (if we use the raw http URLs
	# a redirect with the same effect almost always takes place), and follow these URLs to download
	# images.
	wget -q -i <(wget "$API_URL?wnid=$wnid" -q -O - | grep -m "$num" 'flickr' | sed 's/http/https/')

	# we will observe that wget almost always returns a non-zero exit code (a code of 8, in fact) due
	# to 404 and other errors caused by missing images.
	# however, we don't want to this to be registered as an error per-se, hence we exit with code 0
	# to indicate success.
	return 0
}

export -f download_wnid

# scraping
# --------

if [[ -z $* ]]; then
	parallel --bar "download_wnid {} $num" < /dev/stdin
else
	parallel --bar "download_wnid {} $num" < <(IFS=$'\n'; echo "$*")
fi
