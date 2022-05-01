// write.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#define BUF_SIZE 1024


void writeOne(int seq) {
    int fd;
    int ret;
    unsigned char *buf;
    char path[30];
    char myChar;

    ret = posix_memalign((void **)&buf, 512, BUF_SIZE);
    if (ret) {
        perror("posix_memalign failed");
        exit(1);
    }

    // get the name of the file
    sprintf(path, "/mnt/remote/exp/%d.txt", seq);
    printf("%s\n", path);

    myChar = seq % 94 + 33;
    memset(buf, myChar, BUF_SIZE);
    
    fd = open(path, O_WRONLY | O_DIRECT | O_SYNC | O_CREAT, 0755);
    if (fd < 0){
        perror("open ./direct_io.data failed");
        exit(1);
    }

    ret = write(fd, buf, BUF_SIZE);
    if (ret < 0) {
        perror("write ./direct_io.data failed");
    }

    free(buf);
    close(fd);
}

int main(int argc, char * argv[])
{
    int i;

    for(i = 1; i < 1025; i++) {
        writeOne(i); 
    }  
}
