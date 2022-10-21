#!/bin/bash

# Get commandline arguments
while (( "$#" )); do
  case "$1" in
    --license-key)
      NEWRELIC_LICENSE_KEY="$2"
      shift
      ;;
    --logging-endpoint)
      LOGGING_ENDPOINT="$2"
      shift
      ;;
    --logging-level)
      FLUENTD_LOGGING_LEVEL="$2"
      shift
      ;;
    --help)
      echo "Values for flag --logging-endpoint: US:https://log-api.newrelic.com/log/v1 & EU:https://log-api.eu.newrelic.com/log/v1"
      echo "Values for flag --logging-level: fatal, error, warn, info, debug, trace."
      exit 2
      ;;
    *)
      shift
      ;;
  esac
done

# Set variables
newrelicLoggingAgentName="newrelic-logging-agent"
randomLoggerName="random-logger"

# Install docker on host machine
sudo bash ./01_docker/01_install_docker.sh

# Build New Relic logging image
sudo docker build \
  --build-arg licenseKey=$NEWRELIC_LICENSE_KEY \
  --build-arg baseUri=$LOGGING_ENDPOINT \
  --build-arg logLevel=$FLUENTD_LOGGING_LEVEL \
  --tag $newrelicLoggingAgentName \
  ./02_newrelic

# Start New Relic logging agent
sudo docker run \
  -d \
  --name $newrelicLoggingAgentName \
  -p 24224:24224 \
  $newrelicLoggingAgentName

# Build random logger image
sudo docker build \
  --tag $randomLoggerName \
  ./03_random_logger

# Start random logger
sudo docker run \
  -d \
  --name $randomLoggerName \
  --log-driver="fluentd" \
  --log-opt "fluentd-address=localhost:24224" \
  $randomLoggerName

