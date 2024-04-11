#!/usr/bin/env bash
podman run --name pylucene --rm --interactive --tty --volume $(pwd):/usr/src --volumes-from=mongot-test:ro docker.io/coady/pylucene bash
