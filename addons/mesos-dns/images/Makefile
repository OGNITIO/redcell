.PHONY: build push

IMAGE = mesos-dns
TAG = latest

build:
	docker build -t hub.ognitio.net/containers/$(IMAGE):$(TAG) .

push:
	docker push hub.ognitio.net/containers/$(IMAGE):$(TAG)
