require 'test_helper'

class CoreUserTest < ActiveSupport::TestCase
   should belong_to :core
   should validate_presence_of :core

  # ability test
  context 'nil user' do
    setup do
      @core_user = users(:core_user)
    end

    should 'pass ability profile' do
      denied_abilities(nil, @core_user, [:index, :show, :update, :destroy, :switch_to])
    end
  end #nil user

  context 'admin user' do
    setup do
      @user = users(:admin)
      @core_user = users(:core_user)
    end

    should 'pass ability profile' do
      allowed_abilities(@user, @core_user, [:index, :show, :update, :destroy, :switch_to])
    end
  end #admin user

  context 'repository user' do
    setup do
      @user_in_core = users(:non_admin)
      @user_not_in_core = users(:dm)
      @core_user = users(:core_user)
    end

    should 'be able to switch to a core_user if they are a member of the core of the core_user' do
      allowed_abilities(@user_in_core, @core_user, [:switch_to])
    end

    should 'not be able to switch to a core_user if they are not a member of the core of the core_user' do
      denied_abilities(@user_not_in_core, @core_user, [:switch_to])
    end

    should 'pass general ability profile' do
      denied_abilities(@user_in_core, @core_user, [:index, :show, :update, :destroy])
      denied_abilities(@user_not_in_core, @core_user, [:index, :show, :update, :destroy])
    end
  end #repository user

  context 'CoreUser' do
    setup do
      @core_user = users(:core_user)
      @other_core_user = users(:core_user_two)
    end

    should 'pass ability profile' do
      denied_abilities(@core_user, @core_user, [:show, :update, :destroy])
      denied_abilities(@core_user, @other_core_user, [:show, :update, :destroy])
      User.all.each do |user|
        denied_abilities(@core_user, user, [:switch_to])
      end
    end
  end #CoreUser

  context 'ProjectUser' do
    setup do
      @project_user = users(:project_user)
      @other_project_user = users(:project_user_two)
    end

    should 'pass ability profile' do
      denied_abilities(@project_user, @project_user, [:show, :update, :destroy])
      denied_abilities(@project_user, @other_project_user, [:show, :update, :destroy])
      User.all.each do |user|
        denied_abilities(@project_user, user, [:switch_to])
      end
    end
  end #ProjectUser
end
