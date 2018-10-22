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
##		3.	[✓] Ensure video, audio correct input (480p/480, m4a/webm)
##		4.	Call mpv with format options
##		5.	Call 'mpv --ytdl-format=video+audio'
##		6.	Include video container format
##		7.	[✓] "best" quality functions
##		8.	Populate -h Help
##		9.	Usage text
##
######################################################################################

# NEW GETOPT									 {{{
# ----------
OPTIONS=v:a:u:hp:		# -v video -a audio -u URL -h help -p profile
LONGOPTIONS=video:,audio:,url:,help,profile:	# --video --audio --url --help --profile

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
	echo "Getopt complained about wrong arguments"
	exit 2
fi

eval set -- "$PARSED"

HELP=false

while true; do								#{{{
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
		--profile | -p)
			echo "[ARGS] Profile"
			case "$2" in
				"")	echo "[$1] Need an argument!"
					shift 2
				;;
				*)	PROFILE=$2;
					shift 2
				;;
			esac
		;;
		--)
			shift
			break
		;;
		*)
			echo "Internal error!	ERROR_FLAG_CASE *"
			exit 1
		;;
	esac
done	#}}}
#}}}

# Functions
# ---------
# Make sure to trash temp file on crash
cleanup(){									#{{{
	printf "\nCleanup...\n"
	if [[ -f $ytdl_tmpfile ]]; then
		rm $ytdl_tmpfile -f
		echo "Found tmpfile '$ytdl_tmpfile'"
	fi
	printf "\nFinished cleanup\n"
	exit 1
}	#}}}

# Select best video format from youtube-dl
best_video(){									#{{{
	bitrate=($(grep -E video < $ytdl_tmpfile | grep -Eo '[0-9]{3,4}p' | sed 's/[^0-9p]//g' ))

	# print bitrates before sorting
	echo "[VIDEO] Before sort"


	for i in "${bitrate[@]}"
	do
		#printf "[BITRATE - $i] ${bitrate[$i]}"
		echo "[VIDEO] bitrate - " $i
	done

	# sort video bitrates
	echo "[VIDEO] Sort bitrates"
	bitrate_sorted=( $(
		for i in "${bitrate[@]}"
		do
			echo "$i" | sed "s/k//"
		done | sort -gr) )

	# print bitrates after sorting
	echo "[VIDEO] After sort"
	for i in "${bitrate_sorted[@]}"
	do
		echo $i
	done

	VIDEO="${bitrate_sorted[0]}"
}	#}}}

# Select best audio format from youtube-dl
best_audio(){									#{{{
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

	AUDIO="${bitrate_sorted[0]}"
}	#}}}

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

>&2 echo "[DEBUG] Parameter variables declared"

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

>&2 echo "[DEBUG] Video, Audio, URL set & Tempfile populated"

# Set video resolution
# --------------------
while [[ -z ${VIDEO+x} ]]						#{{{
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
		echo "$line" | sed -n '/video/p' | awk '{ print $2"	"$4 }' | sed -e '/video/d'
	done < $ytdl_tmpfile

	read -p "Enter video resolution:	" VIDEO
	echo "VIDEO:	$VIDEO"

	if ! [[ $VIDEO =~ ^[0-9]{3,4}p$  ||  $VIDEO =~ ^[0-9]{3,4}$  ]]; then
		echo "Not a valid VIDEO resolution"
		unset VIDEO
	fi
done

# if quality is best, find the best bitrate
if [[ "$VIDEO" -eq "best" ]]; then
	echo "[VIDEO] BEST"
	# compare video qualities
	best_video

	echo "[VIDEO] " $VIDEO
fi #}}}

>&2 echo "[DEBUG] Video resolution set"

# Set audio resolution
# --------------------
if [[ -z ${AUDIO+x} ]]; then					#{{{
	echo "-----------------------------------------------"
	echo "Audio unset"

	# Since URL is definitely set,
	# list youtube-dl formats

	printf '\nAudio Resolutions:\n'
	echo "------------------"

	#for line in $(cat "$ytdl_tmpfile")
	while read line;
	do
		echo "$line" | sed -n '/audio/p' | awk '{ print $2"	"$7 }'
	done < $ytdl_tmpfile

	read -p "Enter audio quality:	" AUDIO
	AUDIO=$(echo $AUDIO | sed 's/k//g')
	echo "AUDIO:	$AUDIO"
fi

# if quality is best, find the best bitrate
if [[ "$AUDIO" -eq "best" ]]; then
	echo "[AUDIO] BEST"
	# compare audio qualities
	best_audio

	echo "[AUDIO] " $AUDIO

fi	#}}}

>&2 echo "[DEBUG] Audio resolution set"

# Find format index from ytdl -F
# ------------------------------

AUDIO_FORMAT="$(grep -E audio < $ytdl_tmpfile | grep -E $AUDIO"k" | head -n 1 | awk '{ print $1 }')"
echo "Audio format = $AUDIO_FORMAT"

VIDEO_FORMAT="$(grep -E video < $ytdl_tmpfile | grep -E $VIDEO | head -n 1 | awk '{ print $1 }')"
echo "Video format = $VIDEO_FORMAT"

# At this point we have the
#	URL
#	Video Format Code
#	Audio Format Code
# We can call mpv with the ytdl-format flag

if [[ -z ${PROFILE+x} ]]; then
	mpv "$URL" --ytdl-format=$VIDEO_FORMAT+$AUDIO_FORMAT
else
	mpv "$URL" --profile=$PROFILE --ytdl-format=$VIDEO_FORMAT+$AUDIO_FORMAT
fi

rm "$ytdl_tmpfile"

! echo "Complete"

