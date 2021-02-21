#!/bin/bash

if uname -a | grep Ubuntu; then
    sudo apt-get update
    sudo apt-get install --no-install-recommends --assume-yes python-apt
else
    echo not found
fi

