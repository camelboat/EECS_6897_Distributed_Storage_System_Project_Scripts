#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/stat.h> 
#include <string.h>
#define BUF_SIZE 65 * 1024 * 1024
 
int main(int argc, char * argv[]) {
    if (argc < 3) {
        printf("Usage: ./create-pool SST-Dir SST-Num\n");
        return 0;
    }

    int fd;
    int ret;
    unsigned char *buf;
    char *sst_dir = argv[1];
    int sst_num = atoi(argv[2]);
    printf("sst_dir %s\nsst_num %d\n", sst_dir, sst_num);

    ret = posix_memalign((void **)&buf, 512, BUF_SIZE);
    if (ret) {
        perror("posix_memalign failed");
        exit(1);
    }
    memset(buf, 'c', BUF_SIZE);
 
    for (int i = 0; i < sst_num; i++) {
        char sst_name[128];
        sprintf(sst_name, "%s%d.sst", sst_dir, i);
        fd = open(sst_name, O_WRONLY | O_DIRECT | O_CREAT, 0755);
        if (fd < 0) {
            perror("open sst failed");
            exit(1);
        }
    
        ret = write(fd, buf, BUF_SIZE);
        if (ret < 0) {
            perror("write sst failed");
        }

        close(fd);
    }
 
    free(buf);
    printf("Done!\n");
}