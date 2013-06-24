require 'test_helper'

class SurvivorEntriesControllerTest < ActionController::TestCase
  setup do
    @survivor_entry = survivor_entries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:survivor_entries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create survivor_entry" do
    assert_difference('SurvivorEntry.count') do
      post :create, survivor_entry: { game_type: @survivor_entry.game_type, is_alive: @survivor_entry.is_alive, used_autopick: @survivor_entry.used_autopick, year: @survivor_entry.year }
    end

    assert_redirected_to survivor_entry_path(assigns(:survivor_entry))
  end

  test "should show survivor_entry" do
    get :show, id: @survivor_entry
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @survivor_entry
    assert_response :success
  end

  test "should update survivor_entry" do
    put :update, id: @survivor_entry, survivor_entry: { game_type: @survivor_entry.game_type, is_alive: @survivor_entry.is_alive, used_autopick: @survivor_entry.used_autopick, year: @survivor_entry.year }
    assert_redirected_to survivor_entry_path(assigns(:survivor_entry))
  end

  test "should destroy survivor_entry" do
    assert_difference('SurvivorEntry.count', -1) do
      delete :destroy, id: @survivor_entry
    end

    assert_redirected_to survivor_entries_path
  end
end
