// read.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#define BUF_SIZE 1024

void readOne(int seq) {
	int fd;
    int ret;
    unsigned char *buf;
    unsigned char *expect;
    char path[30];
    char expChar;

    ret = posix_memalign((void **)&buf, 512, BUF_SIZE);
    if (ret) {
        perror("posix_memalign failed");
        exit(1);
    }
		ret = posix_memalign((void **)&expect, 512, BUF_SIZE);
    if (ret) {
        perror("posix_memalign failed");
        exit(1);
    }

	expChar = seq % 94 + 33;
    memset(expect, expChar, BUF_SIZE);

	sprintf(path, "/mnt/sdb/exp/%d.txt", seq);

    fd = open(path, O_RDONLY | O_DIRECT, 0755);

    if (fd < 0){
        perror("open ./direct_io.data failed");
        exit(1);
    }

    ret = read(fd, buf, BUF_SIZE);
		if (ret < 0) {
			perror("write ./direct_io.data failed");
		}

		// strcmp
		if(strcmp(buf, expect) != 0) {
			perror("not expected");
			perror(path);
			exit(1);
		}

    free(buf);
    close(fd);
}

int main()
{
	  int i;

    for(i = 1; i < 1025; i++) {
        readOne(i); 
    }  

}
