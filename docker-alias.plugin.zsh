#!/usr/bin/env zsh

if [ -x "$(command which docker)" ]; then
  function docker-image-dependencies() {
    # about 'attempt to create a Graphiz image of the supplied image ID dependencies'
    # group 'docker'
    if hash dot 2>/dev/null; then
      OUT=$(mktemp -t docker-viz-XXXX.png)
      docker images -viz | dot -Tpng >$OUT
      case $OSTYPE in
      linux*)
        xdg-open $OUT
        ;;
      darwin*)
        open $OUT
        ;;
      esac
    else
      echo >&2 "Can't show dependencies; Graphiz is not installed"
    fi
  }
  function docker-runtime-environment() {
    # about 'attempt to list the environmental variables of the supplied image ID'
    # group 'docker'
    docker run "$@" env
  }
  function docker-remove-stale-assets() {
    # about 'attempt to remove exited containers and dangling images'
    # group 'docker'
    docker ps --filter status=exited -q | xargs docker rm --volumes
    docker images --filter dangling=true -q | xargs docker rmi
  }
  function docker-remove-images() {
    # about 'attempt to remove images with supplied tags or all if no tags are supplied'
    # group 'docker'
    if [ -z "$1" ]; then
      docker rmi $(docker images -q)
    else
      DOCKER_IMAGES=""
      for IMAGE_ID in $@; do DOCKER_IMAGES="$DOCKER_IMAGES\|$IMAGE_ID"; done
      # Find the image IDs for the supplied tags
      ID_ARRAY=($(docker images | grep "${DOCKER_IMAGES:2}" | awk {'print $3'}))
      # Strip out duplicate IDs before attempting to remove the image(s)
      docker rmi $(echo ${ID_ARRAY[@]} | tr ' ' '\n' | sort -u | tr '\n' ' ')
    fi
  }
  function docker-remove-most-recent-container() {
    # about 'attempt to remove the most recent container from docker ps -a'
    # group 'docker'
    docker ps -ql | xargs docker rm
  }
  function docker-remove-most-recent-image() {
    # about 'attempt to remove the most recent image from docker images'
    # group 'docker'
    docker images -q | head -1 | xargs docker rmi
  }
  alias dk='docker'
  # List last Docker container
  alias dklc='docker ps -l'
  # List last Docker container ID
  alias dklcid='docker ps -l -q'
  # Get IP of last Docker container
  alias dklcip='docker inspect -f "{{.NetworkSettings.IPAddress}}" $(docker ps -l -q)'
  # List running Docker containers
  alias dkps='docker ps'
  # List all Docker containers
  alias dkpsa='docker ps -a'
  # List Docker images
  alias dki='docker images'
  # Delete all Docker containers
  alias dkrmac='docker rm $(docker ps -a -q)'

  case $OSTYPE in
  darwin* | *bsd* | *BSD*)
    # Delete all untagged Docker images
    alias dkrmui='docker images -q -f dangling=true | xargs docker rmi'
    ;;
  *)
    # Delete all untagged Docker images
    alias dkrmui='docker images -q -f dangling=true | xargs -r docker rmi'
    ;;
  esac

  # Function aliases from docker plugin:
  # Output a graph of image dependencies using Graphiz
  alias dkideps='docker-image-dependencies'
  # List environmental variables of the supplied image ID
  alias dkre='docker-runtime-environment'
  # Delete all untagged images and exited containers
  alias dkrmall='docker-remove-stale-assets'
  # Delete images for supplied IDs or all if no IDs are passed as arguments
  alias dkrmi='docker-remove-images'
  # Delete most recent (i.e., last) Docker container
  alias dkrmlc='docker-remove-most-recent-container'
  # Delete most recent (i.e., last) Docker image
  alias dkrmli='docker-remove-most-recent-image'
  alias dkbash='dkelc'
  # Enter last container (works with Docker 1.3 and above)
  alias dkelc='docker exec -it $(dklcid) bash --login'
  # Useful to run any
  alias dkex='docker exec -it '
  alias dkri='docker run --rm -i '
  alias dkrit='docker run --rm -it '
  alias dkrmflast='docker rm -f $(dklcid)'

  # Added more recent cleanup options from newer docker versions
  alias dkip='docker image prune -a -f'
  alias dksp='docker system prune -a -f'
  alias dkvp='docker volume prune -f'
fi

if [ -x "$(command which docker-compose)" ]; then
  function docker-compose-fresh() {
    # about 'shut down, remove and start again the docker-compose setup, then tail the logs'
    # group 'docker-compose'
    # param '1: name of the docker-compose.yaml file to use (optional). Default: docker-compose.yaml'
    # example 'docker-compose-fresh docker-compose-foo.yaml'
    local DCO_FILE_PARAM=""
    if [ -n "$1" ]; then
      echo "Using docker-compose file: $1"
      DCO_FILE_PARAM="--file $1"
    fi
    docker-compose $DCO_FILE_PARAM stop
    docker-compose $DCO_FILE_PARAM rm -f
    docker-compose $DCO_FILE_PARAM up -d
    docker-compose $DCO_FILE_PARAM logs -f --tail 100
  }
  alias dco="docker-compose"
  alias dcofresh="docker-compose-fresh"
  alias dcol="docker-compose logs -f --tail 100"
  alias dcou="docker-compose up"
fi
