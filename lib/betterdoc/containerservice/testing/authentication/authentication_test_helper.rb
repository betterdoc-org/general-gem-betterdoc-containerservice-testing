require 'jwt'
require 'openssl'

module Betterdoc
  module Containerservice
    module Testing
      module Authentication
        module AuthenticationTestHelper
          extend ActiveSupport::Concern

          included do
            setup do
              ApplicationController.any_instance.stubs(:compute_jwt_validation_enabled).returns(true)
              ApplicationController.any_instance.stubs(:compute_jwt_public_key).returns(AuthenticationTestHelper.lookup_jwt_public_key.to_s)
              ApplicationController.any_instance.stubs(:compute_jwt_validation_algorithm).returns('RS256')
            end
          end

          @jwt_private_key = OpenSSL::PKey::RSA.generate(512)

          class << self

            def lookup_jwt_private_key
              @jwt_private_key
            end

            def lookup_jwt_public_key
              @jwt_private_key
            end

            def create_valid_jwt
              JWT.encode({ exp: (Time.now + 1.hour).utc.to_i }, @jwt_private_key, 'RS256')
            end

          end

        end
      end
    end
  end
end
