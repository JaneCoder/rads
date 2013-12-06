require 'test_helper'

class RecordsControllerTest < ActionController::TestCase

  setup do
    @test_content_path = Rails.root.to_s + '/test/fixtures/attachments/content.txt'
    @test_content = File.new(@test_content_path)
    @expected_md5 = `/usr/bin/md5sum #{ @test_content.path }`.split.first.chomp

    @user = users(:non_admin)
    @user_record = records(:user)
    @user_record.content = @test_content
    @user_record.save

    @admin = users(:admin)
    @admin_record = records(:admin)
    @admin_record.content = @test_content
    @admin_record.save
  end

  teardown do
    @user_record.content.destroy
    @user_record.destroy
    @admin_record.content.destroy
    @admin_record.destroy
  end

  context 'Unauthenticated User' do
    should "get index with md5=value html parameter" do
      assert Record.find_by_md5(@expected_md5).count > 0, 'there should be a file with the expected md5'
      get :index, md5: @expected_md5
      assert_response :success
      assert_not_nil assigns(:records)
      assert assigns(:records).count > 0, 'there should be records with the expected md5'
      assigns(:records).each do |record|
        assert_equal @expected_md5, record.content_fingerprint
      end
    end

    should 'not get index without md5=value html parameter' do
      get :index
      assert_redirected_to sessions_new_url(:target => records_url)
    end
  end #Unauthenticated User

  context 'Admin' do

    setup do
      authenticate_existing_user(@admin, true)
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:records)
    end

    should 'get new' do
      get :new
      assert_response :success
    end

    should "post create" do
      assert_difference('Record.count') do
        post :create, record: {
          content: fixture_file_upload('attachments/content.txt', 'text/plain')
        }
      end
      assert_not_nil assigns(:record)
      assert_redirected_to record_path(assigns(:record))
      assert_equal @admin.id, assigns(:record).creator_id
      assert_equal @expected_md5, assigns(:record).content_fingerprint
      @expected_record_path = [ @admin.storage_path,  assigns(:record).id, assigns(:record).content_file_name ].join('/')
      assert_equal @expected_record_path, assigns(:record).content.path
      assigns(:record).content.destroy
      assigns(:record).destroy
    end

    should "show their record" do
      get :show, id: @admin_record
      assert_response :success
      assert_not_nil assigns(:record)
      assert_equal @admin_record.id, assigns(:record).id
    end

    should "show someone elses record" do
      get :show, id: @user_record
      assert_response :success
      assert_not_nil assigns(:record)
      assert_equal @user_record.id, assigns(:record).id
    end

    should 'download the content with download_content=true parameter to show' do
      get :show, id: @admin_record, download_content: true
      assert_response :success
      assert_equal "attachment; filename=\"#{ @admin_record.content_file_name }\"", @response.header["Content-Disposition"]
      assert_equal @admin_record.content_content_type, @response.header["Content-Type"]
    end

    should "destroy record by deleting the content, but keeping the record entry with is_disabled? true" do
      md5 = @admin_record.content_fingerprint
      name = @admin_record.content_file_name
      size = @admin_record.content_file_size
      path = @admin_record.content.path
      assert File.exist?( path ), 'content should be present before destroy'
      assert_no_difference('Record.count') do
        delete :destroy, id: @admin_record
      end
      assert_redirected_to records_path
      assert_not_nil assigns(:record)
      @tr = Record.find(assigns(:record).id)
      assert @tr.is_destroyed?, 'content should be destroyed'
      assert !File.exist?( path ), 'content should not be present after destroy'
      assert_equal md5, @tr.content_fingerprint
      assert_equal name, @tr.content_file_name
      assert_equal size, @tr.content_file_size
    end

    should "not destroy someone elses record" do
      assert @user_record.content.present?, 'content should be present before destroy'
      assert_no_difference('Record.count') do
        delete :destroy, id: @user_record
      end
      assert_response 403
      assert_not_nil assigns(:record)
      @tr = Record.find(assigns(:record).id)
      assert !@tr.is_destroyed?, 'content should not be destroyed'
      assert @tr.content.present?, 'content should be present after destroy'
    end

  end #Admin

  context 'NonAdmin' do

    setup do
      authenticate_existing_user(@user, true)
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:records)
    end

    should 'get new' do
      get :new
      assert_response :success
    end

    should "post create" do
      assert_difference('Record.count') do
        post :create, record: {
          content: fixture_file_upload('attachments/content.txt', 'text/plain')
        }
      end
      assert_not_nil assigns(:record)
      assert_redirected_to record_path(assigns(:record))
      assert_equal @user.id, assigns(:record).creator_id
      assert_equal @expected_md5, assigns(:record).content_fingerprint
      @expected_record_path = [ @user.storage_path,  assigns(:record).id, assigns(:record).content_file_name ].join('/')
      assert_equal @expected_record_path, assigns(:record).content.path
      assert File.exists? assigns(:record).content.path
      assigns(:record).content.destroy
      assigns(:record).destroy
    end

    should "show their record" do
      get :show, id: @user_record
      assert_response :success
      assert_not_nil assigns(:record)
      assert_equal @user_record.id, assigns(:record).id
    end

    should "not show someone elses record" do
      get :show, id: @admin_record
      assert_response 403
    end

    should 'download the content with download_content=true parameter to show' do
      get :show, id: @user_record, download_content: true
      assert_response :success
      assert_equal "attachment; filename=\"#{ @user_record.content_file_name }\"", @response.header["Content-Disposition"]
      assert_equal @user_record.content_content_type, @response.header["Content-Type"]
    end

    should "destroy record by deleting the content, but keeping the record entry with is_disabled? true" do
      md5 = @user_record.content_fingerprint
      name = @user_record.content_file_name
      size = @user_record.content_file_size
      path = @user_record.content.path
      assert File.exist?( path ), 'content should be present before destroy'
      assert_no_difference('Record.count') do
        delete :destroy, id: @user_record
      end
      assert_redirected_to records_path
      assert_not_nil assigns(:record)
      @tr = Record.find(assigns(:record).id)
      assert @tr.is_destroyed?, 'content should be destroyed'
      assert !File.exist?( path ), 'content should not be present after destroy'
      assert_equal md5, @tr.content_fingerprint
      assert_equal name, @tr.content_file_name
      assert_equal size, @tr.content_file_size
    end

    should "not destroy someone elses record" do
      assert @admin_record.content.present?, 'content should be present before destroy'
      assert_no_difference('Record.count') do
        delete :destroy, id: @admin_record
      end
      assert_response 403
      assert_not_nil assigns(:record)
      @tr = Record.find(assigns(:record).id)
      assert !@tr.is_destroyed?, 'content should not be destroyed'
      assert @tr.content.present?, 'content should be present after destroy'
    end

  end #NonAdmin

end
