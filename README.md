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

To create new tiles we use planetiler, with a convenient script

```bash
sh utils/download_tiles.sh
```