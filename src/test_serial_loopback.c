/*
* This is generic test for testing serial port in loopback mode
*/

#include <termios.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define NUM_OF_TEST_BYTES	100
#define SELECT_TIMEOUT		5


static void usage(void)
{
	printf("Usage:\t./test_serial_loopback device [options]\n\n"
		   "\tdevice: specify the serial device to be used e.g /dev/ttySC0\n\n"
		   "\t[options]\n"
		   "\t-f enable hardware flow control\n"
		   "\t   this would mean shorting RTS,CTS for the test to pass\n");
}

int main(int argc, char *argv[])
{
	int pf, retval, i, opt, enable_hardwareflow = 0, ret = 0;
	struct termios pts;
	char data, test_char = 'a';
	fd_set rfds;
	struct timeval tv;

	pf = open(argv[1], O_RDWR);
	if (pf < 0)
	{
		printf("Cannot open device\n");
		usage();
		return -1;
	}

	while ((opt = getopt(argc,argv,"f::")) > 0)
	{
		switch (opt)
		{
			case 'f':
				enable_hardwareflow = 1;
				break;
			default:
				usage();
				close(pf);
				return -1;
		}
	}

	printf("*********** Serial loopback test *********\n\n");

	tcgetattr(pf, &pts);

	pts.c_lflag=0;
	pts.c_iflag=0;
	pts.c_oflag=0;
	pts.c_cflag=0;

	/* 1 stop bit, no parity is default, so no need to set anything */
	pts.c_cflag |= B9600;
	pts.c_cflag |= CS8;

	if (enable_hardwareflow == 1)
	{
		printf("enabling hardware flow control\n");
		pts.c_cflag |= CRTSCTS;
	}

	/* ignore modem status lines */
	pts.c_cflag |= CLOCAL;
	/* hang up on last close */
	pts.c_cflag |= HUPCL;
	/* one input byte is enough to return from read(), inter-character timer off */
	pts.c_cc[VMIN] = 1;
	pts.c_cc[VTIME] = 0;

	/* set new attributes */
	tcsetattr(pf, TCSANOW, &pts);

	for (i = 0; i < NUM_OF_TEST_BYTES; i++)
	{
		/* write data to serial port */
		retval = write(pf, &test_char, 1);
		if (1 != retval)
		{
			printf("FAIL: write failed(%d)\n", retval);
			ret = -1;
			break;
		}

		FD_ZERO(&rfds);
		FD_SET(pf, &rfds);
		/* Wait up to five seconds */
		tv.tv_sec = SELECT_TIMEOUT;
		tv.tv_usec = 0;
		retval = select(pf+1, &rfds, NULL, NULL, &tv);
		if (retval == -1)
		{
			printf("FAIL: Error in select\n");
		}
		else if (retval)
		{
			/* we got some data, read it */
			retval = read(pf, &data, 1);
			if (retval != 1)
			{
				printf("FAIL: error in reading(%d)\n", retval);
				ret = -1;
				break;
			}
			else
			{
				if (test_char != data)
				{
					printf("FAIL: incorrect data read\n");
					ret = -1;
					break;
				}
			}
		}
		else
		{
			printf("FAIL: No data within %d seconds.\n", SELECT_TIMEOUT);
			ret = -1;
			break;
		}

		/* start again from a */
		if (test_char == 'z')
			test_char = 'a';
		else
			test_char++;
	}

	if (ret == 0)
	{
		printf("PASS\n");
	}

	close(pf);
	return ret;
}
