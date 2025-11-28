class Payment < ApplicationRecord
  belongs_to :athlete
  belongs_to :match
  belongs_to :transaction_category

  validates :amount, presence: true
  validates :status, presence: true, inclusion: { in: %w(pending paid) }

  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }

  def modality
    transaction_category&.name
  end

  def modality=(value)
    self.transaction_category = TransactionCategory.find_by(name: value)
  end
end
