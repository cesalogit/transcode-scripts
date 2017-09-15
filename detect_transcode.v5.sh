#!/bin/bash

##2016.04.12 - Added change for tvshows and variable tv

wrk_dir=/share/media/scripts.1/transcode_custom
tmp_dir=/share/media/movies.to.delete
file_status_dir=/share/media/scripts.1/transcode_custom/file.status
dir_videos="$1"
num_files="$2"

if [ "$#" -eq 0 ];then
echo "No Params"
echo "Usage: $0 Directory #files"
exit 1
fi

fname=`echo $1 | sed 's/\//./g'`
fname=`echo $fname | sed 's/ /./g'`
time_file=${wrk_dir}/time.info/time.touch.$fname
lst_files=${wrk_dir}/list_file/list_files.$fname.$$.lst

echo $time_file

if [ -f "${time_file}" ]; then
echo "Time file found"
ls -lrt ${time_file}
else echo "No time file"; touch -t 1601010000 "${time_file}"
fi

cd "$dir_videos"

if [ "`echo "$dir_videos" | grep tv.shows.sickrage | wc -l`" -ge 1 ] || [ "`echo "$dir_videos" | grep tvshows.1 | wc -l`" -ge 1 ]; then
     tv=true
fi

#echo "Found tv: $tv" >> /tmp/ll.lst

if [ "$num_files" == "" ];then
     ls -lrt *.avi | grep -v MARK.DONE.TRANS.MP4 > $lst_files
     ls -lrt *.mkv | grep -v MARK.DONE.TRANS.MP4 >> $lst_files
else ls -lrt *.avi | head -n "$num_files" | grep -v MARK.DONE.TRANS.MP4 > $lst_files
     ls -lrt *.mkv | head -n "$num_files" | grep -v MARK.DONE.TRANS.MP4 >> $lst_files
fi
 
awk '{print $9}' $lst_files > $lst_files.clean

while read current_file
do
   echo "-> Encoding file: $current_file"
   echo ""
   touch ${file_status_dir}/${current_file}.start
   if [ "$tv" = true ];then
        encode_donmelton.sh $current_file tv < /dev/null
   else encode_donmelton.sh $current_file < /dev/null
   fi
   echo ""
   echo "-> Finishing encoding of file: $current_file"
   echo ""
   echo "-> Changing name of original to: MARK.DONE.TRANS.MP4."$current_file""
   echo "-> Moving to temp dir: ${tmp_dir}"

   mv $current_file ${tmp_dir}/MARK.DONE.TRANS.MP4."$current_file" 

   touch ${file_status_dir}/${current_file}.end
   echo ""
   echo ""
done < $lst_files.clean

cat ${lst_files}.clean >  ${time_file}
