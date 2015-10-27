# This test first makes all the required GPIO's low and then sequentially makes them high as user press Enter key on terminal
# Note that the dtb should have all the below MFIO's configured as GPIO

LOG_LEVEL=1
source common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

mfio_array="2 8 9 10 11 12 13 14 21 28 29 30 31 32 33 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 61 62 72 73 74 75 76 79 80 81 82 83 84 85 87 88"

# Make all the required GPIO's 0
echo -e "Setting all required MFIOs to low\n" >&3
for i in $mfio_array
do
	sh test_set_pin.sh $i 0
	if [ $? -ne 0 ];then
		echo -e "Error in setting MFIO_$i = 0\n" >&3
	fi
done

for i in $mfio_array
do
	echo -e "Press \"Enter\" key to set MFIO_$i = 1\n" >&3
	read user_input
	sh test_set_pin.sh $i 1
	if [ $? -ne 0 ];then
		echo -e "Error in setting MFIO_$i = 1 \b" >&3
	fi
done
