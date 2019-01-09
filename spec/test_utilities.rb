
def get_random_and_end_indices (array, iteration_count=5)
  x = Random.new(1)
  array_size = array.size
  values = [0, array_size-1] # always include first and last
  iteration_count.times do
   values << (x.rand(array_size-2)+1)
  end
  values
end

def get_hashes_array_sorted_values (array_of_hashes, keys_array, method)
  array_of_hashes.
  map do |evt|
    evt.send(method).
    select do |key|
      keys_array.include? key
    end.
    values.
    sort do |a, b|
      a.to_s <=> b.to_s end
  end
end
