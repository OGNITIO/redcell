.PHONY: build push

IMAGE = mesos-dns
TAG = latest

build:
	docker build -t mesos-master-1.ognitio.net/containers/$(IMAGE):$(TAG) .

push:
	docker push mesos-master-1.ognitio.net/containers/$(IMAGE):$(TAG)
