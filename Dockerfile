FROM jrottenberg/ffmpeg:4-nvidia

# avoid interactive prompts from apt
ARG DEBIAN_FRONTEND=noninteractive

# append nzbget path to PATH variable
ENV PATH="/opt/nzbget:${PATH}"

# install apt dependencies
RUN apt update && \
  apt -y dist-upgrade && \
  apt -y install curl git python3 python3-pip

# install pip3 dependencies
RUN pip3 install \
  babelfish \
  guessit \
  idna \
  mutagen \
  python-dateutil \
  pymediainfo \
  qtfaststart \
  requests \
  requests-cache \
  setuptools \
  stevedore \
  subliminal \
  tmdbsimple

# install nzbget
RUN mkdir -p /opt/nzbget && \
  curl -Lo /tmp/nzbget.run $(curl -s https://nzbget.net/info/nzbget-version-linux.json | grep "stable-download" | cut -d '"' -f 4) && \
  sh /tmp/nzbget.run --destdir /opt/nzbget && \
  rm -f /tmp/nzbget.run

# install mp4-automator and symlink config file
RUN mkdir -p /opt/mp4-automator && \
  git clone --depth=1 https://github.com/mdhiggins/sickbeard_mp4_automator.git /opt/mp4-automator && \
  rm -f /opt/mp4-automator/config/autoProcess.ini && \
  ln -sf /config/autoProcess.ini /opt/mp4-automator/config/autoProcess.ini && \
  ln -sf /config/logging.ini /opt/mp4-automator/config/logging.ini && \
  chmod 777 /opt/mp4-automator/config

# remove apt cache
RUN rm -rf /var/lib/apt/lists/

# volume mappings
VOLUME /config /downloads

# export nzbget port
EXPOSE 6789/tcp

# create user
RUN groupadd -g 1100 nzbget && \
  useradd -m -d /home/nzbget -s /bin/bash -u 1100 -g 1100 nzbget

# stop running things as root
USER nzbget

# set workdir
WORKDIR /opt/nzbget

# set entrypoint
ENTRYPOINT ["/opt/nzbget/nzbget", "-s", "-o", "OutputMode=log", "-c", "/config/nzbget.conf"]
