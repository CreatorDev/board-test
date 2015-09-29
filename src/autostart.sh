#!/bin/sh

FILE_PATH=/etc/init.d/S99autostart
if [ -e $FILE_PATH ] && [ "$1" != "-r" ]; then
	echo "Previous autostart command already exists; run 'autostart -r' to replace"
	cat $FILE_PATH | tail -n+2
	exit
fi

echo "Enter here the commands to be autostarted; then press CTRL+D"
echo "#!/bin/sh" | cat > $FILE_PATH
cat  >> $FILE_PATH
chmod 755 $FILE_PATH
sync
echo "$FILE_PATH scipt created successfully"
