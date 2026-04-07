# ZvgPortal Scraper

This is Python-based code able to scrape data from https://www.zvg-portal.de/.

## Installation

Even though dependencies of this application are minimal, it is recommended to run it in a virtual environment:

```bash
$ cd /path/to/ZvgPortal/
$ git clone 'https://github.com/larsborn/ZvgPortalScraper.git' .
$ python3 -m venv .venv
$ source .venv/bin/activate
$ pip install -U pip
$ pip install -r requirements.txt
```

## Usage

Set the `PYTHONPATH` environment variable and then you can execute `app.py`:

```bash
$ export PYTHONPATH=/path/to/ZvgPortal/  # the directory _containing_ the "zvg_portal" directory

$ python zvg_portal/app.py --help
usage: app.py [-h] [--debug] 
              [--print-stats] [--print-entries]
              [--base-url BASE_URL] [--raw-data-directory RAW_DATA_DIRECTORY] [--user-agent USER_AGENT]
              [--nsqd-address NSQD_ADDRESS] [--nsqd-port NSQD_PORT]
              [--client-side-crt CLIENT_SIDE_CRT] [--client-side-key CLIENT_SIDE_KEY]

optional arguments:
  -h, --help            show this help message and exit
  --debug
  --print-stats
  --print-entries
  --base-url BASE_URL
  --nsqd-address NSQD_ADDRESS
  --nsqd-port NSQD_PORT
  --client-side-crt CLIENT_SIDE_CRT
  --client-side-key CLIENT_SIDE_KEY
  --raw-data-directory RAW_DATA_DIRECTORY
  --user-agent USER_AGENT

```

For example like so:

```bash
$ python zvg_portal/app.py --nsqd-address nsqd.example.com --nsqd-port 4151
```

## Running with Docker

A `Dockerfile` is provided to build a self-contained image of the scraper. The image is based on `python:3.13-slim-bookworm`, generates the `de_DE` / `de_DE.UTF-8` locales required by the application, and runs as an unprivileged `scraper` user (UID 1000).

Build the image:

```bash
$ docker build -t zvg-portal-scraper .
```

Run the scraper as a one-shot job. All CLI flags are forwarded to `app.py`:

```bash
$ docker run --rm \
    -v zvg-raw:/data/raw \
    zvg-portal-scraper \
    --nsqd-address nsqd.example.com --nsqd-port 4151
```

The image declares `VOLUME /data/raw` and sets `RAW_DATA_DIRECTORY=/data/raw`, so raw scraped files are written to a mounted volume (named volume `zvg-raw` in the example above — use a bind mount like `-v /host/path:/data/raw` to persist to a host directory instead).

All arguments accepted by `app.py` also have environment variable equivalents (`BASE_URL`, `NSQD_ADDRESS`, `NSQD_PORT`, `CLIENT_SIDE_CRT`, `CLIENT_SIDE_KEY`, `RAW_DATA_DIRECTORY`), which can be passed with `-e`:

```bash
$ docker run --rm \
    -v zvg-raw:/data/raw \
    -e NSQD_ADDRESS=nsqd.example.com \
    -e NSQD_PORT=4151 \
    zvg-portal-scraper
```

### Docker Compose / Portainer stack

The following `docker-compose.yml` can be pasted directly into a Portainer stack (or used with `docker compose`). It assumes the image has been built and tagged locally as `zvg-portal-scraper:latest`, or is available from a registry — replace `image:` accordingly:

```yaml
services:
  zvg-scraper:
    image: zvg-portal-scraper:latest
    container_name: zvg-scraper
    environment:
      NSQD_ADDRESS: nsqd.example.com
      NSQD_PORT: "4151"
      # BASE_URL: https://www.zvg-portal.de
      # CLIENT_SIDE_CRT: /certs/client.crt
      # CLIENT_SIDE_KEY: /certs/client.key
    volumes:
      - zvg-raw:/data/raw
      # - /host/path/to/certs:/certs:ro
    restart: "no"

volumes:
  zvg-raw:
```

A few things to keep in mind:

- The scraper is a **one-shot job** — the container runs once and then exits. `restart: "no"` reflects that; Compose/Portainer will mark the stack as "exited" after a successful run, which is expected.
- To run it on a schedule, trigger the stack externally: a host cron job invoking `docker compose run --rm zvg-scraper`, a Kubernetes `CronJob`, or a companion scheduler like [ofelia](https://github.com/mcuadros/ofelia) deployed alongside the stack.
- If you are building the image from a cloned repo directly in Portainer, replace `image:` with `build: .` and point the stack at the repository.
- Client-side certificate paths (`CLIENT_SIDE_CRT` / `CLIENT_SIDE_KEY`) must resolve *inside* the container — mount them as a read-only volume as shown in the commented lines.

## Development

Install the development dependencies (includes runtime deps plus `black`, `isort` and `pre-commit`):

```bash
$ pip install -r requirements-dev.txt
```

Then install the git hook so formatters run automatically on every commit:

```bash
$ pre-commit install
```

Code style is enforced by [black](https://github.com/psf/black) and [isort](https://github.com/pycqa/isort) (config in `pyproject.toml`, line length 120). To format the entire codebase manually:

```bash
$ pre-commit run --all-files
```
