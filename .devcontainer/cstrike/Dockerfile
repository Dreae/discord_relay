FROM fedora

RUN dnf -y install libgcc.i686 libstdc++.i686 glibc.i686 unzip gdb ncurses-libs.i686

RUN useradd -ms /bin/bash steam
WORKDIR /home/steam

USER steam

RUN curl -o /tmp/steamcmd_linux.tar.gz http://media.steampowered.com/installer/steamcmd_linux.tar.gz && \
    tar -xvzf /tmp/steamcmd_linux.tar.gz && \
    rm /tmp/steamcmd_linux.tar.gz

# Install CSS once to speed up container startup
RUN ./steamcmd.sh +login anonymous +force_install_dir ./css +app_update 232330 validate +quit # Update to date as of 2016-02-06

ENV CSS_HOSTNAME Counter-Strike Source Dedicated Server
ENV CSS_PASSWORD ""
ENV RCON_PASSWORD mysup3rs3cr3tpassw0rd

EXPOSE 27015/udp
EXPOSE 27015
EXPOSE 1200
EXPOSE 27005/udp
EXPOSE 27020/udp
EXPOSE 26901/udp

# Support for 64-bit systems
# https://www.gehaxelt.in/blog/cs-go-missing-steam-slash-sdk32-slash-steamclient-dot-so/
RUN ln -s /home/steam/linux32/ /home/steam/.steam/sdk32

# Add Source Mods
COPY --chown=steam:steam mods/ /temp
RUN cd /home/steam/css/cstrike && \
    tar zxvf /temp/mmsource-1.10.7-git971-linux.tar.gz && \
    tar zxvf /temp/sourcemod-1.10.0-git6488-linux.tar.gz
RUN cp /temp/cryptosocket.ext.so /home/steam/css/cstrike/addons/sourcemod/extensions/

USER steam
WORKDIR css/
