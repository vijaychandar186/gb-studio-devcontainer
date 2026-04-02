FROM ubuntu:latest

SHELL ["/bin/bash", "-c"]

# Update sources list and install dependencies
RUN apt update && apt-get --no-install-recommends install --assume-yes \
    git \
    ca-certificates \
    curl \
    make && \
    apt-get --assume-yes autoclean && \
    rm --recursive --force /var/lib/apt/lists/*

# Install nvm
ENV NVM_VERSION=0.40.1
ENV NVM_DIR=/usr/local/nvm

RUN mkdir $NVM_DIR && \
    curl --location --output - https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash

# Install GB Studio
WORKDIR /usr/lib

ARG BRANCH
ENV BRANCH=$BRANCH

RUN source $NVM_DIR/nvm.sh \
    # clone gb-studio (with engine submodule)
    && git clone --single-branch --branch $BRANCH --recurse-submodules https://github.com/chrismaltby/gb-studio.git gb-studio \
    && cd gb-studio \
    # install dependencies
    && nvm install $(cut --delimiter='.' --fields=1 < .nvmrc) --reinstall-packages-from=current \
    && if [ -f ".yarnrc" ]; then \
        npm install --global corepack && \
        corepack enable; \
    else \
        npm install --global yarn; \
    fi \
    && yarn install \
    # fetch build tools (GBDK) for linux-x64
    && npx ts-node src/scripts/fetchDependencies.ts -- --arch=linux-x64 \
    # build
    && npm run make:cli \
    # link cli
    && ln --symbolic $NVM_BIN/node /usr/bin/node \
    && ln --symbolic /usr/lib/gb-studio/out/cli/gb-studio-cli.js /usr/bin/gb-studio-cli \
    && chmod +x out/cli/gb-studio-cli.js \
    # confirm build
    && gb-studio-cli --version \
    # clean
    && npm remove --global yarn

WORKDIR /home/ubuntu
