FROM thedreae/devcontainer

USER root
RUN dnf -y install elixir erlang git inotify-tools nodejs

USER dev
COPY --chown=dev:dev tools/ /temp
RUN tar -xvf /temp/sourcemod-1.10.0-git6488-linux.tar.gz