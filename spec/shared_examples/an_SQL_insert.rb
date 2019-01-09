require_relative '../test_utilities.rb'

shared_examples_for('an SQL insert') do

  let(:ends_and_randoms) {
     get_random_and_end_indices(insert_queue) }

  it 'returns SQL-inserted events' do
      expect(
        get_hashes_array_sorted_values(
          inserted_records,
          test_keys,
          :attributes
        ).
        values_at(*ends_and_randoms)
      ).
      to eq(
        get_hashes_array_sorted_values(
          insert_queue,
          insert_queue_test_keys,
          :itself
        ).
        values_at(*ends_and_randoms)
      )
  end
end
