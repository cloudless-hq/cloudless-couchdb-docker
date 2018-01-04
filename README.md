# cloudant-search
This is a merge from apache/couchdb-docker and homerjam/cloudant-search

The goal is to make a production ready and up to date docker container with cloudant search, geo serach (future) and couchdb

Current version is [CouchDB 2.1.1](http://couchdb.apache.org/) with full text search capabilities that follows the steps from this [blog post](https://cloudant.com/blog/enable-full-text-search-in-apache-couchdb/#.Vly24SCrQbV) from [Cloudant](https://cloudant.com/).

## Prerequisites

You need to have a recent version of [Docker](https://www.docker.com/) installed

## Executing the Stack

Build the CouchDB image from the Dockerfile and run using the following:

```
$ docker-copose up

```

There will be a Fauxton console available at http://localhost:5984/_utils

Full text searching is enabled and fully functional.  See the Cloudant [documentation](https://cloudant.com/for-developers/search/) for more info on how to test use the full text searching capabilities.
