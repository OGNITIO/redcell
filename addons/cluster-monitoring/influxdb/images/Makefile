.PHONY: build push

IMAGE = influxdb
TAG = latest

build:
	docker build -t hub.ognitio.net:5000/containers/$(IMAGE):$(TAG) .

push:
	docker push hub.ognitio.net:5000/containers/$(IMAGE):$(TAG)
