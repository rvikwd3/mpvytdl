#!/bin/bash

######################################################################################
## Script to find the youtube-dl format number from the youtube video link provided
##
## Examples
##
##	$ mpvur 1080p m4a https://www.youtube.com/watch?v=3urOzCclGhc
##	$ mpvur -v 480p -a best -u https://www.youtube.com/watch?v=3urOzCclGhc
##	$ mpvur -v 720p -a m4a -u https://www.youtube.com/watch?v=3urOzCclGhc
##
##	TODO
##		1.	Extract 'youtube-dl -F' format
##		2.	Put automatic arguments for Audio, Video and URL
##		3.	Ensure video, audio correct input (480p/480, m4a/webm)
##		4.	Call mpv with format options
##		5.	Call 'mpv --ytdl-format=video+audio'
##		6.	Include video container format
##
######################################################################################

# OLD GETOPTS
# -----------
# Check for option flags
#while getopts ":v:a:u:" opt; do
#	case $opt in
#		v)
#				echo "-v was triggered	Parameter: $OPTARG" >&2
#				;;
#		a)
#				echo "-a was triggered	Parameter: $OPTARG" >&2
#				;;
#		u)
#				echo "-u was triggered	Parameter: $OPTARG" >&2
#				;;
#		\?)
#				echo "Invalid option: -$OPTARG" >&2
#				exit 1
#				;;
#		:)
#				echo "Option -$OPTARG requires an argument." >&2
#				exit 1
#				;;
#		esac
#done

# NEW GETOPT
# ----------
OPTIONS=v:a:u:h		# -v video -a audio -u URL -h help
LONGOPTIONS=video:,audio:,url:,help

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
	echo "Getopt complained about wrong arguments"
	exit 2
fi

eval set -- "$PARSED"

HELP=false

while true; do
	case "$1" in
		--video | -v)
			case "$2" in
				"") echo "[$1] Need an argument!"
					shift 2
					;;
				*)	VIDEO=$2;
					shift 2
					;;
			esac
		;;
		--audio | -a)
			case "$2" in
				"") echo "[$1] Need an argument!"
					shift 2
					;;
				*)	AUDIO=$2;
					shift 2
					;;
			esac
		;;
		--url | -u)
			case "$2" in
				"") echo "[$1] Need an argument!"
					shift 2
					;;
				*)	URL=$2;
					shift 2
					;;
			esac
		;;
		--help | -h)
			echo "Help!"
			shift
			exit 0
			;;
		--)
			shift
			break
			;;
		*)
			echo "Internal error!\tERROR_FLAG_CASE *"
			exit 1
			;;
	esac
done

# Functions
# ---------
# Make sure to trash temp file on crash
cleanup(){
	printf "\nCleanup...\n"
	if [[ -f $ytdl_tmpfile ]]; then
		rm $ytdl_tmpfile -f
		echo "Found tmpfile '$ytdl_tmpfile'"
	fi
	printf "\nFinished cleanup\n"
	exit 1
}


# Parameter variables
echo "Video:	$VIDEO"
echo "Audio:	$AUDIO"
echo "URL:	$URL"

# Arguments
args=()
while [[ $# -gt 0 ]]
do
	arg="$1"
	shift

	echo $arg
done

# Create temporary file for ytdl format lines
# -------------------------------------------
ytdl_tmpfile=$(mktemp /tmp/ytdl-script.XXXXX)

# Gracefully exit on crash
trap cleanup 0 2 3 15

# Populate tempfile
echo "Tempfile made:	$ytdl_tmpfile"
youtube-dl -F "$URL" > $ytdl_tmpfile
echo "Tempfile populated"

# Check if video, audio, URL are set
if [[ -z ${URL+x} ]]; then
	echo "-----------------------------------------------"
	echo "URL unset"
	read -p "Enter URL:	" URL
	echo "URL:	$URL"
fi

# Set video resolution
# --------------------
while [[ -z ${VIDEO+x} ]]
do
	echo "-----------------------------------------------"
	echo "Resolution unset"

	# Since URL is definitely set,
	# list youtube-dl formats

	printf '\nVideo Resolutions:\n'
	echo "------------------"

	#for line in $(cat "$ytdl_tmpfile")
	while read line;
	do
		echo "$line" | sed -n '/video/p' | awk '{ print $2"\t"$4 }' | sed -e '/video/d'
	done < $ytdl_tmpfile

	read -p "Enter video resolution:	" VIDEO
	echo "VIDEO:	$VIDEO"

	if ! [[ $VIDEO =~ ^[0-9]{3,4}p$  ||  $VIDEO =~ ^[0-9]{3,4}$  ]]; then
		echo "Not a valid VIDEO resolution"
		unset VIDEO
	fi
done

# Set audio resolution
# --------------------
if [[ -z ${AUDIO+x} ]]; then
	echo "-----------------------------------------------"
	echo "Audio unset"

	# Since URL is definitely set,
	# list youtube-dl formats

	printf '\nAudio Resolutions:\n'
	echo "------------------"

	#for line in $(cat "$ytdl_tmpfile")
	while read line;
	do
		echo "$line" | sed -n '/audio/p' | awk '{ print $2"\t"$7 }'
	done < $ytdl_tmpfile

	read -p "Enter audio quality:	" AUDIO
	echo "AUDIO:	$AUDIO"
fi

# Find format index from ytdl -F
# ------------------------------
if [[ "$VIDEO" -eq "best" ]]
then
	echo "[VIDEO] BEST"
	# compare video qualities
else
	VIDEO_FORMAT="$(grep -E video < $ytdl_tmpfile | grep -E $VIDEO | head -n 1 | awk '{ print $1 }')"
	echo "Video format = $VIDEO_FORMAT"
fi

if [[ "$AUDIO" -eq "best" ]]
then
	echo "[AUDIO] BEST"
	bitrate=($(grep -E audio < $ytdl_tmpfile | grep -Eo '@[0-9]{2,3}k|@ [0-9]{2,3}k' | sed 's/[^0-9k]//g' ))

	# print bitrates before sorting
	echo "[AUDIO] Before sort"
#	for i in "${bitrate[@]}"
#	do
#		printf "[BITRATE - $i] ${bitrate[$i]}"
#		echo "[AUDIO] bitrate - " $i
#	done

	# sort audio bitrates
	echo "[AUDIO] Sort bitrates"
	bitrate_sorted=( $(
		for i in "${bitrate[@]}"
		do
			echo "$i" | sed "s/k//"
		done | sort -gr) )

	# print bitrates after sorting
	echo "[AUDIO] After sort"
	for i in "${bitrate_sorted[@]}"
	do
		echo $i
	done

	AUDIO=${bitrate_sorted[0]}
	echo "[AUDIO] " $AUDIO

fi

AUDIO_FORMAT="$(grep -E audio < $ytdl_tmpfile | grep -E $AUDIO"k" | head -n 1 | awk '{ print $1 }')"
echo "Audio format = $AUDIO_FORMAT"


rm "$ytdl_tmpfile"

! echo "Complete"
