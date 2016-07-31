#!/bin/bash

flexget='/home/harleypig/projects/flexget/bin/flexget'

$flexget daemon stop

while ( pgrep flexget > /dev/null 2>&1 ); do
  sleep 1
done

$flexget daemon start -d
