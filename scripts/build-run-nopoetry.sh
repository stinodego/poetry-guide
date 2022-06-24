set -e

poetry export > requirements.txt

docker build -t mypackage:nopoetry -f docker/Dockerfile.nopoetry .
docker run --rm mypackage:nopoetry
