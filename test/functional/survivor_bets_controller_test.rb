require 'test_helper'

class SurvivorBetsControllerTest < ActionController::TestCase
  setup do
    @survivor_bet = survivor_bets(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:survivor_bets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create survivor_bet" do
    assert_difference('SurvivorBet.count') do
      post :create, survivor_bet: { is_correct: @survivor_bet.is_correct, week: @survivor_bet.week }
    end

    assert_redirected_to survivor_bet_path(assigns(:survivor_bet))
  end

  test "should show survivor_bet" do
    get :show, id: @survivor_bet
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @survivor_bet
    assert_response :success
  end

  test "should update survivor_bet" do
    put :update, id: @survivor_bet, survivor_bet: { is_correct: @survivor_bet.is_correct, week: @survivor_bet.week }
    assert_redirected_to survivor_bet_path(assigns(:survivor_bet))
  end

  test "should destroy survivor_bet" do
    assert_difference('SurvivorBet.count', -1) do
      delete :destroy, id: @survivor_bet
    end

    assert_redirected_to survivor_bets_path
  end
end
