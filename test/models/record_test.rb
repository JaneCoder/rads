require 'test_helper'

class RecordTest < ActiveSupport::TestCase

  should belong_to :creator
  should have_attached_file(:content)
  should have_many :project_affiliated_records
  should have_many(:projects).through(:project_affiliated_records)
  should have_many :audited_activities
  should accept_nested_attributes_for :project_affiliated_records

  setup do
    @test_content_path = Rails.root.to_s + '/test/fixtures/attachments/content.txt'
    @test_content = File.new(@test_content_path)
    @expected_md5 = `/usr/bin/md5sum #{ @test_content.path }`.split.first.chomp

    @user = users(:non_admin)
    @user_record = records(:user)
    @user_record.content = @test_content
    @user_record.save
    @expected_path = [ @user.storage_path,  @user_record.id, @user_record.content_file_name ].join('/')

    @admin = users(:admin)
    @admin_record = records(:admin)

    @core_user = users(:core_user)
    @core_user_record = records(:core_user)

    @project_user = users(:project_user)
    @project_user_record = records(:project_user)
  end

  teardown do
    @user_record.content.destroy
    @user_record.destroy
    @admin_record.content.destroy
    @admin_record.destroy
    @core_user_record.content.destroy
    @core_user_record.destroy
  end

  should 'support find_by_md5 method' do
    assert_respond_to Record, 'find_by_md5'
    @trec = Record.find_by_md5(@expected_md5).take!
    assert_not_nil @trec
    assert_equal @user_record.id, @trec.id
  end
    
  should 'store content relative to user.storage_path' do
    assert_equal @expected_path, @user_record.content.path
    assert_equal @expected_md5, @user_record.content_fingerprint
  end

  context 'nil user' do
    should 'pass ability profile' do
      denied_abilities(nil, Record, [:index] )
      denied_abilities(nil, @user_record, [:show, :destroy])
      denied_abilities(nil, @admin_record, [:show, :destroy])
      denied_abilities(nil, Record.new, [:new, :create])
    end
  end #nil user
  
  context 'non_admin' do
    should 'pass ability profile' do
      allowed_abilities(@user, Record, [:index])
      allowed_abilities(@user, @user_record, [:index, :show, :destroy])
      denied_abilities(@user, @admin_record, [:index, :show, :destroy])
      allowed_abilities(@user, @user.records.build, [:new, :create])
    end
  end #non_admin

  context 'CoreUser' do
    should 'pass ability profile' do
      allowed_abilities(@core_user, Record, [:index])
      allowed_abilities(@core_user, @core_user_record, [:index, :show, :destroy])
      denied_abilities(@core_user, @admin_record, [:index, :show, :destroy])
      allowed_abilities(@core_user, @core_user.records.build, [:new, :create])
    end
  end #CoreUser

  context 'ProjectUser' do
    should 'pass ability profile' do
      allowed_abilities(@project_user, Record, [:index])
      allowed_abilities(@project_user, @project_user_record, [:index, :show, :destroy])
      denied_abilities(@project_user, @admin_record, [:index, :show, :destroy])
      allowed_abilities(@project_user, @project_user.records.build, [:new, :create])
    end
  end #ProjectUser

  context 'admin' do
    should 'pass ability profile' do      
      allowed_abilities(@admin, Record, [:index] )
      allowed_abilities(@admin, @user_record, [:show])
      allowed_abilities(@admin, @admin.records.build, [:new, :create])
      denied_abilities(@admin, @user.records.build, [:new, :create])
    end
  end #non_admin

  context 'ProjectMembership' do
    setup do
      @user = users(:non_admin)
      @project_with_membership = projects(:one)
      @project_record_not_owned_by_user = records(:project_one_affiliated_project_user)
      @non_member_project_record = records(:project_two_affiliated)
    end

    should 'pass ability profile' do
      assert @project_with_membership.is_member?(@user), 'user should be a member of the project'
      assert @project_with_membership.is_affiliated_record?(@project_record_not_owned_by_user), 'record should be affiliated with project'
      allowed_abilities(@user, @project_record_not_owned_by_user, [:index, :show])
      denied_abilities(@user, @project_record_not_owned_by_user, [:destroy])
      denied_abilities(@user, @non_member_project_record, [:index, :show, :destroy])
    end
  end #ProjectMembership
end
