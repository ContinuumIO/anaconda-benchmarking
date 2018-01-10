FROM ubuntu:16.04
MAINTAINER Michael Sarahan <msarahan@anaconda.com>

# Set the locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update && apt-get install -y perl python3 python3-pip python3-venv

WORKDIR /build_scripts
COPY install_miniconda.sh /build_scripts
RUN ./install_miniconda.sh

WORKDIR /envs
COPY create_envs.sh /envs
RUN ./create_envs.sh
