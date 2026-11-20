# Native RPi profile for the packaged systemd journal to OTLP pipeline.
set(FLB_NATIVE_PROFILE_VERSION "systemd-otlp-v3" CACHE STRING "Native Fluent Bit profile" FORCE)

set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "Install prefix" FORCE)
set(CMAKE_INSTALL_BINDIR "/bin" CACHE PATH "Install binary directory" FORCE)

# FLB_MINIMAL defaults every plugin option to Off. Keep the known default-on
# options explicit so a cached or updated source configuration cannot broaden
# the native binary.
set(FLB_MINIMAL On CACHE BOOL "Enable minimal plugin defaults" FORCE)
set(FLB_ALL Off CACHE BOOL "Disable all optional features" FORCE)

set(fluent_bit_native_disabled_default_inputs
  FLB_IN_BLOB
  FLB_IN_CALYPTIA_FLEET
  FLB_IN_COLLECTD
  FLB_IN_CPU
  FLB_IN_DISK
  FLB_IN_DOCKER
  FLB_IN_DOCKER_EVENTS
  FLB_IN_DUMMY
  FLB_IN_ELASTICSEARCH
  FLB_IN_EMITTER
  FLB_IN_EVENT_TYPE
  FLB_IN_EXEC
  FLB_IN_EXEC_WASI
  FLB_IN_FLUENTBIT_METRICS
  FLB_IN_FLUENTBIT_LOGS
  FLB_IN_FORWARD
  FLB_IN_GPU_METRICS
  FLB_IN_HEAD
  FLB_IN_HEALTH
  FLB_IN_HTTP
  FLB_IN_KAFKA
  FLB_IN_KMSG
  FLB_IN_KUBERNETES_EVENTS
  FLB_IN_LIB
  FLB_IN_MEM
  FLB_IN_MQTT
  FLB_IN_NETIF
  FLB_IN_NGINX_EXPORTER_METRICS
  FLB_IN_NODE_EXPORTER_METRICS
  FLB_IN_OPENTELEMETRY
  FLB_IN_PODMAN_METRICS
  FLB_IN_PROCESS_EXPORTER_METRICS
  FLB_IN_PROC
  FLB_IN_PROMETHEUS_REMOTE_WRITE
  FLB_IN_PROMETHEUS_SCRAPE
  FLB_IN_PROMETHEUS_TEXTFILE
  FLB_IN_RANDOM
  FLB_IN_SERIAL
  FLB_IN_SPLUNK
  FLB_IN_STATSD
  FLB_IN_STDIN
  FLB_IN_STORAGE_BACKLOG
  FLB_IN_SYSLOG
  FLB_IN_TAIL
  FLB_IN_TCP
  FLB_IN_THERMAL
  FLB_IN_UDP
  FLB_IN_WINDOWS_EXPORTER_METRICS
)

set(fluent_bit_native_disabled_default_processors
  FLB_PROCESSOR_CUMULATIVE_TO_DELTA
  FLB_PROCESSOR_LABELS
  FLB_PROCESSOR_METRICS_SELECTOR
  FLB_PROCESSOR_SAMPLING
  FLB_PROCESSOR_SQL
  FLB_PROCESSOR_TDA
)

set(fluent_bit_native_disabled_default_filters
  FLB_FILTER_ALTER_SIZE
  FLB_FILTER_AWS
  FLB_FILTER_CHECKLIST
  FLB_FILTER_ECS
  FLB_FILTER_EXPECT
  FLB_FILTER_GEOIP2
  FLB_FILTER_GREP
  FLB_FILTER_KUBERNETES
  FLB_FILTER_LOG_TO_METRICS
  FLB_FILTER_LUA
  FLB_FILTER_MULTILINE
  FLB_FILTER_NIGHTFALL
  FLB_FILTER_PARSER
  FLB_FILTER_RECORD_MODIFIER
  FLB_FILTER_REWRITE_TAG
  FLB_FILTER_STDOUT
  FLB_FILTER_SYSINFO
  FLB_FILTER_THROTTLE
  FLB_FILTER_TYPE_CONVERTER
  FLB_FILTER_WASM
)

set(fluent_bit_native_disabled_default_outputs
  FLB_OUT_AZURE
  FLB_OUT_AZURE_BLOB
  FLB_OUT_AZURE_KUSTO
  FLB_OUT_AZURE_LOGS_INGESTION
  FLB_OUT_BIGQUERY
  FLB_OUT_CALYPTIA
  FLB_OUT_CHRONICLE
  FLB_OUT_CLOUDWATCH_LOGS
  FLB_OUT_COUNTER
  FLB_OUT_DATADOG
  FLB_OUT_ES
  FLB_OUT_EXIT
  FLB_OUT_FILE
  FLB_OUT_FLOWCOUNTER
  FLB_OUT_FORWARD
  FLB_OUT_GELF
  FLB_OUT_HTTP
  FLB_OUT_INFLUXDB
  FLB_OUT_KAFKA
  FLB_OUT_KAFKA_REST
  FLB_OUT_KINESIS_FIREHOSE
  FLB_OUT_KINESIS_STREAMS
  FLB_OUT_LIB
  FLB_OUT_LOGDNA
  FLB_OUT_LOKI
  FLB_OUT_NATS
  FLB_OUT_NRLOGS
  FLB_OUT_NULL
  FLB_OUT_OPENSEARCH
  FLB_OUT_ORACLE_LOG_ANALYTICS
  FLB_OUT_PLOT
  FLB_OUT_PROMETHEUS_EXPORTER
  FLB_OUT_PROMETHEUS_REMOTE_WRITE
  FLB_OUT_S3
  FLB_OUT_SKYWALKING
  FLB_OUT_SLACK
  FLB_OUT_SPLUNK
  FLB_OUT_STACKDRIVER
  FLB_OUT_STDOUT
  FLB_OUT_SYSLOG
  FLB_OUT_TCP
  FLB_OUT_TD
  FLB_OUT_UDP
  FLB_OUT_VIVO_EXPORTER
  FLB_OUT_WEBSOCKET
)

set(fluent_bit_native_disabled_default_features
  FLB_DEBUG
  FLB_UTF8_ENCODER
  FLB_UNICODE_ENCODER
  FLB_EXAMPLES
  FLB_SHARED_LIB
  FLB_CHUNK_TRACE
  FLB_INOTIFY
  FLB_BACKTRACE
  FLB_LUAJIT
  FLB_SIGNV4
  FLB_AWS
  FLB_STREAM_PROCESSOR
  FLB_WINDOWS_DEFAULTS
  FLB_WASM
  FLB_KAFKA
  FLB_ZIG
  FLB_RIPSER
  FLB_PROFILES
  FLB_PROXY_GO
  FLB_CUSTOM_CALYPTIA
)

foreach(disabled_option IN LISTS
    fluent_bit_native_disabled_default_inputs
    fluent_bit_native_disabled_default_processors
    fluent_bit_native_disabled_default_filters
    fluent_bit_native_disabled_default_outputs
    fluent_bit_native_disabled_default_features)
  set(${disabled_option} Off CACHE BOOL "Disabled by the native minimal profile" FORCE)
endforeach()

# Required by the packaged YAML and the OTLP output.
set(FLB_RELEASE On CACHE BOOL "Build an optimized production binary" FORCE)
set(FLB_SIMD Off CACHE STRING "Disable unsupported optional SIMD paths" FORCE)
set(FLB_BINARY On CACHE BOOL "Build the Fluent Bit executable" FORCE)
set(FLB_CONFIG_YAML On CACHE BOOL "Support the packaged YAML configuration" FORCE)
set(FLB_YYJSON On CACHE BOOL "Keep JSON record serialization support" FORCE)
set(FLB_REGEX On CACHE BOOL "Required for filter_nest registration upstream" FORCE)
set(FLB_TLS On CACHE BOOL "Required by OTLP over HTTPS and OAuth2" FORCE)
# This pinned source generates Monkey headers needed by Fluent Bit core only
# through its full HTTP-server CMake path; it also forces FLB_METRICS on.
set(FLB_HTTP_SERVER On CACHE BOOL "Required for pinned Monkey header generation" FORCE)
set(FLB_METRICS On CACHE BOOL "Required by the pinned HTTP server build path" FORCE)
# The pinned blob database fallback references SQLDB result codes even when no
# configured pipeline uses a database backend.
set(FLB_SQLDB On CACHE BOOL "Required by pinned blob database fallback" FORCE)
# The pinned executable resolves parser and record-accessor symbols even with
# every parser- and accessor-dependent plugin disabled.
set(FLB_PARSER On CACHE BOOL "Required by pinned executable parser references" FORCE)
set(FLB_RECORD_ACCESSOR On CACHE BOOL "Required by pinned executable accessor references" FORCE)
set(FLB_IN_SYSTEMD On CACHE BOOL "Read the systemd journal" FORCE)
set(FLB_FILTER_NEST On CACHE BOOL "Apply the packaged Journal nesting filter" FORCE)
# OTLP output to Azure Monitor (Microsoft-OTLP-Logs stream) with journal severity mapping.
set(FLB_OUT_OPENTELEMETRY On CACHE BOOL "Send records over OTLP/HTTP" FORCE)
set(FLB_FILTER_MODIFY On CACHE BOOL "Map journal PRIORITY to OTel severity" FORCE)
set(FLB_PROCESSOR_CONTENT_MODIFIER On CACHE BOOL "Set OTel resource attributes and convert severity" FORCE)
set(FLB_PROCESSOR_OPENTELEMETRY_ENVELOPE On CACHE BOOL "Wrap journal records in the OTel logs envelope" FORCE)
