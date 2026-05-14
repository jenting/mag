# mag

A proof-of-concept pipeline that bridges **NATS JetStream** → **benthos** → **Redis Streams**.

## Architecture

```
Publisher ──► NATS JetStream (subject: test) ──► benthos ──► Redis Streams (key: test)
```

| Component | Image | Purpose |
|-----------|-------|---------|
| nats | `nats:2.10-alpine` | NATS server with JetStream enabled |
| nats-setup | `natsio/nats-box:latest` | One-shot container that creates the JetStream stream |
| redis | `redis:7-alpine` | Redis server (receives messages as a Stream) |
| benthos | `ghcr.io/benthosdev/benthos:4` | Reads from NATS JetStream, writes to Redis Streams |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) ≥ 20.10
- [Docker Compose](https://docs.docker.com/compose/install/) v2

## Run

```bash
docker compose up -d
```

All four services start. The `nats-setup` container creates the `test` JetStream stream and exits; `benthos` starts consuming messages and writing them to Redis.

## Publish a Test Message

Use the `nats-box` image to publish a message to the `test` subject:

```bash
docker run --rm --network mag_default natsio/nats-box:latest \
  nats pub test "hello from NATS" --server=nats://nats:4222
```

> **Note:** `mag_default` is the Docker Compose network name derived from the project directory name (`mag`) and the default network (`default`). If your working directory is named differently or you use a custom project name (`-p` flag), replace `mag_default` with the actual network name. Run `docker network ls` to find it.


## Validate

### Check the message arrived in Redis Streams

```bash
docker exec $(docker compose ps -q redis) \
  redis-cli XREAD COUNT 10 STREAMS test 0
```

Expected output example:
```
1) 1) "test"
   2) 1) 1) "1700000000000-0"
         2) 1) "body"
            2) "hello from NATS"
```

### Check NATS JetStream stream info

```bash
docker run --rm --network mag_default natsio/nats-box:latest \
  nats stream info test --server=nats://nats:4222
```

## Stop

```bash
docker compose down
```