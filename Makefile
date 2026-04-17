.PHONY: cluster clean api-docker traffic-docker

cluster:
	./bootstrap.sh

clean:
	k3d cluster delete devops-cluster || true

api-docker:
	docker build -t devops-sample-api:latest ./src/api
	k3d image import devops-sample-api:latest -c devops-cluster

traffic-docker:
	docker build -t devops-traffic-gen:latest ./src/traffic-generator
	k3d image import devops-traffic-gen:latest -c devops-cluster
