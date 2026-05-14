# mag

PoC for replicating Redis primary key/value entries to 20 Redis replicas via NATS JetStream and Redpanda Connect.

## Architecture

```
[Application]
    │  XADD orders * key <k> value <v>
    ▼
redis-primary (port 6379)
    │
    └──► connect-publisher  (redis_streams → nats_jetstream)
                │
                ▼
    NATS JetStream  (stream: orders, subject: orders.created)
                │
    ┌───────────┼────────────┐  ...  ┐
    ▼           ▼            ▼       ▼
connect-    connect-     connect-  connect-
replica-1   replica-2    replica-3 ... replica-20
    │           │            │           │
redis-      redis-       redis-      redis-
replica-1   replica-2    replica-3   replica-20
(port 6380) (port 6381)  (port 6382) (port 6399)
```

`connect-publisher` reads entries from the `orders` Redis Stream on `redis-primary` and publishes them to the `orders.created` NATS JetStream subject. Each `connect-replica-N` uses its own durable NATS consumer (`redis-replica-N-sink`) so every replica independently receives all messages and writes them to its own Redis hash — true event-driven fan-out with no coupling between replicas.

## Files

- `docker-compose.yml` — starts NATS, redis-primary, 20 redis-replica services, connect-publisher, 20 connect-replica services, and the NATS stream initializer.
- `connect-publisher.yaml` — Redpanda Connect pipeline: reads from the `orders` Redis Stream on redis-primary → publishes to NATS JetStream `orders.created`.
- `connect-replica.yaml` — Redpanda Connect template (uses `${REDIS_HOST}` and `${NATS_DURABLE}` env vars): subscribes to NATS JetStream `orders.created` → upserts fields in a Redis hash on the target replica.

## Run the PoC

```bash
docker compose up -d
```

## Publish a key/value entry to Redis primary

```bash
docker compose exec redis-primary redis-cli XADD orders '*' key order:1 value created
```

## Verify replication across replicas

Check a sample of replicas (all should converge within a second):

```bash
docker compose exec redis-replica-1  redis-cli HGET orders-created-kv order:1
docker compose exec redis-replica-10 redis-cli HGET orders-created-kv order:1
docker compose exec redis-replica-20 redis-cli HGET orders-created-kv order:1
```

You should see `created` on every replica.

Publish an update:

```bash
docker compose exec redis-primary redis-cli XADD orders '*' key order:1 value updated
```

Verify again — all replicas should show `updated`.
