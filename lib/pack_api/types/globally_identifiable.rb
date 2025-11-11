# frozen_string_literal: true

module PackAPI::Types
  module GloballyIdentifiable
    extend ActiveSupport::Concern

    class_methods do
      def make_gid(model_id)
        GlobalID.new(URI::GID.build(app: GlobalID.app, model_name: name, model_id: model_id))
      end
    end

    included do
      def gid
        @gid ||= self.class.make_gid(id)
      end
    end
  end
end
