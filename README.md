# mpvytdl

 Script to find the youtube-dl format number from the youtube video link provided

### Options
```	-v	--video	Video quality eg. 144p, 720p, best
	-a	--audio	Audio quality eg. 128k, 160k, best
	-u	--url	URL of youtube video to play
	-p	--profile	mpv profile to use
	-h	--help	Show help
```

### TODO
	1.	Extract 'youtube-dl -F' format
	2.	Put automatic arguments for Audio, Video and URL
	3.	[✓] Ensure video, audio correct input (480p/480, m4a/webm)
	4.	Call mpv with format options
	5.	Call 'mpv --ytdl-format=video+audio'
	6.	Include video container format
	7.	[✓] "best" quality functions
	8.	Populate -h Help
	9.	Usage text
	10.	60fps quality support

### Examples

```	$ mpvur 1080p m4a https://www.youtube.com/watch?v=3urOzCclGhc
	$ mpvur -v 480p -a best -u https://www.youtube.com/watch?v=3urOzCclGhc
	$ mpvur -v 720p -a m4a -u https://www.youtube.com/watch?v=3urOzCclGhc
```

