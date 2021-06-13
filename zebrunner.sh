#!/bin/bash

CONTAINER_NAME="sonarqube"

  echo_warning() {
    echo "
      WARNING! $1"
  }

  echo_telegram() {
    echo "
      For more help join telegram channel: https://t.me/zebrunner
      "
  }

  status() {
    source .env
    local container_status=$(docker inspect $CONTAINER_NAME -f {{.State.Health.Status}} 2> /dev/null)
    if [[ -z "$container_status" ]]; then
       echo_warning "There's no container $CONTAINER_NAME"
       exit -1
    fi

    echo "$CONTAINER_NAME is $container_status"

    case "$container_status" in
        "healthy")
            return 0
            ;;
        "unhealthy")
            return 1
            ;;
        "starting")
            return 2
            ;;
    esac
  }

  setup() {
    echo
  }

  shutdown() {
    if [[ -f .disabled ]]; then
      rm -f .disabled
      exit 0 #no need to proceed as nothing was configured
    fi

    docker-compose --env-file .env -f docker-compose.yml down -v
  }

  start() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    docker network inspect infra >/dev/null 2>&1 || docker network create infra
    docker-compose --env-file .env -f docker-compose.yml up -d
  }

  stop() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    docker-compose --env-file .env -f docker-compose.yml stop
  }

  down() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    docker-compose --env-file .env -f docker-compose.yml down
  }

  backup() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    status
    if [[ $? -ne -1 ]]; then
      echo "Backup $CONTAINER_NAME container"
      docker run --rm --volumes-from $CONTAINER_NAME -v "$(pwd)"/backup:/var/backup "ubuntu" tar -czvf /var/backup/sonarqube.tar.gz /opt/sonarqube
    else
      echo_warning "Impossible backup $CONTAINER_NAME container!"
      echo_telegram
    fi
  }

  restore() {
    if [[ -f .disabled ]]; then
      exit 0
    fi

    status
    if [[ $? -ne -1 ]]; then
      echo "Restore $CONTAINER_NAME container"
      stop
      docker run --rm --volumes-from $CONTAINER_NAME -v "$(pwd)"/backup:/var/backup "ubuntu" bash -c "cd / && tar -xzvf /var/backup/sonarqube.tar.gz"
      down
    else
      echo_warning "Impossible restore $CONTAINER_NAME container"
      echo_telegram
    fi
  }

  version() {
    if [[ -f .disabled ]]; then
      exit 0
    fi
    
    source .env
    echo "sonarqube: ${TAG_SONAR}"
  }

  echo_help() {
    echo "
      Usage: ./zebrunner.sh [option]
      Flags:
          --help | -h    Print help
      Arguments:
      	  start          Start container
      	  stop           Stop and keep container
          status         Show $CONTAINER_NAME container status
      	  restart        Restart container
      	  down           Stop and remove container
      	  shutdown       Stop and remove container, clear volumes
      	  backup         Backup container
      	  restore        Restore container
      	  version        Version of container"
      echo_telegram
      exit 0
  }

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd ${BASEDIR} || exit

case "$1" in
    setup)
        setup
        ;;
    start)
	start 
        ;;
    stop)
        stop
        ;;
    restart)
        down
        start
        ;;
    down)
        down
        ;;
    shutdown)
        shutdown
        ;;
    backup)
        backup
	;;
    restore)
        restore
        ;;
    status)
        status
        ;;
    version)
        version
        ;;
    --help | -h)
        echo_help
        ;;
    *)
        echo "Invalid option detected: $1"
        echo_help
        exit 1
        ;;
esac

