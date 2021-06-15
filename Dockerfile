ARG ffmpeg_tag=4.4-nvidia2004
# Sonarr needs to be develop at the moment as it is based on Ubuntu 20.04 LTS which is needed for FFMPEG requirements, where latest is based on Ubuntu 18.04 LTS.
ARG sonarr_tag=develop
FROM jrottenberg/ffmpeg:${ffmpeg_tag} as ffmpeg
FROM ghcr.io/linuxserver/sonarr:${sonarr_tag}
LABEL maintainer="mdhiggins <mdhiggins23@gmail.com>"

# Add files from ffmpeg
COPY --from=ffmpeg /usr/local/ /usr/local/
# and its dependancies
RUN apt update && apt upgrade -y && apt install -y \
     libnppig10
     # libnppicc10 \
     # libnppidei10

ENV SMA_PATH /usr/local/sma
ENV SMA_RS Sonarr
ENV SMA_UPDATE false

# get python3 and git, and install python libraries
RUN \
  apt-get update && \
  apt-get install -y \
    git \
    wget \
#    openssl \
    python3 \
    python3-pip && \
# make directory
  mkdir ${SMA_PATH} && \
# download repo
  git clone https://github.com/mdhiggins/sickbeard_mp4_automator.git ${SMA_PATH} && \
# install pip, venv, and set up a virtual self contained python environment
  python3 -m pip install --user --upgrade pip && \
  python3 -m pip install --user virtualenv && \
  python3 -m virtualenv ${SMA_PATH}/venv && \
  ${SMA_PATH}/venv/bin/pip install -r ${SMA_PATH}/setup/requirements.txt && \
# ffmpeg
  chgrp users /usr/local/bin/ffmpeg && \
  chgrp users /usr/local/bin/ffprobe && \
  chmod g+x /usr/local/bin/ffmpeg && \
  chmod g+x /usr/local/bin/ffprobe && \
# cleanup
  apt-get purge --auto-remove -y && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

RUN \
	apt-get update -y && \
	apt-get install -y --no-install-recommends libva-drm2 libva2 i965-va-driver && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

EXPOSE 8989

VOLUME /config
VOLUME /usr/local/sma/config

# update.py sets FFMPEG/FFPROBE paths, updates API key and Sonarr/Radarr settings in autoProcess.ini
COPY extras/ ${SMA_PATH}/
COPY root/ /
