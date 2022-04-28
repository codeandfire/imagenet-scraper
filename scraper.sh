#/usr/bin/env bash

# display a help message
help_msg() {
	printf "%s\n" \
		"Usage: $0 [-n NUM] [-f FILE] [WNID]..." \
		'Scrapes images from ImageNet for classes corresponding to the WordNet IDs (WNIDs).' \
		'Examples:'
	printf "\t%s\n" \
		"$0 -n 5 'n01440764' 'n01443537'" \
		"$0 -n 5 -f wnids.txt"
	printf "%s\n" 'Options:'
	printf "\t%s\t%s\n" \
		'-n' 'number of images to download per class (default 10)' \
		'-f' 'file containing WordNet IDs of classes; if specified, ' \
		'  ' 'any WNIDS passed are ignored' \
		'-h' 'print this help message and exit'
}

# default number of images to download per class
num='10'

# parse command line options
while getopts 'n:f:h' opt; do
	case "$opt" in
		n) num="$OPTARG" ;;
		f) wnidfile="$OPTARG" ;;
		h) help_msg; exit 0;;
		*) echo "See '$0 -h' for more details."; exit 1;;
	esac
done
shift $((OPTIND - 1))

# check that requirements are installed
wget --version > /dev/null || exit 1
parallel --version > /dev/null || exit 1

# download images for the class corresponding to the given WordNet ID
download_wnid() {

	# WordNet ID
	local wnid="$1"

	# number of images
	local num="$2"

	# make a directory for this class
	mkdir "$wnid"

	cd "$wnid"

	# retrieve a list of image URLs from image-net.org,
	# retain only the flickr URLs (as they are the most reliable),
	# convert the http connections to https (if we use the raw http URLs
	# a redirect with the same effect almost always takes place),
	# and follow these URLs to download images.
	wget -q -i <(wget "https://www.image-net.org/api/imagenet.synset.geturls?wnid=$wnid" -q -O - | \
		grep -m "$num" 'flickr' | sed 's/http/https/')
}

export -f download_wnid

# download images for the various classes in a parallel manner.
# (within a class the images are downloaded serially, but across classes there is parallelization.)
# use the file of WordNet IDs if specified, otherwise use the WordNet IDs
# passed as command-line arguments.
if [[ -n "$wnidfile" ]]; then
	parallel --bar "download_wnid {} $num" < "$wnidfile"
else
	(IFS=$'\n'; echo "$*") | parallel --bar "download_wnid {} $num"
fi
