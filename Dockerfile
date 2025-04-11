FROM golang:1.24.2-alpine3.21@sha256:7772cb5322baa875edd74705556d08f0eeca7b9c4b5367754ce3f2f00041ccee AS azcopy
ARG TARGETARCH
ENV GOARCH=$TARGETARCH GOOS=linux
WORKDIR /usr/bin
RUN apk update \
    && apk add --no-cache libc6-compat ca-certificates
ADD "https://github.com/Azure/azure-storage-azcopy/archive/v10.28.1.tar.gz" azcopy.tgz
RUN tar xf azcopy.tgz --strip 1 && \
    go build -o azcopy && ./azcopy --version

FROM debian:bookworm-slim@sha256:b1211f6d19afd012477bd34fdcabb6b663d680e0f4b0537da6e6b0fd057a3ec3

RUN apt-get update && \
    apt-get install -y \
    awscli \
    postgresql-client \
    wget \
    curl \
    gnupg \
    procps \
#    default-mysql-client \
    && apt-get clean

RUN key='BCA4 3417 C3B4 85DD 128E C6D4 B7B3 B788 A8D3 785C'; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
    mkdir -p /etc/apt/keyrings; \
    gpg --batch --export "$key" > /etc/apt/keyrings/mysql.gpg; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME"
RUN echo 'deb [ signed-by=/etc/apt/keyrings/mysql.gpg ] http://repo.mysql.com/apt/debian/ bookworm mysql-8.0' > /etc/apt/sources.list.d/mysql.list \
    && apt-get update \
    && apt-get install -y mysql-community-client \
    && rm -f /etc/apt/keyrings/mysql.gpg /etc/apt/sources.list.d/mysql.list \
    && apt-get update \
    && apt-get clean

COPY ./bin/. /usr/local/bin/
COPY --from=azcopy /usr/bin/azcopy /usr/local/bin/azcopy
