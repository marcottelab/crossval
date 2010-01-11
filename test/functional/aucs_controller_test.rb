require 'test_helper'

class AucsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:aucs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create auc" do
    assert_difference('Auc.count') do
      post :create, :auc => { }
    end

    assert_redirected_to auc_path(assigns(:auc))
  end

  test "should show auc" do
    get :show, :id => aucs(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => aucs(:one).to_param
    assert_response :success
  end

  test "should update auc" do
    put :update, :id => aucs(:one).to_param, :auc => { }
    assert_redirected_to auc_path(assigns(:auc))
  end

  test "should destroy auc" do
    assert_difference('Auc.count', -1) do
      delete :destroy, :id => aucs(:one).to_param
    end

    assert_redirected_to aucs_path
  end
end
