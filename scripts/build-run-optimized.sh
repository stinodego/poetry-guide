set -e

docker build -t mypackage:optimized -f docker/Dockerfile.optimized .
docker run --rm mypackage:optimized
