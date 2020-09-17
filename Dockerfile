FROM ubuntu:18.04
# hadolint ignore=DL3008,DL3005

LABEL maintainer Team STINGAR <team-stingar@duke.edu>
LABEL name "conpot"
LABEL version "1.9"
LABEL release "1"
LABEL summary "Conpot Honeypot container"
LABEL description "Conpot is an ICS honeypot with the goal to collect intelligence about the motives and methods of adversaries targeting industrial control systems"
LABEL authoritative-source-url "https://github.com/CommunityHoneyNetwork/conpot"
LABEL changelog-url "https://github.com/CommunityHoneyNetwork/conpot/commits/master"

# Set DOCKER var - used by Conpot init to determine logging
ENV DEBIAN_FRONTEND "noninteractive"
ENV DOCKER "yes"
ENV CONPOT_USER "conpot"
ENV CONPOT_GROUP "conpot"
ENV CONPOT_DIR "/opt/conpot"
ENV CONPOT_JSON "/etc/conpot/conpot.json"

# hadolint ignore=DL3008,DL3005
RUN apt-get update \
    && apt-get install --no-install-recommends -y python-apt gettext-base build-essential\
    && apt-get install --no-install-recommends -y ipmitool tcpdump git jq python3-dev \
        wget python3-cffi libxslt-dev libffi-dev libssl-dev python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /code
COPY output /code/output
COPY requirements.txt conpot.cfg.template entrypoint.sh /code/
RUN python3 -m pip install --upgrade pip setuptools wheel \
  && python3 -m pip install --no-cache-dir --upgrade pip pika requests fluent-logger cymruwhois setuptools coverage \
  && python3 -m pip install --no-cache-dir -r /code/requirements.txt

RUN groupadd -r -g 1000 ${CONPOT_GROUP} && \
    useradd -r -u 1000 -m -g ${CONPOT_GROUP} ${CONPOT_USER} && \
    mkdir /var/log/conpot /etc/conpot && \
    chown ${CONPOT_USER}:${CONPOT_GROUP} -R /var/log/conpot /etc/conpot && \
    mkdir /opt/conpot && \
    chown ${CONPOT_USER}:${CONPOT_GROUP} -R /opt/conpot && \
    chmod +x /code/entrypoint.sh

WORKDIR ${CONPOT_DIR}

RUN mkdir -p /etc/conpot /var/log/conpot /usr/share/wireshark && \
    wget https://github.com/wireshark/wireshark/raw/master/manuf -o /usr/share/wireshark/manuf

USER $CONPOT_USER
RUN git clone --branch Release_0.6.0 https://github.com/mushorg/conpot.git
COPY output/log_worker.py ${CONPOT_DIR}/conpot/conpot/core/loggers

WORKDIR ${CONPOT_DIR}/conpot

RUN python3 -m pip install --no-cache-dir -r requirements.txt \
  && python3 setup.py install --user --prefix=

ENV PATH=$PATH:/home/conpot/.local/bin
ENTRYPOINT ["/code/entrypoint.sh"]
