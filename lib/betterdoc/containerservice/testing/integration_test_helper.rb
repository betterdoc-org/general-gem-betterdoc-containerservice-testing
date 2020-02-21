require "climate_control"
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

      private

      def stacker_events
        header = response.headers["X-Stacker-Event"]
        return [] if header.blank?

        if header.starts_with?("multi-encoded")
          header.sub("multi-encoded ", "").split(", ").map { |h| Base64.strict_decode64(h) }
        else
          [header.sub("simple ", "")]
        end
      end

      def with_modified_env(options, &block)
        ClimateControl.modify(options, &block)
      end
    end
  end
end
