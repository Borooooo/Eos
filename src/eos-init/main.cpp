#include <iostream>
#include <sys/mount.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <unistd.h>
#include <signal.h>
#include <cerrno>
#include <cstring>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <linux/if.h>

// pid 1 needs to be on 24/7

void mout_fs(const char* source, const char* target, const char* type) {
    mkdir(target, 0755);

    if(mount(source, target, type, 0, nullptr) == 0) {
        std::cout << "mounted " << type << " in " << target << std::endl;
    }
    else {
        std::cerr << "error " << type << " on " << target << " : " << strerror(errno) << std::endl;
    }
}


volatile sig_atomic_t keep_running = 1;

void signal_handler(int signal) {
    switch(signal) {
        case SIGINT: // ctrl + c or ctrl + alt + del
            std::cout << "rebooting..." << std::endl;
            keep_running = 0;
            break;

        case SIGTERM: // kill [PID]
            std::cout << " shutting down..." << std::endl;
            keep_running = 0;
            break;
    }
}

void setup_signals() { 
    struct sigaction sa;

    sa.sa_handler = signal_handler; // function handler
    sigemptyset(&sa.sa_mask); // dont block other signals while handling
    sa.sa_flags = 0;

    if(sigaction(SIGINT, &sa, nullptr) == -1) {
        perror("erorr sigaction SIGINT");
    }
    if(sigaction(SIGTERM, &sa, nullptr) == -1) {
        perror("errpr sigaction SIGTERM");
    }

}

void cleanup_and_reboot() {
    std::cout << "disk sync" << std::endl;
    sync();

    std::cout << "unmounting system files /proc, /sys, /dev";
    umount("/proc");
    umount("/sys");
    umount("/dev");


}
void start_shell() {
    pid_t pid = fork();

    if(pid == -1) perror("FORK FAILED");
    else if( pid == 0) {
        char *argv[] = { (char *) "/bin/sh", nullptr};
        char *envp[] = {nullptr}; // env. variables

        std::cout << "starting /bin/sh" << std::endl;

        execve("/bin/sh", argv, envp); // swaping programs

        perror("execve failed, no file");

        _exit(1);
    }
    else {
        std::cout << "[INIT] PID started: " << pid << std::endl;

        int status;

        waitpid(pid, &status, 0);

        std::cout << "[INIT] pid ended" << std::endl;
    }

}


void setup_network() {
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if(fd < 0 ){
        std::cerr << "error while opening socket for network: " << strerror(errno) << std::endl;
        return;
    }

    struct ifreq ifr;
    
    memset(&ifr, 0, sizeof(ifr));
    strcpy(ifr.ifr_name, "lo");

    // getting flags
    if (ioctl(fd, SIOCGIFFLAGS, &ifr) < 0) {
        std::cerr << "error while getting lo flags: " << strerror(errno) << std::endl;
        close(fd);
        return;
    }
    //setup flags up and running
    ifr.ifr_flags |= IFF_UP | IFF_RUNNING;


    // saving the flags
    if (ioctl(fd, SIOCSIFFLAGS, &ifr) < 0) {
        std::cerr << "error while setting lo flahs: " << strerror(errno) << std::endl;
    }
    else {
        std::cout << "network interface 'lo' is up" << std::endl;
    }

    close(fd);
}




int main() {
    sethostname("Eos", 3);
    
    std::cout << "starting PID1" << std::endl;

    mout_fs("none", "/proc", "proc");
    mout_fs("none", "/sys", "sysfs");
    mout_fs("devtmpfs", "/dev", "devtmpfs");

    
    mount("tmpfs", "/tmp", "tmpfs", 0, nullptr);
    mount("tmpfs", "/run", "tmpfs", 0, nullptr);

    setup_network();
    setup_signals();

    start_shell();

    std::cout << "PID1 READY" << std::endl;

    while(keep_running) {
        int status;

        pid_t p = waitpid(-1, &status, 0);
        
        if(p < 0) {
            if(errno == ECHILD) {
                sleep(1);
            }
            else if(errno == EINTR) {
                continue;
            }
        }
        else {
            std::cout << "reaped process PID: " << p << std::endl;

            if(WIFEXITED(status)) {
                std::cout << "exited with stats: " << WEXITSTATUS(status) << std::endl;
            }
            else if(WIFSIGNALED(status)) {
                std::cout << "killed by signal: " << WTERMSIG(status) << std::endl;
            }
        }
        pause();
    }

    cleanup_and_reboot();
}

