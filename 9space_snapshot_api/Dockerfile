FROM ghcr.io/home-assistant/base:3.20

RUN apk add --no-cache ffmpeg python3 py3-pip

RUN pip3 install --no-cache-dir fastapi uvicorn

COPY app.py /app/app.py
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
