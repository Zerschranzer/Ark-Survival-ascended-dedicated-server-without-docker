#!/bin/bash

# Define the base paths as variables
BASE_DIR="/home/$(whoami)"

# Send a message that the server will restart in 10 minutes
"$BASE_DIR/start_stop.sh" 4 <<EOF
serverchat "Server restart in 10 minutes"
EOF

sleep 420

# Send a message that the server will restart in 3 minutes
"$BASE_DIR/start_stop.sh" 4 <<EOF
serverchat "Server restart in 3 minutes"
EOF

sleep 120

# Save the server
"$BASE_DIR/start_stop.sh" 4 <<EOF
saveworld
EOF

sleep 60

# Execute the start_stop.sh with option 3, restart
"$BASE_DIR/start_stop.sh" 3
