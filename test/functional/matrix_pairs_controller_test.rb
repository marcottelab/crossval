require 'test_helper'

class MatrixPairsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:matrix_pairs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create matrix_pair" do
    assert_difference('MatrixPair.count') do
      post :create, :matrix_pair => { }
    end

    assert_redirected_to matrix_pair_path(assigns(:matrix_pair))
  end

  test "should show matrix_pair" do
    get :show, :id => matrix_pairs(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => matrix_pairs(:one).to_param
    assert_response :success
  end

  test "should update matrix_pair" do
    put :update, :id => matrix_pairs(:one).to_param, :matrix_pair => { }
    assert_redirected_to matrix_pair_path(assigns(:matrix_pair))
  end

  test "should destroy matrix_pair" do
    assert_difference('MatrixPair.count', -1) do
      delete :destroy, :id => matrix_pairs(:one).to_param
    end

    assert_redirected_to matrix_pairs_path
  end
end
