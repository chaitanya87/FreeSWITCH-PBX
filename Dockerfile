FROM debian:buster

# explicitly set user/group IDs
RUN groupadd -r freeswitch --gid=999 && useradd -r -g freeswitch --uid=999 freeswitch

# make the "en_US.UTF-8" locale so freeswitch will be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# https://files.freeswitch.org/repo/deb/freeswitch-1.*/dists/jessie/main/binary-amd64/Packages

#https://freeswitch.org/confluence/display/FREESWITCH/Debian+10+Buster#InstallingfromDebianpackages

RUN apt-get update && apt-get install -y gnupg2 wget lsb-release \
    && wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add - \
    && echo "deb http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list \
    && echo "deb-src http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list

RUN apt-get update && apt-get install -y freeswitch-meta-all \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clean up
RUN apt-get autoremove

COPY docker-entrypoint.sh /
## Ports
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 16384-16494/udp


# Volumes
## Freeswitch Configuration
VOLUME ["/etc/freeswitch"]
## Tmp so we can get core dumps out
VOLUME ["/tmp"]

# Limits Configuration
COPY    freeswitch.limits.conf /etc/security/limits.d/

# Healthcheck to make sure the service is running
SHELL       ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  fs_cli -x status | grep -q ^UP || exit 1

## Add additional things here

## User Directory
COPY  int.example.net.xml /etc/freeswitch/directory/

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["freeswitch"]
