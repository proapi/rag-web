class Query < ApplicationRecord
  belongs_to :user

  validates :question, presence: true
  validates :user, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(error: nil) }
  scope :failed, -> { where.not(error: nil) }

  # Broadcast stat updates after creating a query
  after_create_commit :broadcast_stat_update

  def successful?
    error.nil?
  end

  def failed?
    !successful?
  end

  private

  def broadcast_stat_update
    broadcast_replace_to "queries_stats",
      target: "queries_stat",
      partial: "dashboard/queries_stat"
  end
end
