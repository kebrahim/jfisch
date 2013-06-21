require 'test_helper'

class NflTeamsControllerTest < ActionController::TestCase
  setup do
    @nfl_team = nfl_teams(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:nfl_teams)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create nfl_team" do
    assert_difference('NflTeam.count') do
      post :create, nfl_team: { abbreviation: @nfl_team.abbreviation, city: @nfl_team.city, name: @nfl_team.name }
    end

    assert_redirected_to nfl_team_path(assigns(:nfl_team))
  end

  test "should show nfl_team" do
    get :show, id: @nfl_team
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @nfl_team
    assert_response :success
  end

  test "should update nfl_team" do
    put :update, id: @nfl_team, nfl_team: { abbreviation: @nfl_team.abbreviation, city: @nfl_team.city, name: @nfl_team.name }
    assert_redirected_to nfl_team_path(assigns(:nfl_team))
  end

  test "should destroy nfl_team" do
    assert_difference('NflTeam.count', -1) do
      delete :destroy, id: @nfl_team
    end

    assert_redirected_to nfl_teams_path
  end
end
