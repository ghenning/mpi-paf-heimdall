# Copyright (C) 2016 by Ewan Barr
# Licensed under the Academic Free License version 3.0
# This program comes with ABSOLUTELY NO WARRANTY.
# You are free to modify and redistribute this code as long
# as you do not remove the above attribution and reasonably
# inform receipients that you have modified the original work.

FROM nvidia/cuda:8.0-devel-ubuntu16.04

MAINTAINER Ewan Barr "ebarr@mpifr-bonn.mpg.de"

# Suppress debconf warnings
ENV DEBIAN_FRONTEND noninteractive

# Switch account to root and adding user accounts and password
USER root

# Create space for ssh daemon and update the system
RUN echo 'deb http://us.archive.ubuntu.com/ubuntu trusty main multiverse' >> /etc/apt/sources.list && \
    apt-get -y check && \
    apt-get -y update && \
    apt-get install -y apt-utils apt-transport-https software-properties-common python-software-properties && \
    apt-get -y update --fix-missing && \
    apt-get -y upgrade

# Install dependencies
RUN apt-get --no-install-recommends -y install \
    build-essential \
    autoconf \
    autotools-dev \
    automake \
    autogen \
    libtool \
    csh \
    gcc \
    g++ \
    gfortran \
    wget \
    git \
    cvs \
    expect \
    libcfitsio-dev \
    libltdl-dev \
    gsl-bin \
    libgsl-dev \
    libgsl2 \
    hwloc \
    libhwloc-dev \
    libboost1.58-all-dev \
    pkg-config \
    expect

ENV PSRHOME /software/
ENV OSTYPE linux
RUN mkdir -p $PSRHOME
WORKDIR $PSRHOME

COPY psrdada_cvs_login $PSRHOME
RUN  chmod +x psrdada_cvs_login &&\
     ./psrdada_cvs_login && \
    cvs -z3 -d:pserver:anonymous@psrdada.cvs.sourceforge.net:/cvsroot/psrdada co -P psrdada
ENV PSRDADA_HOME $PSRHOME/psrdada
WORKDIR $PSRDADA_HOME
RUN mkdir build/ && \
    ./bootstrap && \
    ./configure --prefix=$PSRDADA_HOME/build && \
    make && \
    make install && \
    make clean
ENV PATH $PATH:$PSRDADA_HOME/build/bin
ENV PSRDADA_BUILD $PSRDADA_HOME/build/
ENV PACKAGES $PSRDADA_BUILD

# (added) cd into PSRHOME and git clone dedisp and heimdall repos
WORKDIR $PSRHOME
ENV ARSE 1
COPY dedisp $PSRHOME/dedisp
COPY heimdall-astro-code $PSRHOME/heimdall-astro-code

RUN cd $PSRHOME/dedisp && \
    make -j 4
RUN cd $PSRHOME/heimdall-astro-code && \
    ./bootstrap && \
    ./configure --with-dedisp-lib-dir=$PSRHOME/dedisp/lib --with-dedisp-include-dir=$PSRHOME/dedisp/include  --with-cuda-dir=/usr/local/cuda && \
    cp libtool /usr/bin &&\
    make -j 4 && \
    make check && \
    make install && \
    make installcheck && \
    make clean

RUN env | awk '{print "export ",$0}' > $HOME/.profile && \
    echo "source $HOME/.profile" >> $HOME/.bashrc
