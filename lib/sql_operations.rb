

module SQLOperations

  # standardized bulk sql insert method
  def sql_insert_all (table, data_hash)
    insert_values = data_hash
    .map do |hash|
      values_string = "'#{hash.values.join('\',\'')}'"
      if hash.values.count(nil) > 0
        values_string.gsub(/''/, 'NULL')
      else values_string end
    end
      # 'value','value','value' --of type String

    fields = data_hash.first.keys.map(&:to_s)
    # "VALUES (CSV string1),(string2),(string3)...

    sql_events = <<~SQL
      INSERT INTO #{table} (#{fields.join(',')} )
      VALUES ( #{insert_values.join('),(')} )
      RETURNING *
    SQL
    begin
      returning = ApplicationRecord.connection.execute(sql_events)
    rescue StandardError => e
      puts "\n\n error: \n\n #{e}"
    end
    # postgresql--
    returning.count
    # sqlite3--
    # ApplicationRecord.connection.execute("SELECT Changes()").first["Changes()"]
  end
  # upgrade to Active-Import?

  module_function :sql_insert_all

end
