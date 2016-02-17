# require 'byebug'
require_relative 'sql_object'
require_relative 'migrations'
require_relative 'associatable'

# create_users = Migration.new("users", {"name" => "VARCHAR(255) NOT NULL"})
# create_users.run

class User < SQLObject
end

class Cat < SQLObject
  # debugger
  belongs_to :owner, foreign_key: :owner_id, class_name: "Human"

  finalize!
end


class Human < SQLObject
  self.table_name = 'humans'
end

debugger

1 + 1
# me = User.new("name" => "rand").save
#
# puts User.last.name
