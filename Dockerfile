FROM ubuntu:20.04

USER root

WORKDIR /build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y git g++ emacs nano wget zlib1g-dev fftw3-dev libgit2-dev libssl-dev libssh2-1-dev python3.9 python3-pip  libxml2-dev libcurl4-openssl-dev

#install latest cmake
ADD https://cmake.org/files/v3.22/cmake-3.22.2-linux-x86_64.sh /cmake-3.22.2-linux-x86_64.sh

RUN mkdir /opt/cmake \
 && sh /cmake-3.22.2-linux-x86_64.sh --prefix=/opt/cmake --skip-license \
 && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
 && ln -s /opt/cmake/bin/cmake /usr/bin/cmake \
 && cmake --version

RUN git clone --recursive https://github.com/microsoft/LightGBM \
 && cd LightGBM \
 && mkdir build \
 && cd build \
 && cmake .. \
 && make -j4

# install R
RUN apt install -y dirmngr gnupg apt-transport-https ca-certificates software-properties-common
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'
RUN apt install -y r-base build-essential

RUN R -e "install.packages('git2r', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('plotrix', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('geosphere', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('viridis', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('shiny', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('data.table', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('xtable', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('DT', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('shinyFiles', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('shinydashboard', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('lubridate', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('wkb', repos='http://cran.rstudio.com/')" \
 && R -e "install.packages('aws.s3', repos='http://cran.rstudio.com/')"


RUN mkdir /data \
 && mkdir /data1 \
 && mkdir /data2 \
 && mkdir /tutorial \
 && cd /tutorial \
 && wget https://zzz.bwh.harvard.edu/dist/luna/tutorial.zip \
 && unzip tutorial.zip \
 && rm tutorial.zip \
 && ln -s /data/ data


RUN cd /build \
 && git clone https://github.com/remnrem/luna-base.git \
 && git clone https://github.com/remnrem/luna.git \
 && cd luna-base \
 && make -j 2 LGBM=1 LGBM_PATH=/build/LightGBM \
 && ln -s /build/luna-base/luna /usr/local/bin/luna \
 && ln -s /build/luna-base/destrat /usr/local/bin/destrat \
 && ln -s /build/luna-base/behead /usr/local/bin/behead \
 && ln -s /build/luna-base/fixrows /usr/local/bin/fixrows

RUN cd /build \
 && R CMD INSTALL luna

RUN echo 'options(defaultPackages=c(getOption("defaultPackages"),"luna" ) )' > ~/.Rprofile

RUN cd /build \
 && git clone https://gitlab-scm.partners.org/zzz-public/nsrr.git

RUN python3 -m pip install nsrr

COPY nap_run.conf /build/

WORKDIR /data
