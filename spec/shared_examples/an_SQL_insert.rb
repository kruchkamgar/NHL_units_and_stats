require_relative '../test_utilities.rb'

# compares the programmatically inserted records, with the input
shared_examples_for('an SQL insert') do # *1

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
          insert_queue_test_keys, #test-specific constants
          :itself
        ).
        values_at(*ends_and_randoms)
      )
  end
end


#*1-
# perhaps generate events for comparison [instead of comparing created/inserted with hashes], because other tests require created events also.
