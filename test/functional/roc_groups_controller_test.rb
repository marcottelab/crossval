require 'test_helper'

class RocGroupsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:roc_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create roc_group" do
    assert_difference('RocGroup.count') do
      post :create, :roc_group => { }
    end

    assert_redirected_to roc_group_path(assigns(:roc_group))
  end

  test "should show roc_group" do
    get :show, :id => roc_groups(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => roc_groups(:one).to_param
    assert_response :success
  end

  test "should update roc_group" do
    put :update, :id => roc_groups(:one).to_param, :roc_group => { }
    assert_redirected_to roc_group_path(assigns(:roc_group))
  end

  test "should destroy roc_group" do
    assert_difference('RocGroup.count', -1) do
      delete :destroy, :id => roc_groups(:one).to_param
    end

    assert_redirected_to roc_groups_path
  end
end
