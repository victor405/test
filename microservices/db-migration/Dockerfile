FROM flyway/flyway:9

# switch to root ONLY to install deps
USER root

RUN apt-get update && apt-get install -y awscli jq && \
    rm -rf /var/lib/apt/lists/*

# switch back to non-root (flyway user)
USER flyway

# copy sql files (ensure ownership)
COPY --chown=flyway:flyway sql/ /flyway/sql/

# run migrations
CMD ["sh", "-c", "\
  echo 'Fetching DB credentials...' && \
  SECRET=$(aws secretsmanager get-secret-value \
    --secret-id $DB_SECRET_ARN \
    --region $AWS_REGION \
    --query SecretString \
    --output text) && \
  DB_HOST=$(echo $SECRET | jq -r .host) && \
  DB_USER=$(echo $SECRET | jq -r .username) && \
  DB_PASS=$(echo $SECRET | jq -r .password) && \
  DB_NAME=$(echo $SECRET | jq -r .dbname) && \
  echo 'Running Flyway migrations...' && \
  flyway \
    -url=jdbc:mysql://$DB_HOST:3306/$DB_NAME \
    -user=$DB_USER \
    -password=$DB_PASS \
    -locations=filesystem:/flyway/sql \
    migrate \
"]