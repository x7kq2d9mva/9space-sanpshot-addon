# 9space-sanpshot-addon

FastAPI service for Dahua NVR RTSP snapshots. The API returns stream health metadata and, when available, a JPEG snapshot in a single response.

## Features

- Single endpoint for health + snapshot.
- RTSP URL built from configuration options.
- In-memory snapshot cache to reduce load.
- Concurrency limiter with a short queue timeout.

## API

### `GET /api/camera/{camera_id}`

Returns a multipart response containing JSON metadata and a JPEG snapshot when successful. If the snapshot fails, the response is JSON only.

Example JSON payload:

```json
{
  "camera_id": "1",
  "ok": true,
  "latency_ms": 842,
  "detail": "decoded 1 frame"
}
```

When busy, the API responds with HTTP 503 and:

```json
{
  "camera_id": "1",
  "ok": false,
  "latency_ms": 0,
  "detail": "busy"
}
```

## Configuration

The addon reads options from `/data/options.json`. Typical values are defined in `config.yaml`:

- `nvr_host`: IP/hostname of the NVR.
- `rtsp_port`: RTSP port (default 554).
- `username`: RTSP username.
- `password`: RTSP password.
- `subtype`: stream subtype (0 = main, 1 = substream, etc.).
- `health_timeout_ms`: ffmpeg timeout in milliseconds.
- `jpeg_qv`: JPEG quality value (lower = higher quality).
- `max_concurrency`: maximum concurrent ffmpeg processes.

## Running locally

Build the container and run it on port 8000:

```sh
docker build -t 9space-snapshot-api .
docker run --rm -p 8000:8000 9space-snapshot-api
```

Then request a snapshot:

```sh
curl -v http://localhost:8000/api/camera/1
```
