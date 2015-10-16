/*
 * This script can be used in two modes:
 * switch test mode:
 *     For testing the switches one by one
 *     returns 0 for pass and 1 for fail
 * wait for switch press mode (-w):
 *     returns these values
 *     -1 any error (select, read, unknown switch error)
 *     -2 for timeout
 *     1 for switch 1
 *     2 for switch 2
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <getopt.h>
#include <fcntl.h>
#include <linux/input.h>

#define SWITCH_1_CODE       (257)
#define SWITCH_2_CODE       (258)
#define DEFAULT_TIMEOUT_SEC (10)
/* return values */
#define NO_ERROR            (0)
#define SWITCH_1_PRESSED    (1)
#define SWITCH_2_PRESSED    (2)
#define OTHER_ERRORS        (-1)
#define TIMEOUT_ERROR       (-2)

#define ARRAY_SIZE(arr) (sizeof(arr)/sizeof(arr[0]))

typedef struct
{
	char *name;
	unsigned int id;
	unsigned int code;
}Switch;

static void usage(void)
{
	printf("\nUsage:\t./test_switch [options]\n\n"
			"[options]\n"
			"\n-w\twaits for key press, returns 1 for SWITCH1 press, 2 for SWITCH2\n"
			"\n-t <timeout>\n"
			"\ttimeout to wait for user response, default is 10 seconds\n\n");
}

static int get_key_pressed(int fd, unsigned int timeout)
{
	struct input_event ev[2];
	fd_set rfds;
	struct timeval tv;
	int rd, retval, key = 0;
	unsigned int i, j, num_events;

	FD_ZERO(&rfds);
	FD_SET(fd, &rfds);
	tv.tv_sec = timeout;
	tv.tv_usec = 0;

	/* loop twice for waiting for key down and up events */
	for (i = 0; i < 2; i++)
	{
		/* Wait upto timeout */
		retval = select(fd+1, &rfds, NULL, NULL, &tv);

		if (retval == -1)
		{
			/* error in select system call */
			return OTHER_ERRORS;
		}
		else if (retval)
		{
			/*read 2 events, 1 for SYN type*/
			rd = read(fd, ev, sizeof(ev));
			if (rd < (int) sizeof(struct input_event))
			{
				/* expected event of size (struct input_event) but got less size */
				return OTHER_ERRORS;
			}
			num_events = (rd / sizeof(struct input_event));
			for (j = 0; j < num_events; j++)
			{
				if (ev[j].type == EV_KEY)
				{
					switch(ev[j].code)
					{
						case SWITCH_1_CODE:
							key = SWITCH_1_PRESSED;
							break;
						case SWITCH_2_CODE:
							key = SWITCH_2_PRESSED;
							break;
						default:
							return OTHER_ERRORS;
					}
				}
			}
		}
		else
		{
			/* no data within timeout */
			return TIMEOUT_ERROR;
		}
	}
	return key;
}

int main (int argc, char *argv[])
{
	int fd, opt, ret;
	unsigned int i, timeout;
	bool pass = true, wait_for_switch_press = false;

	char *device = "/dev/input/event1";
	Switch switches[] = {{"Switch 1", SWITCH_1_PRESSED, SWITCH_1_CODE},
						 {"Switch 2", SWITCH_2_PRESSED, SWITCH_2_CODE}};

	// default timeout 10 seconds
	timeout = DEFAULT_TIMEOUT_SEC;

	while ((opt = getopt(argc,argv,"wt:h")) > 0)
	{
		switch (opt)
		{
			case 'w':
				wait_for_switch_press = true;
				break;
			case 't':
				timeout = atoi(optarg);
				break;
			case 'h':
				usage();
				return NO_ERROR;
			default:
				usage();
				return OTHER_ERRORS;
		}
	}

	// Open input device
	if ((fd = open(device, O_RDONLY)) == -1)
	{
		/* not a valid device file */
		exit(OTHER_ERRORS);
	}

	if (wait_for_switch_press)
	{
		ret = get_key_pressed(fd, timeout);
		close(fd);
		return ret;
	}
	else
	{
		printf("\n**************************** Switch test **************************\n");

		for (i = 0; i < ARRAY_SIZE(switches) && pass; i++)
		{
			printf("\nPress %s\n", switches[i].name);
			ret = get_key_pressed(fd, timeout);
			if (ret > 0)
			{
				printf("\nSwitch %d pressed\n", ret);
			}
			if (switches[i].id != ret)
			{
				pass = false;
			}
		}
		close(fd);
		if (pass)
		{
			printf("\nPASS\n");
			return 0;
		}
		else
		{
			if (ret == TIMEOUT_ERROR)
			{
				printf("\nFAIL (no key pressed within timeout)\n");
			}
			else if (ret == OTHER_ERRORS)
			{
				printf("\nFAIL (some other error)\n");
			}
			else
			{
				printf("\nFAIL\n");
			}
			return 1;
		}
	}
}
