class RecordsController < ApplicationController
  skip_before_action :check_session, only: [:index]
  load_and_authorize_resource except: [:index]

  def index
    if params[:md5]
      @records = Record.find_by_md5(params[:md5]).select(:content_fingerprint, :created_at)
      @redirect_target = records_url
    else
      check_session
      @records = Record.accessible_by(current_ability)
    end
  end

  def show
    if params[:download_content]
      if @record.content?
        send_file @record.content.path, type: @record.content_content_type, filename: @record.content_file_name
      end
    else
      respond_to do |format|
        format.html # show.html.erb
        format.json #show.json.jbuilder
      end
    end
  end

  def new
  end

  def create
    @record.creator_id = current_user.id
    respond_to do |format|
      if @record.save
        format.html { redirect_to @record, notice: 'Record was successfully created.' }
        format.json { render action: 'show', status: :created, location: @record }
      else
        format.html { render action: 'new' }
        format.json { render json: @record.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    File.delete(@record.content.path)
    @record.is_destroyed = true
    @record.save
    respond_to do |format|
      format.html { redirect_to records_url }
      format.json { head :no_content }
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def record_params
      params.require(:record).permit(:content)
    end
end