FROM ubuntu:18.04

LABEL maintainer Team STINGAR <team-stingar@duke.edu>
LABEL name "conpot"
LABEL version "1.9"
LABEL release "1"
LABEL summary "Conpot Honeypot container"
LABEL description "Conpot is an ICS honeypot with the goal to collect intelligence about the motives and methods of adversaries targeting industrial control systems"
LABEL authoritative-source-url "https://github.com/CommunityHoneyNetwork/conpot"
LABEL changelog-url "https://github.com/CommunityHoneyNetwork/conpot/commits/master"

# Set DOCKER var - used by Conpot init to determine logging
ENV DOCKER "yes"
ENV CONPOT_USER "conpot"
ENV CONPOT_GROUP "conpot"
ENV CONPOT_DIR "/opt/conpot"
ENV CONPOT_JSON "/etc/conpot/conpot.json"

RUN mkdir /code
ADD output /code/output
ADD requirements.txt conpot.cfg.template entrypoint.sh /code/

RUN apt-get update \
    && apt-get install -y python-apt gettext-base \
    && apt-get install -y ipmitool tcpdump git jq python3-dev \
        wget python3-cffi libxslt-dev libffi-dev libssl-dev python3-pip \
    && pip3 install -r /code/requirements.txt

RUN groupadd -r -g 1000 ${CONPOT_GROUP} && \
    useradd -r -u 1000 -m -g ${CONPOT_GROUP} ${CONPOT_USER} && \
    mkdir /var/log/conpot && \
    chown conpot:conpot -R /var/log/conpot && \
    mkdir /opt/conpot && \
    chown conpot:conpot -R /opt/conpot && \
    chmod +x /code/entrypoint.sh

WORKDIR ${CONPOT_DIR}

RUN pip3 install --no-cache-dir --upgrade pip pika requests fluent-logger cymruwhois setuptools coverage

RUN mkdir -p /etc/conpot /var/log/conpot /usr/share/wireshark && \
    wget https://github.com/wireshark/wireshark/raw/master/manuf -o /usr/share/wireshark/manuf
RUN chown $CONPOT_USER /etc/conpot /var/log/conpot
USER $CONPOT_USER
RUN git clone --branch Release_0.6.0 https://github.com/mushorg/conpot.git

WORKDIR ${CONPOT_DIR}/conpot
RUN pip3 install --no-cache-dir -r requirements.txt
RUN python3 setup.py install --user --prefix=

COPY output/log_worker.py ${CONPOT_DIR}/conpot/conpot/core/loggers

ENV PATH=$PATH:/home/conpot/.local/bin
ENTRYPOINT ["/code/entrypoint.sh"]
