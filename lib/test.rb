require 'byebug'
require_relative 'sql_object'
require_relative 'migrations'

create_users = Migration.new("users", {"name" => "VARCHAR(255) NOT NULL"})
create_users.run

class User < SQLObject

end

me = User.new("name" => "rafi").save

puts User.all[0].id
