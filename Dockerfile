FROM python:3.12-slim

# Install git for commit hash check
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy build script
COPY scripts/build-server.sh /scripts/build-server.sh
RUN chmod +x /scripts/build-server.sh

CMD ["/scripts/build-server.sh"]
