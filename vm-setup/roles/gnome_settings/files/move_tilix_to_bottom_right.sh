#!/bin/bash

# Move the Tilix window to the bottom right corner of the screen.
# Replace the 0,1000,500 with the actual screen coordinates for the bottom right corner.

TILIX_WINDOW=$(wmctrl -l | grep Tilix | awk '{print $1}')

if [ -n "$TILIX_WINDOW" ]; then
    wmctrl -i -r "$TILIX_WINDOW" -e 0,1000,500,-1,-1
fi
