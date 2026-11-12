# DeQua Tiles

## Start 

1. Update style url and copy them in the right folder
```bash
TILES_SERVER_URL=https://server.url.it utils/update_style_urls.sh
# For example in development
# TILES_SERVER_URL=http://localhost:3000 utils/update_style_urls.sh
```

2. Start docker
```bash
# For development
docker compose up -d
```
```bash
# For production
docker compose -f compose.yml -f compose.prod.yml up -d
```

## Create tiles

To create new tiles we use planetiler, with a non-interactive script (safe to run from cron).
It builds the tiles, swaps them atomically into `tileserver/mbtiles/dequa_tiles.mbtiles` and restarts Martin.

```bash
bash planetiler/download_tiles.sh
```

In production the `tiles_cron` service (supercronic, see `planetiler/crontab`) runs it every monday at 3:00.
It uses the host Docker socket, so run `docker compose` from the project dir. Logs: `docker logs dq_tiles_cron`.