class User < ActiveRecord::Base
  has_many :records, foreign_key: :creator_id
  has_many :project_memberships
  has_many :projects, through: :project_memberships

  def to_s
    name
  end
  def storage_path
    "#{ Rails.application.config.primary_storage_root }/#{ id }" if id
  end
end
