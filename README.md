# CouchDB with Cloudant search

This is a merge from apache/couchdb-docker and homerjam/cloudant-search

The goal is to make a production ready and up to date docker container with Cloudant search, geo search (future) and CouchDB

Current version is [CouchDB 2.2.1](http://couchdb.apache.org/) with full text search capabilities that follows the steps from this [blog post](https://cloudant.com/blog/enable-full-text-search-in-apache-couchdb/#.Vly24SCrQbV) from [Cloudant](https://cloudant.com/).

## Prerequisites

 - You need to have a recent version of [Docker](https://www.docker.com/) installed
 - You need to have Minikube
 - You need to have helm

## Executing the Stack

This repository contains two helm charts:

 - .helm/cloudless-couchdb
 - .helm/cloudless-kubeseal

These charts serve as an example for a small Minikube deployment.

Deploy the cluster:

```
$ make helm-deploy
$ cd .kubeseal/ && make kubeseal-deploy # this ensures we set a master.key
$ cd ..
$ make cluster # this prints an IP:PORT to use for Fauxton
...
$ make helm-undeploy
```

Full text searching is enabled and fully functional. See the Cloudant [documentation](https://cloudant.com/for-developers/search/) for more info on how to test use the full text searching capabilities.

## Build images locally

For changes to the images, build the Docker images from the Dockerfile's using the following:

```
$ eval $(minikube docker-env)
$ make docker-build image_name=clouseau-test docker_file=./clouseau/Dockerfile
$ make docker-build image_name=couchdb-test docker_file=./couchdb/Dockerfile
```

Then configure `.helm/cloudless-couchdb/values.yaml` accordingly.

## Run tests

**Please note:** This expects you have a cluster in Minikube running.

Execute tests and watch output:

```
$ make test
$ make helm-lint
```

For CI, please see:

```
$ make docker-lint
```
