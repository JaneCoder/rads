require 'test_helper'

class SwitchUserControllerTest < ActionController::TestCase

  context 'Not Authenticated' do
    should 'not get switch_user' do
      User.all.each do |user|
        get :switch_to, id: user.id, target: @controller.url_for(user)
        assert_redirected_to sessions_new_url(:target => switch_to_url(id: user.id, target: @controller.url_for(user)))
      end
    end
    should 'not get destroy' do
      get :destroy, target: users_url
      assert_redirected_to sessions_new_url(:target => switch_back_url(target: users_url))
    end
  end # Not Authenticated

  context 'Authenticated without session' do
    should 'not get switch_user' do
      RepositoryUser.all.each do |ruser|
        authenticate_existing_user(ruser)
        User.where.not(id: ruser.id).each do |ouser|
          get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
          assert_redirected_to sessions_create_url(:target => switch_to_url(id: ouser.id, target: @controller.url_for(ouser)))
        end
      end
    end

    should 'not get destroy' do
      RepositoryUser.all.each do |ruser|
        authenticate_existing_user(ruser)
        get :destroy, target: users_url
        assert_redirected_to sessions_create_url(:target => switch_back_url(target: users_url))
      end
    end
  end #Authenticated without session

  context 'Disabled User' do
    should 'not get switch_user' do
      RepositoryUser.all.each do |ruser|
        ruser.is_enabled = false
        ruser.save
        authenticate_existing_user(ruser, true)
        User.where.not(id: ruser.id).each do |ouser|
          get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
          assert_redirected_to repository_user_url(ruser)
          assert session[:switch_to_user_id].nil?, 'switch_to_user_id should be nil'
          assert session[:switch_back_user_id].nil?, 'switch_to_user_id should not be in the session'
        end
      end
    end

    should 'not get destroy' do
      RepositoryUser.all.each do |ruser|
        ruser.is_enabled = false
        ruser.save
        authenticate_existing_user(ruser, true)
        get :destroy, target: users_url
        assert_redirected_to repository_user_url(ruser)
      end
    end
  end # Disabled User

  context 'NonAdmin' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should 'not get switch_user' do
      User.where.not(id: @user.id).each do |ouser|
        get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
        assert_response 403
        assert session[:switch_to_user_id].nil?, 'switch_to_user_id should be nil'
        assert session[:switch_back_user_id].nil?, 'switch_to_user_id should not be in the session'
      end
    end

    should 'get destroy' do
      get :destroy, target: users_url
      assert_redirected_to users_url
      assert session[:switch_to_user_id].nil?, 'switch_to_user_id should be nil'
      assert session[:switch_back_user_id].nil?, 'switch_to_user_id should not be in the session'
    end
  end #NonAdmin

  context 'Admin' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
    end

    should 'not get switch_user' do
      User.where.not(id: @user.id).each do |ouser|
        get :switch_to, id: ouser.id, target: @controller.url_for(ouser)
        assert_redirected_to @controller.url_for(ouser)
        assert_not_nil session[:switch_to_user_id]
        assert_not_nil session[:switch_back_user_id]
        assert_equal ouser.id, session[:switch_to_user_id]
        assert_equal ouser.name, @controller.current_user.name
        assert_equal ouser.id, @controller.current_user.id
        assert_equal @user.id, session[:switch_back_user_id]
        session[:switch_to_user_id] = nil
        session[:switch_back_user_id] = nil
      end
    end

    should 'get destroy' do
      session[:switch_to_user_id] = users(:non_admin).id
      get :destroy, target: users_url
      assert_redirected_to users_url
      assert session[:switch_to_user_id].nil?, 'switch_to_user_id should not be in the session after destroy'
      assert session[:switch_back_user_id].nil?, 'switch_to_user_id should not be in the session after destroy'
      assert_equal @user.id, @controller.current_user.id
    end
  end # Admin

end

