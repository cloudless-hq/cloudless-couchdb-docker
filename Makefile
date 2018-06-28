.PHONY : clean setup run-tests

creds := jan:password
couchdb := http://$(creds)@127.0.0.1:5984
db := test-database
dir := $(shell pwd)/test
curl_post := @curl -s -X POST -H "Content-Type: application/json" -u $(creds)
curl_put := @curl -s -X PUT -H "Content-Type: application/json" -u $(creds)
hadolint := docker run --rm -i hadolint/hadolint hadolint
release := couchdb-test-cluster
public_service := couchdb-loadbalancer

helm-deploy:
	@echo "Building images"
	eval $(minikube docker-env)
	$(MAKE) docker-build image_name=clouseau-test docker_file=./clouseau/Dockerfile
	$(MAKE) docker-build image_name=couchdb-test docker_file=./couchdb/Dockerfile
	@echo "Deploying to Minikube"
	helm install --name $(release) ./.helm/cloudless-couchdb
	@echo ""
	@echo ""
	@echo ""
	@echo "Finish cluster setup by running:"
	@echo "make cluster"
	@echo "make cluster-clouseau"

cluster-clouseau:
	@echo "Registering Clouseau nodes on each CouchDB node"
	kubectl exec -it $(release)-couchdb-0 -c couchdb -- \
		curl -X PUT $(couchdb)/_node/_local/_config/dreyfus/name \
		-d '"clouseau@clouseau-statefulset-0.clouseau-headless-service.default.svc.cluster.local"' ;
	kubectl exec -it $(release)-couchdb-1 -c couchdb -- \
		curl -X PUT $(couchdb)/_node/_local/_config/dreyfus/name \
		-d '"clouseau@clouseau-statefulset-1.clouseau-headless-service.default.svc.cluster.local"';
	kubectl exec -it $(release)-couchdb-2 -c couchdb -- \
		curl -X PUT $(couchdb)/_node/_local/_config/dreyfus/name \
		-d '"clouseau@clouseau-statefulset-2.clouseau-headless-service.default.svc.cluster.local"';

cluster:
	kubectl exec -it $(release)-couchdb-0 -c couchdb -- \
		curl -s \
		$(couchdb)/_cluster_setup \
		-X POST \
		-H "Content-Type: application/json" \
		-d '{"action": "finish_cluster"}' \
		-u "$(creds)" ;
	@echo "Exposing the cluster on a public service"
	kubectl expose service $(release)-svc-couchdb --type=LoadBalancer --name=$(public_service)
	minikube service $(public_service) --url

# in the end this will do the following:
# 1. confirm configuration we set (so it's applied)
# 2. confirm membership (count all_nodes vs. cluster_nodes in /_membership)
cluster-status:
	for number in 0 1 2 ; do \
		kubectl exec -it $(release)-couchdb-$$number -c couchdb -- \
			curl -s $(couchdb)/_node/_local/_config/httpd/bind_address \
			&& curl -s $(couchdb)/_node/_local/_config/chttpd/bind_address ; \
	done

helm-lint:
	helm lint ./.helm/cloudless-couchdb

helm-undeploy:
	@echo "Removing release"
	helm delete --purge $(release)
	kubectl delete service/$(public_service)

helm-upgrade:
	helm upgrade $(release) ./.helm/cloudless-couchdb

clean:
	$(eval endpoint := $(shell minikube service $(public_service) --url))
	@echo "Deleting $(db)"
	curl -X DELETE -u $(creds) $(endpoint)/$(db)

setup:
	$(eval endpoint := $(shell minikube service $(public_service) --url))
	@echo "Creating database(s) on all nodes of cluster $(endpoint)"
	$(curl_put) $(endpoint)/$(db)
	@echo "Populating '$(db)' with test data/fixtures"
	$(curl_post) -d @$(dir)/doc1.json $(endpoint)/$(db)
	$(curl_post) -d @$(dir)/doc2.json $(endpoint)/$(db)
	$(curl_post) -d @$(dir)/doc3.json $(endpoint)/$(db)
	$(curl_post) -d @$(dir)/doc4.json $(endpoint)/$(db)
	@echo "Creating index (Mango)"
	$(curl_post) -d @$(dir)/test-index1.txt $(endpoint)/$(db)/_index

run-tests:
	$(eval endpoint := $(shell minikube service $(public_service) --url))


docker-lint:
	$(hadolint) --ignore DL3008 --ignore DL3015 - < ./couchdb/Dockerfile
	$(hadolint) --ignore DL3008 --ignore DL3015 - < ./clouseau/Dockerfile
	$(hadolint) - < ./maven-mirror/Dockerfile-mirror
	$(hadolint) - < ./maven-mirror/Dockerfile-push

docker-build:
	docker build -t $(image_name) -f $(docker_file) .

test: clean setup run-tests
