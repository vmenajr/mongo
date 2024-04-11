#!/usr/bin/env bash
podman run --name pylucene --rm --interactive --tty --volume $(pwd):/usr/src docker.io/coady/pylucene bash

