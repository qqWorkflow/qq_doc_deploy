FROM python:3.12-slim

# Install inotify-tools for watching file changes
RUN apt-get update && apt-get install -y inotify-tools && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy build script
COPY scripts/build-server.sh /scripts/build-server.sh
RUN chmod +x /scripts/build-server.sh

CMD ["/scripts/build-server.sh"]
