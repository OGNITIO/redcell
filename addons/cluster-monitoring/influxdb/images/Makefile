.PHONY: build push

IMAGE = influxdb
TAG = latest

build:
	docker build -t mesos-master-1.ognitio.net/containers/$(IMAGE):$(TAG) .

push:
	docker push mesos-master-1.ognitio.net/containers/$(IMAGE):$(TAG)
