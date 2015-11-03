.PHONY: build push

IMAGE = grafana
TAG = latest

build:
	docker build -t hub.ognitio.net/containers/$(IMAGE):$(TAG) .

push:
	docker push hub.ognitio.net/containers/$(IMAGE):$(TAG)
