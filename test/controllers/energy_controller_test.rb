require "test_helper"

class EnergyControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get energy_index_url
    assert_response :success
  end

  test "should get claim" do
    get energy_claim_url
    assert_response :success
  end
end
