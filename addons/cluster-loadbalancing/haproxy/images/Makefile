.PHONY: build push

IMAGE = haproxy
TAG = latest

build:
	docker build -t hub.ognitio.net/containers/$(IMAGE):$(TAG) .

push:
	docker push hub.ognitio.net/containers/$(IMAGE):$(TAG)
