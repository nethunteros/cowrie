FROM debian:jessie-slim
MAINTAINER Michel Oosterhof <michel@oosterhof.net>

# For raspberry pi use
# FROM armhf/debian:jessie

# Fix uid/gid to 1000 for shared volumes
RUN groupadd -r -g 1000 cowrie && \
    useradd -r -g 1000 -d /cowrie -m -g cowrie cowrie

# Set up Debian prereqs
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y \
        -o APT::Install-Suggests=false \
        -o APT::Install-Recommends=false \
      python-pip \
      libssl-dev \
      libmpc-dev \
      libffi-dev \
      build-essential \
      libpython-dev \
      python2.7-minimal \
      git \
      virtualenv \
      python-gmpy2 \
      python-virtualenv \
      python-setuptools

COPY . /cowrie/cowrie-git
RUN mkdir -p /cowrie/cowrie-git
RUN chown -R cowrie:cowrie /cowrie/cowrie-git
RUN su - cowrie -c "\
      cd /cowrie/cowrie-git && \
        virtualenv cowrie-env && \
        . cowrie-env/bin/activate && \
        pip install --upgrade cffi && \
        pip install -r ~cowrie/cowrie-git/requirements.txt" && \

    # Remove all the build tools to keep the image small.
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get remove -y --purge \
      git \
      python-pip \
      python-setuptools \
      libmpfr-dev \
      libssl-dev \
      libmpc-dev \
      libffi-dev \
      build-essential \
      libpython-dev \
      python3.4* && \
    # Remove any auto-installed depends for the build and any temp files and package lists.
    apt-get autoremove -y && \
    dpkg -l | awk '/^rc/ {print $2}' | xargs dpkg --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER cowrie
WORKDIR /cowrie/cowrie-git
CMD [ "/cowrie/cowrie-git/bin/cowrie", "start", "-n" ]
EXPOSE 2222 2223
VOLUME [ "/cowrie/cowrie-git/etc", "/cowrie/cowrie-git/var" ]
