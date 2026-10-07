# Build from the repository root:
# docker build -f talkloom/talkloom_server/Dockerfile -t talkloom-server .

FROM dart:3.12.2 AS build

WORKDIR /app
COPY talkloom/pubspec.lock ./pubspec.lock
COPY talkloom/talkloom_server ./talkloom_server
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.12.2' \
  'workspace:' \
  '  - talkloom_server' \
  > pubspec.yaml
RUN dart pub get

# The YouTube caption adapter is Python-based; install its locked dependency
# into the same Debian family used by the runtime image.
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 python3-venv \
  && python3 -m venv /opt/talkloom-python \
  && /opt/talkloom-python/bin/pip install --no-cache-dir \
      -r /app/talkloom_server/scripts/requirements.txt \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app/talkloom_server
RUN dart build cli --target bin/main.dart --output build \
  && mv build/bundle/bin/main build/bundle/bin/server
RUN mkdir -p config web migrations

FROM dart:3.12.2
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 python3-venv ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV runmode=production \
    serverid=default \
    logging=normal \
    role=monolith \
    TALKLOOM_PYTHON_EXECUTABLE=/opt/talkloom-python/bin/python

COPY --from=build /app/talkloom_server/build/bundle/ ./
COPY --from=build /app/talkloom_server/config/ ./config/
COPY --from=build /app/talkloom_server/web/ ./web/
COPY --from=build /app/talkloom_server/migrations/ ./migrations/
COPY --from=build /app/talkloom_server/scripts/ ./scripts/
COPY --from=build /opt/talkloom-python/ /opt/talkloom-python/
COPY --from=build /app/talkloom_server/lib/src/generated/protocol.yaml \
  ./lib/src/generated/protocol.yaml

EXPOSE 8080 8081 8082
ENTRYPOINT ["/bin/sh", "-c", "exec ./bin/server --mode=\"$runmode\" --server-id=\"$serverid\" --logging=\"$logging\" --role=\"$role\""]
