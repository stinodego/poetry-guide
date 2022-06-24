set -e

docker build -t mypackage:minimal -f docker/Dockerfile.minimal .
docker run --rm mypackage:minimal
