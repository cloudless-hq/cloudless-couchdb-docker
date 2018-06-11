.PHONY : clean setup tests

couchdb := http://till:till@127.0.0.1:5984
db := test-database
endpoint := $(couchdb)/$(db)
dir := $(shell pwd)
curl_post := @curl -X POST -H "Content-Type: application/json"

clean:
	curl -X DELETE $(couchdb)/test-database

setup:
	@echo "Creating database"
	curl -X PUT $(endpoint)
	@echo "Populating with test data/fixtures"
	$(curl_post) -d @$(dir)/test/doc1.json $(endpoint)
	$(curl_post) -d @$(dir)/test/doc2.json $(endpoint)
	$(curl_post) -d @$(dir)/test/doc3.json $(endpoint)
	$(curl_post) -d @$(dir)/test/doc4.json $(endpoint)
	@echo "Creating index (Mango)"
	$(curl_post) -d '{"_id":"_design/mango-index"}' $(endpoint)
	$(curl_post) -d @$(dir)/test/test-index1.txt $(endpoint)/_index

test: clean setup
