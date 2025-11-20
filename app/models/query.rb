class Query < ApplicationRecord
  belongs_to :user

  validates :question, presence: true
  validates :user, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(error: nil) }
  scope :failed, -> { where.not(error: nil) }

  def successful?
    error.nil?
  end

  def failed?
    !successful?
  end
end
