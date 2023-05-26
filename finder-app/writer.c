#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>

const int path_to_file_arg_index = 1;
const int string_to_write_arg_index = 2;
int main(int argc, char *argv[]) {
	int fd;
	openlog(NULL, 0, LOG_USER); 
	
	fd = open(argv[path_to_file_arg_index], O_WRONLY | O_CREAT, S_IRWXU );
	if (fd == -1)
		{
		/* error */
		syslog(LOG_ERR,"File not succesfully closed. errno: %d", errno);
		return 1;
		}
	else
		{
		write(fd, (char *)(argv[string_to_write_arg_index]), strlen((char *)(argv[string_to_write_arg_index])) );
		syslog(LOG_DEBUG,"Writing %s to %s.", (char *)(argv[string_to_write_arg_index]), (char *)(argv[path_to_file_arg_index]));
		if (close (fd) == -1)
			{
			/* error */
			syslog(LOG_ERR,"File not succesfully closed. errno: %d", errno);
			return 1;
			}
		}
	return 0;
}

