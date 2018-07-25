.PHONY : clean setup run-tests

creds := jan:password
couchdb := http://$(creds)@couchdb.local
db := test-database
dir := $(shell pwd)/test
curl_post := @curl -s -X POST -H "Content-Type: application/json" -u $(creds)
curl_put := @curl -s -X PUT -H "Content-Type: application/json" -u $(creds)
hadolint := docker run --rm -i hadolint/hadolint hadolint
release := couchdb-test-cluster
nodes := 0 1 2
chart := ./.helm/cloudless-couchdb

build_test_images:
	@echo "Building images"
	eval $(minikube docker-env)
	#$(MAKE) docker-build image_name=clouseau-test docker_file=./clouseau/Dockerfile
	#$(MAKE) docker-build image_name=couchdb-test docker_file=./couchdb/Dockerfile

prepare-cluster:
	helm upgrade --install --debug $(release) ./.helm/cloudless-kubeseal
	cd .kubeseal && $(MAKE) kubeseal-deploy # replaces the master key

helm-deploy:
	@echo "Enabling ingress-nginx"
	minikube addons enable ingress
	@echo "Deploying to Minikube"
	helm upgrade --install --debug $(release) ./.helm/cloudless-couchdb
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
	@echo ""
	@echo "Cluster is (almost) ready! Please execute this, and then go check out CouchDB in the browser!"
	@echo 'minikube ip'
	@echo 'echo "<MINIKUBE IP> couchdb.local" | sudo tee -a /etc/hosts"'
	@echo 'open "http://couchdb.local"'

# in the end this will do the following:
# 1. confirm configuration we set (so it's applied)
# 2. confirm membership (count all_nodes vs. cluster_nodes in /_membership)
cluster-status:
	for number in $(nodes) ; do \
		kubectl exec -it $(release)-couchdb-$$number \
			-c couchdb -- bash -c "echo 'dreyfus.name: ' \
			&& curl -s $(couchdb)/_node/_local/_config/dreyfus/name \
			&& echo 'httpd.bind_address: ' \
			&& curl -s $(couchdb)/_node/_local/_config/httpd/bind_address \
			&& echo 'chttpd.bind_address: ' \
			&& curl -s $(couchdb)/_node/_local/_config/chttpd/bind_address " ; \
	done

helm-lint:
	helm lint ./.helm/cloudless-couchdb
	helm lint ./.helm/cloudless-kubeseal

helm-undeploy:
	@echo "Removing release"
	helm delete --purge $(release)

clean:
	@echo "Deleting $(db)"
	curl -X DELETE -u $(creds) $(couchdb)/$(db)

setup:
	@echo "Creating database(s) on all nodes of cluster $(endpoint)"
	$(curl_put) $(couchdb)/$(db)
	@echo "Populating '$(db)' with test data/fixtures"
	$(curl_post) -d @$(dir)/doc1.json $(couchdb)/$(db)
	$(curl_post) -d @$(dir)/doc2.json $(couchdb)/$(db)
	$(curl_post) -d @$(dir)/doc3.json $(couchdb)/$(db)
	$(curl_post) -d @$(dir)/doc4.json $(couchdb)/$(db)
	@echo "Creating index (Mango)"
	$(curl_post) -d @$(dir)/test-index1.txt $(couchdb)/$(db)/_index

run-tests:
	@echo "Query 1"
	$(curl_post) -d @$(dir)/test-query1.txt $(couchdb)/$(db)/_find
	#@echo "Query 2"
	#$(curl_post) -d @$(dir)/test-query2.txt $(endpoint)/$(db)/_find

docker-lint:
	$(hadolint) --ignore DL3008 --ignore DL3015 - < ./couchdb/Dockerfile
	$(hadolint) --ignore DL3008 --ignore DL3015 - < ./clouseau/Dockerfile
	$(hadolint) - < ./maven-mirror/Dockerfile-mirror
	$(hadolint) - < ./maven-mirror/Dockerfile-push

docker-build:
	docker build -t $(image_name) -f $(docker_file) .

test: clean setup run-tests
