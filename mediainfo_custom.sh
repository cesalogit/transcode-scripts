input=$1
format="$(mediainfo --Inform='Video;%Format%' "$input")"
if [ "$format" == "AVC" ];then
     format=H264
fi
echo Video Codec: $format
frame_rate="$(mediainfo --Inform='Video;%FrameRate%' "$input")"
echo frame_rate: $frame_rate
bitrate="$(mediainfo --Inform='Video;%BitRate%' "$input")"
echo bitrate: $bitrate
width="$(mediainfo --Inform='Video;%Width%' "$input")"
height="$(mediainfo --Inform='Video;%Height%' "$input")"
echo width:$width x height:$height
format_audio="$(mediainfo --Inform='Audio;%Format%' "$input")"
echo Audio Codec: $format_audio
channels="$(mediainfo --Inform='Audio;%Channels%' "$input" | sed 's/[^0-9].*$//')"
echo channels:$channels

lang1="$(mediainfo --Inform='Audio;%Language%' "$input" | cut -c1-2)"
lang2="$(mediainfo --Inform='Audio;%Language%' "$input" | cut -c3-4)"

if [ "$lang2" != "" ]; then
    echo Language-1 = $lang1
    echo Language-2 = $lang2
else echo Language 1= $lang1  
fi

if [ "$height" -gt "800" ];then
     height=1080p
elif [ "$height" -gt "600" -a "$height" -le "800" ];then
       height=720p
elif [ "$height" -le "600" ];then
       height=SD
fi

if [ "$format" == "AVC" ];then
     format=H264
fi

if [ "$bitrate" -gt "2700000" -a "$bitrate" -lt "3200000" ];then
     bitrate=3Mbps
elif [ "$bitrate" -ge "1700000" -a "$bitrate" -lt "2700000" ];then
     bitrate=2Mbps
elif [ "$bitrate" -gt "800000" -a "$bitrate" -le "1700000" ];then
     bitrate=1Mbps
fi

if [ "$channels" -eq 6 -o "$channels" -eq 66 ];then
     channels=5.1 
fi

echo  "$height.$format.$bitrate.$format_audio.$channels"
rename_string="$height.$format.$bitrate.$format_audio.$channels"

if [ "$2" == rename ];then
     input_rename="$(basename "$input")"
     input_rename="${input%\.[^.]*}.${rename_string}.mp4"
     input_rename=`echo $input_rename | awk '{ gsub (" ", "", $0); print}'`
     echo new filename: $input_rename
fi
