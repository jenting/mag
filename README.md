# mag

PoC for replicating Redis key/value entries across multiple Redis instances via NATS JetStream and Redpanda Connect.

## Architecture

```
Publisher
    │
    ▼
NATS JetStream (stream: orders, subject: orders.created)
    │
    ├──► connect-primary  ──► redis-primary  (port 6379)
    │
    ├──► connect-replica-1 ──► redis-replica-1 (port 6380)
    │
    └──► connect-replica-2 ──► redis-replica-2 (port 6381)
```

Each Redpanda Connect worker subscribes to the same NATS JetStream subject using its own durable consumer name, so every Redis instance independently receives and applies every message.

## Files

- `docker-compose.yml` starts NATS, three Redis instances (primary + 2 replicas), three Redpanda Connect workers, and initializes the NATS stream.
- `connect-primary.yaml` configures Redpanda Connect to read from NATS JetStream and upsert fields in the primary Redis hash.
- `connect-replica-1.yaml` configures Redpanda Connect to read from NATS JetStream and upsert fields in the first replica Redis hash.
- `connect-replica-2.yaml` configures Redpanda Connect to read from NATS JetStream and upsert fields in the second replica Redis hash.

## Run the PoC

```bash
docker compose up -d
```

## Publish a key/value message into NATS

```bash
docker compose run --rm nats-cli \
  nats --server nats://nats:4222 pub orders.created '{"key":"order:1","value":"created"}'
```

## Verify replication across all Redis instances

Check the primary:

```bash
docker compose exec redis-primary redis-cli HGET orders-created-kv order:1
```

Check replica 1:

```bash
docker compose exec redis-replica-1 redis-cli HGET orders-created-kv order:1
```

Check replica 2:

```bash
docker compose exec redis-replica-2 redis-cli HGET orders-created-kv order:1
```

You should see the value `created` on all three instances.

Publish an update with the same key:

```bash
docker compose run --rm nats-cli \
  nats --server nats://nats:4222 pub orders.created '{"key":"order:1","value":"updated"}'
```

Then verify again on all three instances — all should show `updated`.
