FROM ubuntu:16.04

# ------------------------------------------------------------------------------------------------
# install build and release tools
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yy -q --no-install-recommends \
        awscli \
        build-essential \
        ca-certificates \
        curl \
        docker.io \
        git \
        jq \
        lsb-release \
        make \
        rsync \
        runit \
        sudo \
        zip && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y && \
    DEBIAN_FRONTEND=noninteractive apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------------------------------------------------------------------------------------------
# Go support
RUN GO_VERSION=1.11 && \
    GO_HASH=b3fcf280ff86558e0559e185b601c9eade0fd24c900b4c63cd14d1d38613e499 && \
    curl -fsSL https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz -o golang.tar.gz && \
    echo "${GO_HASH}  golang.tar.gz" | sha256sum -c - && \
    tar -C /usr/local -xzf golang.tar.gz && \
    rm golang.tar.gz
ENV PATH /usr/local/go/bin:$PATH

# precompile the go standard library for all supported platforms and configurations
# the install suffixes match those in golang.mk so please keep them in sync
RUN platforms="darwin_amd64 windows_amd64 linux_amd64 linux_arm64" && \
    for p in $platforms; do CGO_ENABLED=0 GOOS=${p%_*} GOARCH=${p##*_} GOARM=7 go install -installsuffix static -a std; done

# ------------------------------------------------------------------------------------------------
# Node JS and chrome support
RUN curl -fsSL https://deb.nodesource.com/setup_10.x | bash - && \
    curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yy -q --no-install-recommends \
        nodejs \
        google-chrome-stable \
        xvfb && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y && \
    DEBIAN_FRONTEND=noninteractive apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -f /etc/apt/sources.list.d/google.list

# setup chrome to run inside the container
ADD xvfb-chrome /usr/bin/xvfb-chrome
RUN ln -fs /usr/bin/xvfb-chrome /usr/bin/google-chrome
ENV CHROME_BIN /usr/bin/google-chrome

# ------------------------------------------------------------------------------------------------
# Install some tools we use

RUN npm install -g mjml

# ------------------------------------------------------------------------------------------------
# Run tini as PID 1 and avoid signal handling issues
ARG ARCH
ARG TINI_VERSION
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${ARCH} /tini
RUN chmod +x /tini

COPY run.sh rsyncd.sh /build/

ENTRYPOINT [ "/tini", "-g", "--", "/build/run.sh" ]
