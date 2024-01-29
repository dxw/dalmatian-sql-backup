FROM postgres:latest
RUN apt-get update && apt-get install -y awscli && apt-get clean


