require 'test_helper'

class NflSchedulesControllerTest < ActionController::TestCase
  setup do
    @nfl_schedule = nfl_schedules(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:nfl_schedules)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create nfl_schedule" do
    assert_difference('NflSchedule.count') do
      post :create, nfl_schedule: { away_score: @nfl_schedule.away_score, home_score: @nfl_schedule.home_score, start_time: @nfl_schedule.start_time, week: @nfl_schedule.week, year: @nfl_schedule.year }
    end

    assert_redirected_to nfl_schedule_path(assigns(:nfl_schedule))
  end

  test "should show nfl_schedule" do
    get :show, id: @nfl_schedule
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @nfl_schedule
    assert_response :success
  end

  test "should update nfl_schedule" do
    put :update, id: @nfl_schedule, nfl_schedule: { away_score: @nfl_schedule.away_score, home_score: @nfl_schedule.home_score, start_time: @nfl_schedule.start_time, week: @nfl_schedule.week, year: @nfl_schedule.year }
    assert_redirected_to nfl_schedule_path(assigns(:nfl_schedule))
  end

  test "should destroy nfl_schedule" do
    assert_difference('NflSchedule.count', -1) do
      delete :destroy, id: @nfl_schedule
    end

    assert_redirected_to nfl_schedules_path
  end
end
