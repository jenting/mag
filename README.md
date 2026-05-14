# mag

PoC for **Redis Stream → Vector → NATS JetStream**.

## Requirements

- Docker
- Docker Compose

## Run the PoC

```bash
docker compose up -d --build
```

## Publish to Redis Stream

```bash
docker compose exec redis redis-cli XADD redis.events '*' message 'hello from redis stream'
```

## Verify message in NATS JetStream

The command below assumes the default Compose network name (`mag_default`).
If your network name differs, run `docker network ls` and replace it.

```bash
docker run --rm --network mag_default natsio/nats-box:0.15.0 \
  sh -lc "nats --server nats://nats:4222 stream info redis-events --json"
```

Check `state.messages` in the output and confirm it increases after publishing.

## Stop

```bash
docker compose down --remove-orphans
```
