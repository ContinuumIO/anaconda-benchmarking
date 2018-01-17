FROM ubuntu:16.04
MAINTAINER Michael Sarahan <msarahan@anaconda.com>

# Set the locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL C

WORKDIR /envs
COPY create_envs.sh /envs
RUN bash create_envs.sh

ENV OMP_THREAD_LIMIT 1
ENV MKL_NUM_THREADS 1
ENV OMP_NUM_THREADS 1
