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

In production the `planetiler` service (supercronic, see `planetiler/crontab`) runs it every monday at 3:00.
It uses the host Docker socket, so run `docker compose` from the project dir. Logs: `docker logs dq_planetiler`.
## Rive (Venice quays)

`RIve/` contains the Comune di Venezia PDFs (Allegati A1-A4) with the rive drawn as red polygons
labelled `isola-approdo`. `RIve/rive.py` extracts them, georeferences them and builds `dequa_rive.mbtiles`
(layer `rive`: `id`, `isola`, `approdo`, `sestiere`, `lunghezza_m`, `larghezza_m`, `area_m2`).

```bash
cd RIve
pip install -r requirements.txt
python rive.py images   # PDF -> <sheet>.png + <sheet>.extract.json
```

Georeference each `<sheet>.png` in QGIS (Raster → Georeferencer): add ~8 GCPs spread over the whole sheet
(corners included) on sharp features (building corners, bridges), in any CRS, then
"Save GCP Points as…" next to the PNG (`<sheet>.png.points`, the default name). No need to run the georeferencing.

```bash
python rive.py build    # *.png.points -> rive.geojson + tileserver/mbtiles/dequa_rive.mbtiles
docker restart dq_tiles_martin
```

The build prints the GCP residuals in metres per sheet: if one is much larger than the others, that point is wrong.
Lengths are the long side of the minimum rotated rectangle around each polygon.
