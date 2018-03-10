#!/bin/bash

# Without exposing volumes
# docker run -dit -p 2222:2222 -p 2223:2223 cowrie

# Troubleshoot
# docker exec -it [container name] /bin/bash

# Expose volume and ports
docker run -d -p 2222:2222 -p 2223:2223 -v `pwd`/var:/cowrie/cowrie-git/var cowrie
