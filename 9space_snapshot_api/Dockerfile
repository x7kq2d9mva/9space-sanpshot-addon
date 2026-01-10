ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apk add --no-cache ffmpeg python3 py3-fastapi py3-uvicorn

COPY app.py /app/app.py
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
