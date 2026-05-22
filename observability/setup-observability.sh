#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${HOME}/jobfair-observability"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
INSTALL_DIR="$BASE_DIR/install"
LOG_DIR="$BASE_DIR/logs"
RUN_DIR="$BASE_DIR/run"
GRAFANA_DATA_DIR="$BASE_DIR/grafana-data"
PROMETHEUS_DATA_DIR="$BASE_DIR/prometheus-data"
LOKI_DATA_DIR="$BASE_DIR/loki-data"
PROMTAIL_POSITIONS_DIR="$BASE_DIR/promtail-positions"

PROMETHEUS_VERSION="3.11.3"
GRAFANA_VERSION="13.0.1"
LOKI_VERSION="3.7.2"
PROMTAIL_VERSION="3.4.4"
NODE_EXPORTER_VERSION="1.11.1"

PROMETHEUS_URL="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
GRAFANA_URL="https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz"
LOKI_URL="https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip"
PROMTAIL_URL="https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

mkdir -p \
  "$BIN_DIR" \
  "$CONFIG_DIR" \
  "$INSTALL_DIR" \
  "$LOG_DIR" \
  "$RUN_DIR" \
  "$GRAFANA_DATA_DIR" \
  "$PROMETHEUS_DATA_DIR" \
  "$LOKI_DATA_DIR" \
  "$PROMTAIL_POSITIONS_DIR"

download_file() {
  local url="$1"
  local destination="$2"

  if [ -s "$destination" ]; then
    return 0
  fi

  echo "Downloading $(basename "$destination")"
  curl -fsSL -H 'User-Agent: Mozilla/5.0' -o "$destination" "$url"
}

extract_tarball() {
  local archive="$1"
  local destination="$2"

  rm -rf "$destination"
  mkdir -p "$destination"
  tar -xzf "$archive" -C "$destination" --strip-components=1
}

extract_zip() {
  local archive="$1"
  local destination="$2"

  rm -rf "$destination"
  mkdir -p "$destination"
  python3 - "$archive" "$destination" <<'PY'
import pathlib
import sys
import zipfile

archive = pathlib.Path(sys.argv[1])
destination = pathlib.Path(sys.argv[2])

with zipfile.ZipFile(archive) as bundle:
    bundle.extractall(destination)
PY
}

download_file "$PROMETHEUS_URL" "$INSTALL_DIR/prometheus.tar.gz"
download_file "$GRAFANA_URL" "$INSTALL_DIR/grafana.tar.gz"
download_file "$LOKI_URL" "$INSTALL_DIR/loki.zip"
download_file "$PROMTAIL_URL" "$INSTALL_DIR/promtail.zip"
download_file "$NODE_EXPORTER_URL" "$INSTALL_DIR/node_exporter.tar.gz"

extract_tarball "$INSTALL_DIR/prometheus.tar.gz" "$INSTALL_DIR/prometheus"
extract_tarball "$INSTALL_DIR/grafana.tar.gz" "$INSTALL_DIR/grafana"
extract_tarball "$INSTALL_DIR/node_exporter.tar.gz" "$INSTALL_DIR/node_exporter"
extract_zip "$INSTALL_DIR/loki.zip" "$INSTALL_DIR/loki"
extract_zip "$INSTALL_DIR/promtail.zip" "$INSTALL_DIR/promtail"

cp "$INSTALL_DIR/prometheus/prometheus" "$BIN_DIR/prometheus"
cp "$INSTALL_DIR/prometheus/promtool" "$BIN_DIR/promtool"
cp "$INSTALL_DIR/grafana/bin/grafana" "$BIN_DIR/grafana"
cp "$INSTALL_DIR/node_exporter/node_exporter" "$BIN_DIR/node_exporter"
cp "$INSTALL_DIR/loki/loki-linux-amd64" "$BIN_DIR/loki"
cp "$INSTALL_DIR/promtail/promtail-linux-amd64" "$BIN_DIR/promtail"
chmod +x "$BIN_DIR"/*

if [ ! -f "$CONFIG_DIR/grafana-admin-password.txt" ]; then
  tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24 > "$CONFIG_DIR/grafana-admin-password.txt"
  printf '\n' >> "$CONFIG_DIR/grafana-admin-password.txt"
fi

cat > "$CONFIG_DIR/prometheus.yml" <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['127.0.0.1:9090']

  - job_name: node_exporter
    static_configs:
      - targets: ['127.0.0.1:9100']

  - job_name: loki
    metrics_path: /metrics
    static_configs:
      - targets: ['127.0.0.1:3100']
EOF

cat > "$CONFIG_DIR/loki.yml" <<EOF
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9095

common:
  path_prefix: ${LOKI_DATA_DIR}
  storage:
    filesystem:
      chunks_directory: ${LOKI_DATA_DIR}/chunks
      rules_directory: ${LOKI_DATA_DIR}/rules
  replication_factor: 1
  instance_addr: 127.0.0.1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2026-05-22
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: loki_index_
        period: 24h
EOF

cat > "$CONFIG_DIR/promtail.yml" <<EOF
server:
  http_listen_port: 9081
  grpc_listen_port: 0

positions:
  filename: ${PROMTAIL_POSITIONS_DIR}/positions.yaml

clients:
  - url: http://127.0.0.1:3100/loki/api/v1/push

scrape_configs:
  - job_name: nginx
    static_configs:
      - targets: [localhost]
        labels:
          job: nginx
          host: $(hostname -s)
          __path__: /var/log/nginx/*.log

  - job_name: journal
    journal:
      max_age: 12h
      labels:
        job: journal
        host: $(hostname -s)
    relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: systemd_unit
      - source_labels: ['__journal__priority']
        target_label: priority
EOF

mkdir -p "$BASE_DIR/grafana-provisioning/datasources"
cat > "$BASE_DIR/grafana-provisioning/datasources/datasources.yml" <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://127.0.0.1:9090
    isDefault: true
    editable: true

  - name: Loki
    type: loki
    access: proxy
    url: http://127.0.0.1:3100
    editable: true
EOF

cat > "$BIN_DIR/start-observability.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$BASE_DIR"
BIN_DIR="$BIN_DIR"
CONFIG_DIR="$CONFIG_DIR"
LOG_DIR="$LOG_DIR"
RUN_DIR="$RUN_DIR"
GRAFANA_DATA_DIR="$GRAFANA_DATA_DIR"
PROMETHEUS_DATA_DIR="$PROMETHEUS_DATA_DIR"
LOKI_DATA_DIR="$LOKI_DATA_DIR"

mkdir -p "\$LOG_DIR" "\$RUN_DIR" "\$GRAFANA_DATA_DIR" "\$PROMETHEUS_DATA_DIR" "\$LOKI_DATA_DIR"

start_service() {
  local name="\$1"
  shift
  local pid_file="\$RUN_DIR/\$name.pid"
  local log_file="\$LOG_DIR/\$name.log"

  if [ -f "\$pid_file" ] && kill -0 "\$(cat "\$pid_file")" 2>/dev/null; then
    return 0
  fi

  nohup "\$@" >> "\$log_file" 2>&1 &
  echo \$! > "\$pid_file"
}

start_service prometheus "\$BIN_DIR/prometheus" \
  --config.file="\$CONFIG_DIR/prometheus.yml" \
  --storage.tsdb.path="\$PROMETHEUS_DATA_DIR" \
  --web.listen-address=0.0.0.0:9090

start_service node_exporter "\$BIN_DIR/node_exporter" \
  --web.listen-address=0.0.0.0:9100

start_service loki "\$BIN_DIR/loki" \
  --config.file="\$CONFIG_DIR/loki.yml"

start_service promtail "\$BIN_DIR/promtail" \
  --config.file="\$CONFIG_DIR/promtail.yml"

export GF_SECURITY_ADMIN_USER=admin
export GF_SECURITY_ADMIN_PASSWORD="$(cat "$CONFIG_DIR/grafana-admin-password.txt")"
export GF_PATHS_DATA="\$GRAFANA_DATA_DIR"
export GF_PATHS_PROVISIONING="\$BASE_DIR/grafana-provisioning"

start_service grafana "\$BIN_DIR/grafana" \
  server \
  --homepath="$INSTALL_DIR/grafana" \
  --config="$INSTALL_DIR/grafana/conf/defaults.ini" \
  --packaging=tarball
EOF

chmod +x "$BIN_DIR/start-observability.sh"

if command -v crontab >/dev/null 2>&1; then
  tmp_cron="$INSTALL_DIR/crontab.txt"
  crontab -l 2>/dev/null | grep -v 'jobfair-observability/bin/start-observability.sh' > "$tmp_cron" || true
  printf '@reboot sleep 30 && %s/bin/start-observability.sh\n' "$BASE_DIR" >> "$tmp_cron"
  crontab "$tmp_cron"
  rm -f "$tmp_cron"
fi

"$BIN_DIR/start-observability.sh"

HOST_IP="$(hostname -I | awk '{print $1}')"
echo "Observability stack started at $HOST_IP"
echo "Grafana:        http://$HOST_IP:3000"
echo "Prometheus:     http://$HOST_IP:9090"
echo "Loki:           http://$HOST_IP:3100"
echo "Node Exporter:  http://$HOST_IP:9100/metrics"
echo "Grafana admin password file: $CONFIG_DIR/grafana-admin-password.txt"
