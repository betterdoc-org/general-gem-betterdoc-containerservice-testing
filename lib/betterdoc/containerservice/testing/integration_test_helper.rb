require "webmock/minitest"

require_relative "elasticsearch_test_helper" if defined?(Elasticsearch)
require_relative "jwt_authentication_test_helper"

module Betterdoc
  module Containerservice
    module IntegrationTestHelper
      extend ActiveSupport::Concern

      include ElasticsearchTestHelper if defined?(Elasticsearch)
      include JwtAuthenticationTestHelper

      included do
        setup do
          WebMock.disable_net_connect!(allow_localhost: true)
        end
      end
    end
  end
end
