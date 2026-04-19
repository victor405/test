FROM flyway/flyway:9

USER root

RUN apt-get update && apt-get install -y awscli jq && \
    rm -rf /var/lib/apt/lists/*

COPY sql/ /flyway/sql/