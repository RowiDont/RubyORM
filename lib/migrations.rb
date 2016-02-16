
require_relative 'db_connection'

class Migration
  attr_reader :name, :columns

  def initialize(table_name, options = {})
    @name = table_name
    @columns = options
  end

  def run
    if @columns == "delete"
      this.drop
    else
      this.create
    end
  end

  def create
    cols = @columns.keys.map do |col_name|
      "#{col_name} #{@columns[col_name].upcase}"
    end
    cols.unshift("id INTEGER PRIMARY KEY")

    cols = cols.join(", ")


    DBConnection.execute(<<-SQL)
      CREATE TABLE
        #{self.name}(
        #{cols}
      );
    SQL
  end

  def drop
    DBConnection.execute(<<-SQL)
      DROP TABLE
        #{self.name}
    SQL
  end

end
