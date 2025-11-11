# frozen_string_literal: true

class Comment < ActiveRecord::Base
  belongs_to :blog_post
  validates :txt, presence: true
end