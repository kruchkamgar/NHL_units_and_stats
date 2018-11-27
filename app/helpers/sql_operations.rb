module SQLOperations

  # standardized bulk sql insert method
  def sql_insert_all (table, data_hash)
    insert_values = data_hash.map {
        |hash| "'#{hash.values.join('\',\'')}'"
      }

    fields = data_hash.first.keys.map(&:to_s)
    # "VALUES (CSV string1),(string2),(string3)...
    sql_events = "INSERT INTO #{table} (#{fields.join(',')} )
    VALUES ( #{insert_values.join('),(')} )"
    begin
      ApplicationRecord.connection.execute(sql_events)
    rescue StandardError => e
      puts "\n\n error: \n\n #{e}"
    end
    # if updates to database occurred (inserts)
    # if ApplicationRecord.connection.execute("SELECT Changes()").first["changes()"] == 1
    #   # ...
    # end

    ApplicationRecord.connection.execute("SELECT Changes()").first["Changes()"]
  end
  # upgrade to Active-Import?

  module_function :sql_insert_all

end
