#!/bin/sh
#
# Copyright 2015 by Imagination Technologies Limited and/or its affiliated group companies.
#
# All rights reserved.  No part of this software, either
# material or conceptual may be copied or distributed,
# transmitted, transcribed, stored in a retrieval system
# or translated into any human or computer language in any
# form by any means, electronic, mechanical, manual or
# other-wise, or disclosed to the third parties without the
# express written permission of Imagination Technologies
# Limited, Home Park Estate, Kings Langley, Hertfordshire,
# WD4 8LZ, U.K.

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
