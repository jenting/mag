# mag

PoC for piping messages from NATS JetStream into Redis hash key/value entries with Redpanda Connect.

## Files

- `docker-compose.yml` starts NATS, Redis, Redpanda Connect, and initializes the NATS stream.
- `connect.yaml` configures Redpanda Connect to read from NATS JetStream and upsert fields in a Redis hash.

## Run the PoC

```bash
docker compose up -d
```

## Publish a key/value message into NATS

```bash
docker compose run --rm nats-cli \
  nats --server nats://nats:4222 pub orders.created '{"key":"order:1","value":"created"}'
```

## Verify create/update in Redis

```bash
docker compose exec redis redis-cli HGET orders-created-kv order:1
```

You should see the value `created` (Redis CLI may render this as `created` or `"created"`).

Publish an update with the same key:

```bash
docker compose run --rm nats-cli \
  nats --server nats://nats:4222 pub orders.created '{"key":"order:1","value":"updated"}'
```

Then verify again:

```bash
docker compose exec redis redis-cli HGET orders-created-kv order:1
```

You should now see `updated` (or `"updated"` in quoted CLI output).
