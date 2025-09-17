# Base image
FROM python:3.12-slim

# Install X11 clipboard tools
RUN apt-get update && apt-get install -y \
    xclip xsel \
    && rm -rf /var/lib/apt/lists/*

# Set workdir
WORKDIR /app

# Copy clipboard sync script
COPY clip_sync.py /app/clip_sync.py

# Install Python dependencies
RUN pip install --no-cache-dir pyperclip

# Expose default port
EXPOSE 6060

# Default command: run server
CMD ["python", "clip_sync.py","server"]
