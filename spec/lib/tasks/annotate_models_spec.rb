require_relative '../../spec_helper'

describe 'Annotate annotate_models rake task and Annotate.set_defaults' do # rubocop:disable RSpec/DescribeClass
  before do
    Rake.application = Rake::Application.new
    Rake::Task.define_task('environment')
    Rake.load_rakefile('tasks/annotate_models.rake')
  end

  after do
    Annotate.instance_variable_set('@has_set_defaults', false)
  end

  let(:annotate_models_argument) do
    argument = nil
    allow(AnnotateModels).to receive(:do_annotations) { |arg| argument = arg }
    Rake::Task['annotate_models'].invoke
    argument
  end

  describe 'with_comment_column' do
    subject { annotate_models_argument[:with_comment_column] }

    after { ENV.delete('with_comment_column') }

    context 'when Annotate.set_defaults is not called (defaults)' do
      it { is_expected.to be_falsey }
    end

    context 'when Annotate.set_defaults sets it to "true"' do
      before { Annotate.set_defaults('with_comment_column' => 'true') }

      it { is_expected.to be_truthy }
    end
  end

  context 'when column_type is frozen' do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'users'
      end
    end

    before do
      allow(klass).to receive(:columns).and_return([
        instance_double('Column', name: 'id', type: 'integer'.freeze, sql_type: 'integer', limit: nil, null: false, default: nil, comment: nil)
      ])
      allow(klass).to receive(:table_exists?).and_return(true)
      allow(klass).to receive(:primary_key).and_return('id')
    end

    it 'does not raise an error when modifying column_type' do
      expect { AnnotateModels.get_schema_info(klass, 'Schema Info', {}) }.not_to raise_error
    end

    it 'includes the column information in the schema info' do
      schema_info = AnnotateModels.get_schema_info(klass, 'Schema Info', {})
      expect(schema_info).to include('id :integer')
    end
  end
end
