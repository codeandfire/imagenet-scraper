#!/usr/bin/env bash

# configuration
# -------------

# default number of images to download per class.
DEFAULT_NUM=10

# ImageNet API URL.
API_URL='https://www.image-net.org/api/imagenet.synset.geturls'

# parse command line options
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

# check that requirements are installed
wget --version > /dev/null || {
	cat <<<"Please install Wget and try again."
	exit 1
}
parallel --version > /dev/null || {
	cat <<<"Please install Parallel and try again."
	exit 1
}

# if we set out to download N images, we will find that approx. 25% of these N images are no longer
# available.
# therefore a solution is to increase the number of images to download by a factor of 4/3, which
# means that after a loss of 25% of these 4N/3 images, we will have around N images left.
num=$(( 4 * "${num:-$DEFAULT_NUM}" / 3 ))

# download images for the class corresponding to the given WordNet ID
download_wnid() {

	# WordNet ID
	local wnid="$1"

	# number of images
	local num="$2"

	# make a directory for this class
	mkdir "$wnid"

	cd "$wnid"

	# retrieve a list of image URLs from image-net.org, retain only the flickr URLs (as they are
	# the most reliable), convert the http connections to https (if we use the raw http URLs
	# a redirect with the same effect almost always takes place), and follow these URLs to download
	# images.
	wget -q -i <(wget "$API_URL?wnid=$wnid" -q -O - | \
		grep -m "$num" 'flickr' | sed 's/http/https/')

	# we will observe that wget almost always returns a non-zero exit code (a code of 8, in fact) due
	# to 404 and other errors caused by missing images.
	# however, we don't want to this to be registered as an error per-se, hence we exit with code 0
	# to indicate success.
	return 0
}

export -f download_wnid

# download images for the various classes in a parallel manner.
# (within a class the images are downloaded serially, but across classes there is parallelization.)
if [[ -z $* ]]; then
	parallel --bar "download_wnid {} $num" < /dev/stdin
else
	(IFS=$'\n'; echo "$*") | parallel --bar "download_wnid {} $num"
fi
