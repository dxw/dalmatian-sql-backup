# Docker image for PostgresSQL backups on Dalmatian to S3

We use this image to backup our PostgresSQL databases to S3. It is based on the
[official PostgresSQL image](https://hub.docker.com/_/postgres/) but adds the
[AWS CLI](https://aws.amazon.com/cli/) so that we can push to S3. It also adds
AWS certs.
