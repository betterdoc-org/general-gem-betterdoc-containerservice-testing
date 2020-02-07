require "climate_control"
require "minitest/hooks/test"

module Betterdoc
  module Containerservice
    module JwtAuthenticationTestHelper
      extend ActiveSupport::Concern
      include Minitest::Hooks

      class_methods do
        # This macro makes it easy to test that all actions inside controller
        # are not accessible and return proper responses if JWT is missing or
        # invalid.
        #
        #   class MyControllerTest < ContainerService::IntegrationTest
        #     it_should_require_jwt_authentication
        #
        #     test "something" do
        #       # ...
        #     end
        #   end
        #
        # Maybe we should even set this to be called automatically for all
        # controller tests that inherit from ContainerService::IntegrationTest
        def it_should_require_jwt_authentication
          controller_name = self.to_s.sub(/Test$/, "").constantize.controller_name
          Rails.application.routes.routes.select { |r| r.defaults[:controller] == controller_name }.each do |route|
            path = route.format({})
            verb = route.verb.downcase
            define_method("test_empty_unauthorized_response_is_returned_if_jwt_is_missing") do
              public_send(verb, path, headers: { "Authorization" => nil })
              assert_response :unauthorized
            end

            define_method("test_empty_forbidden_response_is_returned_if_invalid_jwt_is_passed") do
              public_send(verb, path, headers: { "Authorization" => "JwtToken Invalid-Token" })
              assert_response :forbidden
            end
          end
        end
      end

      # Around callback that makes sure default ENV variables needed for JWT
      # authentication are set by default.
      # It is still possible to overwrite some of the ENV vars for specific case.
      #
      #   class MyControllerTest < ContainerService::IntegrationTest
      #     test "env var needs to be stubed for this test" do
      #       ClimateControl.modify(JWT_VALIDATION_ENABLED: "false") do
      #         # ...
      #       end
      #     end
      #   end
      #
      def around
        ClimateControl.modify(default_env_vars) do
          super
        end
      end

      # Original methods that simulate requests are overwritten so that header
      # with valid JWT token is always added to the request.
      #
      # It is still possible to test missing and invalid tokens by explicitly
      # setting the header.
      #
      #   get "/some_path", headers: { "Authorization" => "Some invalid token" }
      #
      %w[delete get head patch post put].each do |name|
        define_method(name) do |action, **args|
          args[:headers] ||= {}
          args[:headers]["Authorization"] = "Bearer #{valid_jwt}" unless args[:headers].key?("Authorization")
          super(action, args)
        end
      end

      private

      def default_env_vars
        {
          JWT_PUBLIC_KEY: jwt_public_key.to_s,
          JWT_VALIDATION_ALGORITHM: "RS256",
          JWT_VALIDATION_ENABLED: "true"
        }
      end

      def jwt_public_key
        @jwt_public_key ||= OpenSSL::PKey::RSA.generate(512)
      end

      def valid_jwt
        @valid_jwt ||= JWT.encode({ exp: (Time.now + 1.hour).utc.to_i }, jwt_public_key, "RS256")
      end
    end
  end
end
