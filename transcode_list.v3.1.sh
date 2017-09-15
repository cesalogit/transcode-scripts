tv_shows_list=/share/scripts.1/transcode_custom/tv.shows.lst
wrk_dir=/share/scripts.1/transcode_custom
num_files=$1

if [ "`ls -lrt /share/movies.torrent/* | grep lftp-pget-status | wc -l`" -lt 1 ];then
     cd /share/movies.torrent
     ls -lrt *
     mv *.mkv /share/movies.transcode/
     mv *.avi /share/movies.transcode/
else echo "It seems torrents are being copied - Skip copying from torrent dir"
fi
cd /share/movies.temp
ls -lrt *
mv *.mkv /share/movies.transcode/
mv *.avi /share/movies.transcode/

ps -ef | grep -i encode_donmelton | grep -v grep
ps -ef | grep -i mediainfo | grep -v grep
ps -ef | grep -i detect_transcode | grep -v grep

if [ "`ps -ef | grep -i encode_donmelton | grep -v grep |  wc -l`" -ge 1 ];then
     echo "There is already a encoding session ... Stopping."
     exit 1
elif [ "`ps -ef | grep -i detect_transcode | grep -v grep | wc -l`" -ge 1 ];then
       echo "There is already a detect_transcoding session ... Stopping."
       exit 1
else echo " ";echo "No transcoding sessions detected" ; echo " "
fi

while read current_dir
do
   if [ -z "${current_dir}" ];then
        echo "Empty Line"
   else
        if [ "${current_dir}" == "/share/movies.transcode" ]; then
             if [ "`ls -lrt /share/movies.torrent/* | grep lftp-pget-status | wc -l`" -lt 1 ];then
                  cd /share/movies.torrent
                  ls -lrt *
                  mv *.mkv /share/movies.transcode/
                  mv *.avi /share/movies.transcode/
             else echo "It seems torrents are being copied - Skip copying from torrent dir"
             fi
             cd /share/movies.temp
             ls -lrt *
             mv *.mkv /share/movies.transcode/
             mv *.avi /share/movies.transcode/
        fi

        ps -ef | grep -i encode_donmelton | grep -v grep
        ps -ef | grep -i mediainfo | grep -v grep
        ps -ef | grep -i detect_transcode | grep -v grep
        
        if [ "`ps -ef | grep -i encode_donmelton | grep -v grep |  wc -l`" -ge 1 ];then
             echo "There is already a encoding session ... Stopping."
             exit 1
        elif [ "`ps -ef | grep -i detect_transcode | grep -v grep | wc -l`" -ge 1 ];then
               echo "There is already a detect_transcoding session ... Stopping."
               exit 1
        else echo "No transcoding sessions detected"
        fi

        cfile=`echo ${current_dir} | sed 's/ /./g'`
        cfile=`echo ${cfile} | sed 's#/#.#g'`
        cfile=`echo $cfile | awk '{print substr($1,2); }'`
        echo ""
        echo "-> Encoding Directory: ${current_dir}"
        #echo ${wrk_dir}/logs/${cfile}.out

        if [ "$num_files" == "" ];then
             /sbin/detect_transcode.sh "$current_dir" > ${wrk_dir}/logs/${cfile}.$$.out 2>&1
        else /sbin/detect_transcode.sh "$current_dir" "$num_files" > ${wrk_dir}/logs/${cfile}.$$.out 2>&1
        fi

        echo ""
   fi
done < $tv_shows_list

#find ${wrk_dir}/logs -name "*.out" -mtime +2 -exec rm -Rf {} \;
#find ${wrk_dir}/list_file -name "*.clean" -mtime +2 -exec rm -Rf {} \;
#find ${wrk_dir}/list_file -name "*.lst" -mtime +2 -exec rm -Rf {} \;

