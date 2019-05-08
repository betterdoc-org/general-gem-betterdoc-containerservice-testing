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

### JWT authentication

We use a JSON Web Token (JWT) to authenticate all calls to our container services.

To allow easy testing and make sure that an integrationtest doesn't need to setup the right keys and token for testing, the `AuthenticationTestHelper` can be included in a test:

```ruby
require 'test_helper'
require 'betterdoc/containerservice/testing/authentication/authentication_test_helper'

class SelectControllerTest < ActionDispatch::IntegrationTest
  include Betterdoc::Containerservice::Testing::Authentication::AuthenticationTestHelper

  test "an example test using a parameter" do
  
    get '/your-endpoint', params: { '_jwt' => Betterdoc::Containerservice::Testing::Authentication::AuthenticationTestHelper.create_valid_jwt }

    assert_response 200

  end 

  test "an example test using a header " do
  
    get '/your-endpoint', headers: { 'Authorization' => "Bearer #{Betterdoc::Containerservice::Testing::Authentication::AuthenticationTestHelper.create_valid_jwt}" }

    assert_response 200
  
  end 

end
```
