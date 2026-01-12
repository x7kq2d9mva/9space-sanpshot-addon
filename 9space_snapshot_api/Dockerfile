ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apk add --no-cache ffmpeg python3 py3-pip

RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir fastapi uvicorn

COPY main.py /app/main.py
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENV PATH="/opt/venv/bin:${PATH}"

CMD ["/run.sh"]
