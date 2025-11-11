# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Mapping
  RSpec.describe PackAPI::Querying::ComposableQuery, type: :model do
    let!(:joined_model) { Class.new(ActiveRecord::Base) { self.table_name = 'joined_models' } }
    let!(:test_model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'test_models'
      end
    end

    before(:all) do
      ActiveRecord::Base.connection.create_table :joined_models do |t|
        t.string :joined_name
      end
      ActiveRecord::Base.connection.create_table :test_models do |t|
        t.string :name
        t.bigint :joined_model_id
      end
    end

    after(:all) do
      ActiveRecord::Base.connection.drop_table :test_models
      ActiveRecord::Base.connection.drop_table :joined_models
    end

    describe '#add' do
      let(:query) { described_class.new(test_model.all) }

      it 'can add where clauses' do
        # given
        test_model.create!(name: 'foo')

        # when
        query.add(test_model.where(name: 'foo'))

        # then
        result = query.build.to_a
        expect(result).to have(1).item
      end

      it 'can add join clauses and dependent where clauses' do
        # given
        bar = joined_model.create!(joined_name: 'bar')
        test_model.create!(name: 'foo', joined_model_id: bar.id)
        # when
        query.add(test_model.joins("JOIN joined_models on joined_models.id = test_models.joined_model_id")
                            .where("joined_models.joined_name = 'bar'"))

        # then
        result = query.build.to_a
        expect(result).to have(1).item
      end

      it 'can add output names to final result' do
        # given
        test_model.create!(name: 'foo')

        # when
        query.add(test_model.select('id baz'))

        # then
        result = query.build.to_a
        expect(result).to have(1).items
        result_baz = result.pluck(:baz)
        expect(result_baz).not_to be_nil
      end
    end
  end
end
