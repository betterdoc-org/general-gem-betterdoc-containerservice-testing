# Betterdoc::Containerservice::Testing

This gem is designed to help with testing our container services.

It assumes the services temselves are based on out `Betterdoc::Containerservice` gem available at: https://github.com/betterdoc-org/general-gem-betterdoc-containerservice

## Installation

Add this line to your application's Gemfile:

```ruby
# ...
group :development, :test do
  gem 'betterdoc-containerservice-testing', git: 'https://github.com/betterdoc-org/general-gem-betterdoc-containerservice-testing'
end
# ...
```

## Functionalities

The following functionalities are available:

### External requests are blocked by default

All non local requests are blocked by default. In case it detects one it will give you suggestion how to successfully stub it.

### JWT authentication

We use a JSON Web Token (JWT) to authenticate all calls to our container services.

To allow easy testing and make sure that you do not have to think about JWT original `ActionDispatch::IntegrationTest` methods that simulate requests (`delete, get, head, patch, post, put`) are overwritten so that header with valid JWT token is always added to the request.

```ruby
# Authorization header with valid JWT token will be automatically added, no need to worry about it
get "/something", params:  { foo: :bar }
```

To test that all actions inside some controller are not accessible if JWT is missing or invalid and return proper responses just add `it_should_require_jwt_authentication` call to your controller test.

```ruby
class MyControllerTest < ActionDispatch::IntegrationTest
  it_should_require_jwt_authentication

  test "something" do
    # ...
  end
end
```

Although it is not needed in most cases you can still manually test missing or invalid token use cases by explicitly setting the header.

```ruby
# Invalid token
get "/something", headers: { "Authorization" => "Invalid token" }
# Missing token
get "/something", headers: { "Authorization" => nil }
```

### Elasticsearch

This gem offers two ways of testing Elasticsearch related scenarios. In most cases you should go with stubbing the ES calls cause it is much faster and simpler.
Test cluster option is slower and more complicated to setup so use it only when you need to test that ES is returning currect results.

If you have `elasticsearch-ruby` gem in your Gemfile support for testing Elasticsearch will be automatically required.

#### Stub Elasticsearch calls

Calling `with_stubbed_elasticsearch` block helper will stub all calls to Elasticsearch service and return results you pass as hits argument.

```ruby
test "something that uses Elasticsearch as a data source" do
  with_stubbed_elasticsearch hits: [{ name: "Vlado Cingel" }, { name: "Petar Cingel }] do
    get "/search", params: { q: "cingel" }
  end

  assert_response :success
  assert_select ".search-result", count: 2
end
```

This will stub all calls to ES which makes it super fast and easy to use. Downside is that you can not test if ES returns proper results.

#### Elasticsearch Test Cluster

Calling `with_elasticsearch_test_cluster` block helper will check if Elasticsearch test cluster is running and then run all calls inside that block agains test cluster.

```ruby
test "some complex elasticsearch search use case" do
  with_elasticsearch_test_cluster index: "my-index" do
    index_in_elasticsearch(index: "my-index", type: "person", id: 1, body: { name: "Vlado Cingel" })
    index_in_elasticsearch(index: "my-index", type: "person", id: 2, body: { name: "Petar Cingel" })

    results = MySearch.search("petar")
    assert_equal 1, results.size

    results = MySearch.search("cingel")
    assert_equal 2, results.size
  end
end
```

`index` argument is mandatory cause missing index could result in false positives in some cases. This helper will clean up after it self and delete created index.

`index_in_elasticsearch` helper method is here to help you add documents to ES index.

This option expect ES test cluster running, proper indexes to be created, documents to be indexed so it is much more complicated to setup and slower but it is needed to
be able to test results returned from Elasticsearch.

To start the test cluster download correct Elasticsearch version from https://www.elastic.co/downloads/elasticsearch, then go to https://github.com/elastic/elasticsearch-ruby/tree/master/elasticsearch-extensions#testcluster and follow instructions have to setup proper ENV variables.

