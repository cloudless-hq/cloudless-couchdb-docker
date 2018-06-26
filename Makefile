.PHONY : clean setup run-tests

couchdb := http://jan:password@127.0.0.1:5984
db := test-database
endpoint := $(couchdb)/$(db)
dir := $(shell pwd)/test
curl_post := @curl -X POST -H "Content-Type: application/json"
curl_put := @curl -X PUT -H "Content-Type: application/json"
hadolint := docker run --rm -i hadolint/hadolint hadolint
release := couchdb-test-cluster

helm-deploy:
	@echo "Building images"
	eval $(minikube docker-env)
	$(MAKE) docker-build image_name=clouseau-test docker_file=./clouseau/Dockerfile
	$(MAKE) docker-build image_name=couchdb-test docker_file=./couchdb/Dockerfile
	@echo "Deploying to Minikube"
	helm install --name $(release) ./.helm/cloudless-couchdb
	@echo "Finish cluster setup"
	kubectl exec -it $(release)-couchdb-0 -c couchdb -- \
 curl -s \
 http://127.0.0.1:5984/_cluster_setup \
 -X POST \
 -H "Content-Type: application/json" \
 -d '{"action": "finish_cluster"}' \
 -u "jan:password"

helm-lint:
	helm lint ./.helm/cloudless-couchdb

helm-undeploy:
	@echo "Removing release"
	helm delete --purge $(release)

helm-upgrade:
	helm upgrade $(release) ./.helm/cloudless-couchdb

clean:
	@echo "Deleting $(db)"
	curl -X DELETE $(endpoint)

setup:
	@echo "Creating database(s)"
	$(curl_put) $(couchdb)/_users
	$(curl_put) $(couchdb)/_replicator
	$(curl_put) $(couchdb)/_global_changes
	$(curl_put) $(endpoint)
	@echo "Populating '$(db)' with test data/fixtures"
	$(curl_post) -d @$(dir)/doc1.json $(endpoint)
	$(curl_post) -d @$(dir)/doc2.json $(endpoint)
	$(curl_post) -d @$(dir)/doc3.json $(endpoint)
	$(curl_post) -d @$(dir)/doc4.json $(endpoint)
	@echo "Creating index (Mango)"
	$(curl_post) -d @$(dir)/test-index1.txt $(endpoint)/_index

run-tests:
	@echo "Query 1"
	$(curl_post) -d @$(dir)/test-query1.txt $(endpoint)/_find
	@echo "Query 2"
	$(curl_post) -d @$(dir)/test-query2.txt $(endpoint)/_find

docker-lint:
	$(hadolint) --ignore DL3008 --ignore DL3015 - < ./couchdb/Dockerfile
	$(hadolint) --ignore DL3008 --ignore DL3015 - < ./clouseau/Dockerfile
	$(hadolint) - < ./maven-mirror/Dockerfile-mirror
	$(hadolint) - < ./maven-mirror/Dockerfile-push

docker-build:
	docker build -t $(image_name) -f $(docker_file) .

test: clean setup run-tests
