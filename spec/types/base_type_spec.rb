# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Types
  RSpec.describe BaseType, type: :model do

    describe 'inherited' do
      it 'preserves the base class optional attributes on derived class' do
        expect(CoAuthorType.optional_attributes).to include(:blog_posts)
      end
    end
  end
end
