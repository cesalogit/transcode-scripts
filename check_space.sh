
if [ `du -k $1 | awk '{print $1}'` -lt 100000000 ];then
echo "File is too small"
else echo "File is ok"
fi
