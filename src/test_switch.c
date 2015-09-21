/*
 * This test is for testing the two switches on the marduk board
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <linux/input.h>


#define SWITCH_1_CODE	257
#define SWITCH_2_CODE	258

int main (int argc, char *argv[])
{
	struct input_event ev[64];
	int fd, rd, i;
	char *device = "/dev/input/event1";

	printf("**************************** Switch test **************************\n");

	// Open input device
	if ((fd = open(device, O_RDONLY)) == -1)
	{
		printf("Error: %s is not a vaild device.\n", device);
		exit(-1);
	}

	printf("\nWaiting for switches to get pressed\n");

	// Wait for events from the device
	while (1)
	{
		rd = read(fd, ev, sizeof(ev));
		if (rd < (int) sizeof(struct input_event))
		{
			printf("Error: expected event %d bytes, got %d\n", (int) sizeof(struct input_event), rd);
			close(fd);
			return 1;
		}

		for (i = 0; i < rd / sizeof(struct input_event); i++)
		{
			if (ev[i].type == EV_KEY)
			{
				if(ev[i].code == SWITCH_1_CODE)
					printf("SWITCH 1 %s\n", ev[i].value == 1?"ON":"OFF");
				else if(ev[i].code == SWITCH_2_CODE)
					printf("SWITCH 2 %s\n", ev[i].value == 1?"ON":"OFF");
			}
		}
	}

	return 0;
}
