# CouchDB with Cloudant search

This is a merge from apache/couchdb-docker and homerjam/cloudant-search

The goal is to make a production ready and up to date docker container with Cloudant search, geo search (future) and CouchDB

Current version is [CouchDB 2.2.1](http://couchdb.apache.org/) with full text search capabilities that follows the steps from this [blog post](https://cloudant.com/blog/enable-full-text-search-in-apache-couchdb/#.Vly24SCrQbV) from [Cloudant](https://cloudant.com/).

Full text searching is enabled and fully functional. See the Cloudant [documentation](https://cloudant.com/for-developers/search/) for more info on how to test use the full text searching capabilities.

## Prerequisites

 - ~~You need to have a recent version of [Docker](https://www.docker.com/) installed~~
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
$ make cluster # this prints an IP:PORT to use for Fauxton
...
$ make helm-undeploy
```

### Behind the scenese

 1. We deploy our helm chart for Kubeseal first, followed by the chart for cloudless-couchdb.
 2. In between, we ensure _our_ master.key is used so the admin secret for CouchDB can be decrypted.

## `Secret` and `SealedSecret`

Speaking of secrets! Kubeseal creates a `Secret`, from our `SealedSecret`.

Check out [couchdb-secret.json-dist](couchdb-secret.json-dist) for our "un-sealed" base.

The _sealed_ result is checked into `.helm/cloudless-couchdb/templates/couchdb-admin-secret.yaml`.
