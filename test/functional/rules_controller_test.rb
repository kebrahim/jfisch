require 'test_helper'

class RulesControllerTest < ActionController::TestCase
  test "should get survivor" do
    get :survivor
    assert_response :success
  end

end
