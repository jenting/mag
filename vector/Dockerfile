FROM timberio/vector:0.51.0-debian

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq redis-tools \
    && rm -rf /var/lib/apt/lists/*

COPY vector/vector.toml /etc/vector/vector.toml
COPY scripts/read_redis_stream.sh /usr/local/bin/read_redis_stream.sh
RUN chmod +x /usr/local/bin/read_redis_stream.sh

CMD ["--config", "/etc/vector/vector.toml"]
