# frozen_string_literal: true

class BlogPost < ActiveRecord::Base
  belongs_to :author, optional: true
  has_many :comments, dependent: :destroy
  accepts_nested_attributes_for :comments, allow_destroy: true

  validates_presence_of :title
  has_one_attached :contents

  def earnings_float
    earnings
  end

  def earnings_float=(value)
    self.earnings = value
  end
end