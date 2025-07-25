FROM golang:1.24.5-alpine3.21@sha256:6edc20586dd08dacad538c1f09984bc2aa61720be59056cf75429691f294d731 AS azcopy
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
    wget \
    curl \
    gnupg \
    procps \
    lsb-release \
    && apt-get clean

RUN mkdir -p /etc/apt/keyrings

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
 | gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update \
  && apt-get install -y postgresql-client-16

RUN key='BCA4 3417 C3B4 85DD 128E C6D4 B7B3 B788 A8D3 785C'; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
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
