#!/bin/bash

# encode.sh
#
# Copyright (c) 2013 Don Melton
#
# This version published on June 7, 2013.
#
# Re-encode video files in a format suitable for playback on Apple TV, Roku 3,
# iOS, OS X, etc.
#
# Input is assumed to be a single file readable by HandBrakeCLI and mediainfo,
# e.g. just about any .mkv, .avi, .mpg, etc. file.
#
# The script automatically calculates output video bitrate based on input. For
# Blu-ray Disc-quality input that's always 5000 Kbps. For DVD-quality input
# that's always 1800 Kbps. For other files that will vary.
#
# The script also automatically calculates video frame rates and audio channel
# configuration.
#
# If the input contains a VobSub (DVD-style) or PGS (Blu-ray Disc-style)
# subtitle, then it is burned into the video.
#
# Optional frame rate overrides and soft subtitles in .srt format are read
# from separate fixed locations in the `$frame_rates_location` and
# `$subtitles_location` variables defined below. Edit this script to redefine
# them.
#
# If your input file is named "foobar.mkv" then the optional frame rate file
# should be named "foobar.txt". And all it should contain is the frame rate
# number, e.g. "25" followed by a carriage return.
#
# If your input file is named "foobar.mkv" then the optional soft subtitle
# file should be named "foobar.srt".
#
# Output is an MP4 container with H.264 video, AAC audio and possibly AC-3
# audio if the input has more than two channels.
#
# No scaling or cropping is performed on the output. This is a good thing.
#
# The output .mp4 file and a companion .log file are written to the current
# directory.
#
# This script depends on two separate command line tools:
#
#   HandBrakeCLI    http://handbrake.fr/
#   mediainfo       http://mediainfo.sourceforge.net/
#
# Make sure both are in your `$PATH` or redefine the variables below.
#
# Usage:
#
#   ./encode.sh [input file] [tv: true]
#
# 2016-02-24: Added support for AC3-6ch -> AAC-6ch
# 2016-04-12: Added special case for tv shows and variable tv
# 2016-04-29: Added option for $channels == 26

istv="$2"

die() {
    echo "$program: $1" >&2
    exit ${2:-1}
}

escape_string() {
    echo "$1" | sed "s/'/'\\\''/g;/ /s/^\(.*\)$/'\1'/"
}

readonly program="$(basename "$0")"

readonly input="$1"

if [ ! "$input" ]; then
    die 'too few arguments'
fi

handbrake="HandBrakeCLI"
mediainfo="mediainfo"

frame_rates_location="/path/to/Frame Rates"
subtitles_location="/path/to/Subtitles"

# My advice is: do NOT change these HandBrake options. I've encoded over 300
# Blu-ray Discs, 30 DVDs and numerous other files with these settings and
# they've never let me down.

handbrake_options="--markers --large-file --encoder x264 --encopts vbv-maxrate=25000:vbv-bufsize=31250:ratetol=inf --crop 0:0:0:0 --strict-anamorphic --optimize"

mediainfo "$input"

width="$(mediainfo --Inform='Video;%Width%' "$input")"
height="$(mediainfo --Inform='Video;%Height%' "$input")"
lang1="$(mediainfo --Inform='Audio;%Language%' "$input" | cut -c1-2)"
lang2="$(mediainfo --Inform='Audio;%Language%' "$input" | cut -c3-4)"

#echo width: $width
#echo height: $height

if (($width > 1280)) || (($height > 720)); then
#    max_bitrate="5000"
#    max_bitrate="3000"
    max_bitrate="2200"
elif (($width > 720)) || (($height > 576)); then
#    max_bitrate="4000"
#    max_bitrate="2500"
    max_bitrate="2000"
else
    max_bitrate="1500"
fi

#echo max_bitrate: $max_bitrate

min_bitrate="$((max_bitrate / 2))"

#echo min_bitrate: $min_bitrate

bitrate="$(mediainfo --Inform='Video;%BitRate%' "$input")"

#echo bitrate: $bitrate

if [ ! "$bitrate" ]; then
    bitrate="$(mediainfo --Inform='General;%OverallBitRate%' "$input")"
    bitrate="$(((bitrate / 10) * 9))"
fi

if [ "$bitrate" ]; then
    bitrate="$(((bitrate / 5) * 4))"
    bitrate="$((bitrate / 1000))"
    bitrate="$(((bitrate / 100) * 100))"

    if (($bitrate > $max_bitrate)); then
        bitrate="$max_bitrate"
    elif (($bitrate < $min_bitrate)); then
        bitrate="$min_bitrate"
    fi
else
    bitrate="$min_bitrate"
fi

if [ "$2" != "" -a "$2" != "tv" ]; then
     bitrate=$2
fi

echo bitrate: $bitrate

handbrake_options="$handbrake_options --vb $bitrate"

frame_rate="$(mediainfo --Inform='Video;%FrameRate_Original%' "$input")"

if [ ! "$frame_rate" ]; then
    frame_rate="$(mediainfo --Inform='Video;%FrameRate%' "$input")"
fi

frame_rate_file="$(basename "$input")"
frame_rate_file="$frame_rates_location/${frame_rate_file%\.[^.]*}.txt"

if [ -f "$frame_rate_file" ]; then
    handbrake_options="$handbrake_options --rate $(cat "$frame_rate_file")"
elif [ "$frame_rate" == '29.970' ]; then
    handbrake_options="$handbrake_options --rate 23.976"
else
    handbrake_options="$handbrake_options --rate 30 --pfr"
fi

channels="$(mediainfo --Inform='Audio;%Channels%' "$input" | sed 's/[^0-9].*$//')"

echo channels: $channels

lang1="$(mediainfo --Inform='Audio;%Language%' "$input" | cut -c1-2)"
lang2="$(mediainfo --Inform='Audio;%Language%' "$input" | cut -c3-4)"

if [ "$lang2" != "" ]; then
    echo Language-1 = $lang1
    echo Language-2 = $lang2
else echo Language 1= $lang1
fi

if [ "$lang1" == "en" ]; then
     langeng=1 
elif [ "$lang2" == "en" ]; then
     langeng=2
fi

echo langeng=$langeng
echo lang1=$lang1
echo lang2=$lang2

if (($channels == 6)); then
    handbrake_options="$handbrake_options --aencoder faac --mixdown 6ch"
elif (($channels == 8)); then
    handbrake_options="$handbrake_options --aencoder faac --mixdown 6ch"
elif (($channels > 60)); then
    handbrake_options="$handbrake_options --audio $langeng --aencoder faac --mixdown 6ch"
elif (($channels == 26)); then
    if [ "$lang2" == "en" ]; then
         langeng=2
    fi
    handbrake_options="$handbrake_options --audio $langeng --aencoder faac --mixdown 6ch"
elif (($channels == 22)); then
    if [ "$lang2" == "en" ]; then
         langeng=2
    fi
    handbrake_options="$handbrake_options --audio $langeng --aencoder faac --mixdown 6ch"
elif [ "$(mediainfo --Inform='General;%Audio_Format_List%' "$input" | sed 's| /.*||')" == 'AAC' ]; then
    handbrake_options="$handbrake_options --aencoder copy:aac"
else handbrake_options="$handbrake_options --aencoder faac"
fi

if [ "$frame_rate" == '29.970' ]; then
    handbrake_options="$handbrake_options --detelecine"
fi

srt_file="$(basename "$input")"
srt_file="$subtitles_location/${srt_file%\.[^.]*}.srt"

if [ -f "$srt_file" ]; then
    subtitle_format="$(mediainfo --Inform='Text;%Format%' "$input" | sed q)"

    if [ "$subtitle_format" == 'VobSub' ] || [ "$subtitle_format" == 'PGS' ]; then
        handbrake_options="$handbrake_options --subtitle 1 --subtitle-burned"
    else
        tmp=""

        trap '[ "$tmp" ] && rm -rf "$tmp"' 0
        trap '[ "$tmp" ] && rm -rf "$tmp"; exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

        tmp="/tmp/${program}.$$"
        mkdir -m 700 "$tmp" || exit 1

        temporary_srt_file="$tmp/subtitle.srt"
        cp "$srt_file" "$temporary_srt_file" || exit 1

        handbrake_options="$handbrake_options --srt-file $(escape_string "$temporary_srt_file") --srt-codeset UTF-8 --srt-lang eng --srt-default 1"
    fi
fi

output="$(basename "$input")"
output="${output%\.[^.]*}.mp4"

if [ -f ${output} ]; then
     output=${output}.v2.mp4 
fi

echo "Encoding: $input" >&2

echo handbrake_options: $handbrake_options

time "$handbrake" \
    $handbrake_options \
    --input "$input" \
    --output "$output" \
    2>&1 | tee -a "${output}.log"

#--Setting up automatic file naming

format="$(mediainfo --Inform='Video;%Format%' "$output")"
if [ "$format" == "AVC" ];then
     format=H264
fi
echo Video Codec: $format
frame_rate="$(mediainfo --Inform='Video;%FrameRate%' "$output")"
echo frame_rate: $frame_rate
bitrate="$(mediainfo --Inform='Video;%BitRate%' "$output")"
echo bitrate: $bitrate
width="$(mediainfo --Inform='Video;%Width%' "$output")"
height="$(mediainfo --Inform='Video;%Height%' "$output")"
echo width:$width x height:$height
format_audio="$(mediainfo --Inform='Audio;%Format%' "$output")"
echo Audio Codec: $format_audio
channels="$(mediainfo --Inform='Audio;%Channels%' "$output" | sed 's/[^0-9].*$//')"
echo channels:$channels

if [ "$height" -gt "800" ];then
     height=1080p
elif [ "$height" -gt "600" -a "$height" -le "800" ];then
       height=720p
elif [ "$height" -le "600" ];then
       height=SD
fi

if [ "$bitrate" -gt "2700000" -a "$bitrate" -lt "3700000" ];then
     bitrate=3Mbps
elif [ "$bitrate" -ge "1700000" -a "$bitrate" -lt "2700000" ];then
     bitrate=2Mbps
elif [ "$bitrate" -gt "700000" -a "$bitrate" -le "1700000" ];then
     bitrate=1Mbps
fi

if [ "$channels" -eq 6 -o "$channels" -eq 66 ];then
     channels=5.1
fi

echo  "$height.$format.$bitrate.$format_audio.$channels"
rename_string="$height.$format.$bitrate.$format_audio.$channels"
rename_string_4_tv="$bitrate.$format_audio.$channels"

if [ "$istv" = "tv" ];then
     rename_string=$rename_string_4_tv
fi

input_rename="$(basename "$output")"
input_rename="${output%\.[^.]*}.${rename_string}.mp4"
input_rename=`echo $input_rename | awk '{ gsub (" ", "", $0); print}'`
echo new filename: $input_rename

mv $output $input_rename
