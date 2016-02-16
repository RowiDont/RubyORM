require_relative 'db_connection'
require_relative 'sql_object'

module Searchable

  def where(params)
    values = []
    columns = []
    params.each do |column, value|
      columns << "#{column} = ?"
      values << value
    end
    columns = columns.join(" AND ")

    results = DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{columns}
    SQL
    self.parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
