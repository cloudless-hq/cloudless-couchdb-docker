# A simple test setup

 1. Install minikube and start it
 2. Ensure we use Minikube's Docker Daemon: `eval $(minikube docker-env)`
 3. (from the top directory): `docker build -t couchdb-test:latest -f ./couchdb/Dockerfile .`
 4. Deploy this chart: `helm install --debug ./helm/cloudless-couchdb` (or: `helm list` and `helm upgrade <release> ./.helm/cloudless-couchdb`)
