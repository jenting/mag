# mag

PoC for piping messages from NATS JetStream into Redis Streams with Redpanda Connect.

## Files

- `docker-compose.yml` starts NATS, Redis, Redpanda Connect, and initializes the NATS stream.
- `connect.yaml` configures Redpanda Connect to read from NATS JetStream and write to Redis Streams.

## Run the PoC

```bash
docker compose up -d
```

## Publish a message into NATS

```bash
docker compose run --rm nats-cli \
  nats --server nats://nats:4222 pub orders.created '{"order_id":1,"status":"created"}'
```

## Verify the message in Redis

```bash
docker compose exec redis redis-cli XRANGE orders-created-stream - +
```

You should see the published payload stored under the `body` field in the Redis stream entry.
