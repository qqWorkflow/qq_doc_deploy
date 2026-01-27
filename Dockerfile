FROM python:3.12-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    findutils \
    inotify-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy build script
COPY scripts/watch-and-build.sh /scripts/watch-and-build.sh
RUN chmod +x /scripts/watch-and-build.sh

CMD ["/scripts/watch-and-build.sh"]
