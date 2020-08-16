FROM ubuntu:20.04
LABEL name=netdevops
LABEL version=0.0.2
LABEL maintainer="m.klose@route4all.com"

RUN \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install build-essential git nano nmap python3 python3-pip python3-venv tcpdump

# Clean UP
RUN \
  rm -rf /var/lib/apt/lists/* && \
  apt-get clean

COPY root/requirements.txt /root
RUN pip3 install --no-cache-dir -r /root/requirements.txt
