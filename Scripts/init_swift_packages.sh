#!/bin/bash
# Initialize Swift packages for each framework

for fw in Frameworks/*; do
  cd "$fw"
  if [ ! -f Package.swift ]; then
    swift package init --type library
  fi
  cd ../../
done
