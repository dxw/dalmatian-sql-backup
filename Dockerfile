FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y \
    awscli \
    postgresql-client \
    wget \
    curl \
    gnupg \
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

