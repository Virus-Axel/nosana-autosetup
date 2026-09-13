# nosana-autosetup

An automated script for quick Nosana node setup. I use it on _Ubuntu server 26.04_.

# What this does

Running this one script will install docker and GPU drivers. It will also write a service that will autostart the Nosana node. TTY service will also be disabled. As a result you will see the nosana output instead of a default login prompt on ubuntu server startup.

# How to run

Execute the script with the following command
```bash
wget -qO- https://raw.githubusercontent.com/Virus-Axel/nosana-autosetup/refs/heads/master/setup.sh | bash
```
