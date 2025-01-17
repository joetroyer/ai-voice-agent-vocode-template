FROM python:3.9-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libportaudio2 libportaudiocpp0 portaudio19-dev \
    libasound-dev libsndfile1-dev ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /code

# Copy the pyproject.toml file
COPY ./pyproject.toml /code/pyproject.toml

# Install Poetry
RUN pip install --no-cache-dir "poetry==1.5.1"

# Generate poetry.lock
RUN poetry lock

# Commit poetry.lock back to GitHub
RUN git config --global user.email "joetroyer@gmail.com" \
    && git config --global user.name "joetroyer" \
    && git clone https://github.com/joetroyer/ai-voice-agent-vocode-template repo \
    && mv poetry.lock repo/poetry.lock \
    && cd repo \
    && git add poetry.lock \
    && git commit -m "Regenerate poetry.lock from Docker build" \
    && git push origin main

# Install dependencies
RUN poetry config virtualenvs.create false
RUN poetry install --no-dev --no-interaction --no-ansi -vvv

# Copy application files
COPY main.py /code/main.py
COPY speller_agent.py /code/speller_agent.py
COPY memory_config.py /code/memory_config.py
COPY events_manager.py /code/events_manager.py
COPY config.py /code/config.py
COPY instructions.txt /code/instructions.txt
COPY ./utils /code/utils

# Create necessary directories
RUN mkdir -p /code/call_transcripts /code/db

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000"]
