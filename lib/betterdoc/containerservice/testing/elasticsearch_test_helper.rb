require "climate_control"
require "minitest/hooks/test"

module Betterdoc
  module Containerservice
    module ElasticsearchTestHelper
      extend ActiveSupport::Concern
      include Minitest::Hooks

      TEST_CLUSTER_PORT = ENV["TEST_CLUSTER_PORT"] || "9250"
      TEST_CLUSTER_ELASTICSEARCH_URL = "http://localhost:#{TEST_CLUSTER_PORT}".freeze

      # Sets ELASTICSEARCH_URL to the one configured for test cluster
      def around
        ClimateControl.modify(ELASTICSEARCH_URL: TEST_CLUSTER_ELASTICSEARCH_URL) do
          super
        end
      end

      private

      def elasticsearch
        @elasticsearch ||= Elasticsearch::Client.new(url: TEST_CLUSTER_ELASTICSEARCH_URL)
      end

      # Adds document with provided values to provided Elasticsearch index
      # It is probably better to add wrapper around this method for your use case.
      #
      #   def index_case(attributes)
      #     id = attributes[:id].presence || generate_case_id
      #     index_in_elasticsearch(index: "case_search", type: "case", id: id, body: { case: attributes })
      #   end
      def index_in_elasticsearch(options)
        raise "You must provide Elasticsearch index name" if options[:index].blank?

        options[:refresh] = true unless options.key?(:refresh)
        elasticsearch.index(options)
      end

      def safe_create_index(index)
        elasticsearch.indices.delete(index: index) if elasticsearch.indices.exists?(index: index)
        elasticsearch.indices.create(index: index)
      end

      def safe_delete_index(index)
        return unless elasticsearch.indices.exists?(index: index)

        elasticsearch.indices.delete(index: index)
      end

      # Helper to run tests using Elasticsearch test cluster.
      # It expects running test cluster. To start the test cluster download
      # correct Elasticsearch version from
      # https://www.elastic.co/downloads/elasticsearch, set proper env
      # variables (See https://github.com/elastic/elasticsearch-ruby/tree/master/elasticsearch-extensions#testcluster)
      # and then run `bin/elasticsearch-test-cluster`.
      #
      # Usage:
      #
      #   test "some complex elasticsearch stuff" do
      #     with_elasticsearch_test_cluster index: "my-index" do
      #       index_in_elasticsearch(index: "my-index", type: "person", id: 1, body: { name: "Vlado Cingel" })
      #       index_in_elasticsearch(index: "my-index", type: "person", id: 2, body: { name: "Petar Cingel" })
      #
      #       results = MySearch.search("petar")
      #       assert_equal 1, results.size
      #
      #       results = MySearch.search("cingel")
      #       assert_equal 2, results.size
      #     end
      #   end
      #
      # It is usefull when you are testing that proper stuff is returned from ES.
      # In case results from ES are not main concern of the test it is better to
      # use `with_stubbed_elasticsearch` helper cause it is much faster. No need
      # to have running cluster, create index, ...
      #
      # Initially I tried something like this:
      #
      #   def with_elasticsearch_test_cluster(options = {})
      #     Elasticsearch::Extensions::Test::Cluster.start unless Elasticsearch::Extensions::Test::Cluster.running?
      #     yield
      #     Elasticsearch::Extensions::Test::Cluster.stop
      #   end
      #
      # But it was too slow even if I put this in around all callback. During
      # development you need quick feedback and that is only possible if cluster
      # is running in the background all the time and does not have to be started
      # stoped each time you run tests.
      def with_elasticsearch_test_cluster(options = {})
        begin
          require "elasticsearch/extensions/test/cluster"
        rescue LoadError => e
          raise LoadError, "#{e.message}\nYou need to have `elasticsearch-extensions` gem installed to be able to test with test cluster."
        end
        raise "Please start Elasticsearch test cluster with `bundle exec elasticsearch-test-cluster start`" unless Elasticsearch::Extensions::Test::Cluster.running?

        safe_create_index(options[:index]) if options[:index].present?
        yield
        safe_delete_index(options[:index]) if options[:index].present?
      end

      # Helper to run tests using stubbed response from Elasticsearch. The idea is
      # to use it when main concern of the test is not the result that is returned
      # from ES.
      #
      # Usage:
      #
      #   test "something that uses ES as a data source" do
      #     with_stubbed_elasticsearch hits: [{ name: "Vlado Cingel" }, { name: "Petar Cingel }] do
      #       get "/search", params: { q: "cingel" }
      #     end
      #
      #     assert_response :success
      #     assert_select ".search-result", count: 2
      #   end
      #
      # It uses WebMock to stub requests to ELASTICSEARCH_URL and returns results
      # that you pass as `hits` options.
      def with_stubbed_elasticsearch(options = {})
        hits = (options[:hits] || []).map { |hit| { "_source" => hit }}
        total = options[:total] || hits.size
        result = { "hits" => { "hits" => hits, "total" => total } }

        stub = stub_request(:get, %r{#{ENV['ELASTICSEARCH_URL']}}).to_return(
          body: result.to_json,
            headers: { "Content-Type"=> "application/json" }
        )
        yield
        remove_request_stub(stub)
      end
    end
  end
end
