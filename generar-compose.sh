#!/bin/bash
file_name=$1
nclients=$2
echo "Docker Compose file name: '${file_name}'"
echo "Number of clients: '${nclients}'"

python3 scale_clients.py ${file_name} ${nclients}
