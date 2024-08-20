# Software installation, no database files
FROM condaforge/miniforge3:23.3.1-1

# build and run as root users since micromamba image has 'mambauser' set as the $USER
USER root
# set workdir to default for building; set to /data at the end
WORKDIR /

# Version arguments
# ARG variables only persist during build time
# using latest commit as of 2024/08/20
ARG STYLO_COMMIT="acb649c410238b91c582d38ae3af9b5eca6123d4"
ARG STYLO_SRC_URL=https://github.com/ncezid-narst/stylo/archive/${STYLO_COMMIT}.zip

# metadata labels
LABEL base.image="condaforge/miniforge3:23.3.1-1"
LABEL dockerfile.version="1"
LABEL software="stylo-wdl"
LABEL software.version=${STYLO_COMMIT}
LABEL description="A WDL wrapper of ncezid-narst/stylo for Terra.bio"
LABEL website="https://github.com/ncezid-narst/stylo"
LABEL license="https://github.com/ncezid-narst/stylo/blob/main/LICENSE"
LABEL maintainer1="Inês Mendes"
LABEL maintainer.email1="ines.mendes@theiagen.com"

# install dependencies; cleanup apt garbage
RUN apt-get update && apt-get install -y --no-install-recommends \
  wget \
  ca-certificates \
  git \
  procps \
  libtiff5 \
  unzip \
  bsdmainutils && \
  apt-get autoclean && \
  rm -rf /var/lib/apt/lists/*

RUN mamba install -y --name base -c conda-forge -c bioconda -c defaults \
    'bioconda::nanoq==0.10.0' \
    'bioconda::rasusa==0.7.0' \
    'bioconda::flye==2.9.0' \
    'bioconda::unicycler==0.5.0' \
    'bioconda::circlator==1.5.5' \
    'bioconda::medaka==1.11.3' \
    'bioconda::seqtk==1.3' \
    'bioconda::staramr==0.7.1' \
    'bioconda::socru==2.2.4' \
    'bioconda::busco==5.4.6' \
    'bioconda::nextflow==22.10.6' && \
    mamba clean -a -y

# get the mycosnp-nf latest release
RUN wget --quiet "${STYLO_SRC_URL}" && \
 unzip ${STYLO_COMMIT}.zip && \
 rm ${STYLO_COMMIT}.zip && \
 mv -v stylo-${STYLO_COMMIT} stylo

# set the environment, add base conda/micromamba bin directory into path
# set locale settings to UTF-8
# set the environment, put new conda env in PATH by default
ENV PATH="/opt/conda/bin:${PATH}" \
  LC_ALL=C.UTF-8

# Weird error with the workflow
# Unknown config attribute `singularity.SINGULARITY_CACHEDIR` -- check config file: /stylo/config/stylo.config
ENV SINGULARITY_CACHEDIR="/tmp"

# replace the config file with the correct one
COPY stylo.config /stylo/config/stylo.config

# set final working directory to /data
WORKDIR /data