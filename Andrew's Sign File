#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

/* Andrew Fuller <abf@google.com>
   serial interface for the pro-lite pl-m2014r LED sign
*/

/*
working serial settings:
speed 9600 baud; line = 0;
kill = ^H; min = 100; time = 2;
-icrnl -imaxbel
-opost -onlcr
-isig -icanon -echo

    usleep(10000);

    put(fd, "<ID00>\r\n");
    put(fd, "<ID00><PA>");
    put(fd, argv[1]);
    put(fd, "\r\n");
*/

void put(int fd, char *msg)
{
  int rc;
  int i;

  for (i = 0; i < strlen(msg); i++) {
    rc = write(fd, &msg[i], 1);
    if (rc != 1)
      perror("write");
    usleep(10000);
  }
}

int main(int argc, char **argv)
{
  char buf[256];
  int fd = open(argv[1], O_WRONLY);
  perror("open");

  snprintf(buf, sizeof(buf), "<ID01>\r\n");
  put(fd, buf);
  snprintf(buf, sizeof(buf), "<ID01>%s\r\n", argv[1]);
  put(fd, buf);
  if (argc > 2) {
    usleep(100000);
    snprintf(buf, sizeof(buf), "<ID01><PA><FX>\r\n");
    put(fd, buf);
  }
}
