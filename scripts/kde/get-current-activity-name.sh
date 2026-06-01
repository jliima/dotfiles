#!/usr/bin/env bash

echo "$(plasma-activities-cli6 --current-activity | awk '{print $2}')"
