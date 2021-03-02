#include <unistd.h> 
#include <stdio.h> 
#include <sys/socket.h> 
#include <stdlib.h> 
#include <netinet/in.h> 
#include <string.h> 
#define PORT 8080

int main(int argc, char const *argv[]) {
    if (argc < 3) {
        printf("Usage: ./create-pool SST-Dir SST-Num\n");
        return 0;
    }

	int server_fd, new_socket, valread; 
	struct sockaddr_in address; 
	int opt = 1; 
	int addrlen = sizeof(address); 
	char buffer[1024] = {0};
    const char *sst_dir = argv[1];
	int sst_num = atoi(argv[1]);
    bool *bitmap = new bool[sst_num];
    memset(bitmap, false, sizeof(bitmap));

	// Creating socket file descriptor 
	if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) { 
		perror("socket failed"); 
		exit(EXIT_FAILURE); 
	} 
	
	// Forcefully attaching socket to the port 8080 
	if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, 
												&opt, sizeof(opt))) { 
		perror("setsockopt"); 
		exit(EXIT_FAILURE); 
	} 
	address.sin_family = AF_INET; 
	address.sin_addr.s_addr = INADDR_ANY; 
	address.sin_port = htons( PORT ); 
	
	// Forcefully attaching socket to the port 8080 
	if (bind(server_fd, (struct sockaddr *)&address, 
								sizeof(address))<0) { 
		perror("bind failed"); 
		exit(EXIT_FAILURE); 
	}

	if (listen(server_fd, 3) < 0) { 
		perror("listen"); 
		exit(EXIT_FAILURE); 
	}

    while (true) {
        char response[1024] = {0};
        const char *delim = " ";
        if ((new_socket = accept(server_fd, (struct sockaddr *)&address, 
                        (socklen_t*)&addrlen))<0) { 
            perror("accept"); 
            exit(EXIT_FAILURE); 
        } 
        valread = read(new_socket , buffer, 1024);
        printf("recv %s\n", buffer);

        int cur = 0;
        char sst_real[1024];
        char sst_fake[1024];
        char *p = strtok(buffer, delim);
        while(p) {
            while (!bitmap[cur]) cur++;
            bitmap[cur] = true;

            sprintf(sst_real, "%s/%d", sst_dir, cur);
            sprintf(sst_fake, "%s/%06ul.sst", sst_dir, strtoul(p, NULL, 0));
            printf("real %s\nfake %s\n", sst_real, sst_fake);

            if (symlink(sst_real, sst_fake) != 0) {
                perror("symlink"); 
                exit(EXIT_FAILURE); 
            }

            strcat(response, itoa(cur));
            strcat(response, delim);
            p = strtok(NULL, delim);
        }

        printf("send %s\n", response); 
        send(new_socket , response, strlen(response) , 0); 
    } 
	return 0; 
}