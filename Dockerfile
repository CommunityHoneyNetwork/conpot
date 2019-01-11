FROM ubuntu:18.04

LABEL maintainer Alexander Merck <alexander.t.merck@gmail.com>
LABEL name "wordpot"
LABEL version "0.2"
LABEL release "1"
LABEL summary "Conpot Honeypot container"
LABEL description "Conpot is an ICS honeypot with the goal to collect intelligence about the motives and methods of adversaries targeting industrial control systems"
LABEL authoritative-source-url "https://github.com/CommunityHoneyNetwork/conpot"
LABEL changelog-url "https://github.com/CommunityHoneyNetwork/conpot/commits/master"

# Set DOCKER var - used by Conpot init to determine logging
ENV DOCKER "yes"
ENV playbook "conpot.yml"

RUN apt-get update \
      && apt-get install -y ansible python-apt

RUN echo "localhost ansible_connection=local" >> /etc/ansible/hosts
ADD . /opt/
RUN ansible-playbook /opt/${playbook}

ENTRYPOINT ["/usr/bin/runsvdir", "-P", "/etc/service"]
