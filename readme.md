# RubyRM
RubyRM uses object-relational mapping to allow your ruby classes (Models) to persist. It interfaces with sqlite3 to save your changes to a database. It is inspired by Rails' ActiveRecord.

## Setup

##### Initial setup
To use this project, clone it to your projects folder. Your project goes in the `./lib` folder. You may remove the spec folder, or replace the current specs with specs specific for your project. The included specs will fail once the default `./data.db` and `./data.sql` files are updated with your preferences.

Run bundle to install the required gems. (You may need to use rbenv for this to work)

##### Verifying your version
Before beginning to develop your project, it's recommended you run the specs once to ensure the project is working.

If you are using a newer version of ruby than that specified in the gemfile, you must use rbenv, `rbenv exec bundle exec rspec`, otherwise simply run `bundle exec rspec`.

All 45 examples should pass.

##### Resetting the database
The database included in this project contains test data for the specs. to remove it simply delete the contents of `./data.sql`. If you decide you want to rename the database files, you must go into `RubyRM/db_connection` and change line 6 and 7 accordingly.

##### Running your first migration
In `migrations/setup.rb`, an example migration shows you the basics of creating a table. Migrations work in two ways:

1. Create:
  ``` ruby
  Migration.new(table_name, { column_name_1: type_1, column_name_2: type_2 }))
  ```
  - The first argument is the table's name. It should be plural (eg. users).
  - The second argument is a hash, with column name, column type pairs. Use standard SQL column types (eg. INTEGER, VARCHAR(255)).
  - Your arguments should be input as strings.
2. Drop:
  ``` ruby
  Migration.new(table_name, "delete")
  ```

After you've created a migration, all you need to do is call `run` on it, and it will create or drop your table.

Run `rb setub.rb` in your terminal to finish this setup and run the migrations. Any future migrations should be run in the same way. Add a new file to the migrations folder, and then run that file in your terminal once you've written your migrations.

## Writing your Models
Writing a model is easy. In the lib folder, there's an example file already made for you. Follow that style and you'll be golden. Always use finalize at the end of your model definitions. It's how RubyRM knows to connect your ruby class with a table in the database.

***note:*** *if you are having trouble, your class name may not be easily pluralized. In this case, use the function RubyRM::table_name= to manually set the name of the table you wish to connect with in the db.*

## Getting Models from your database
This is the meat of RubyRM, the whole reason you'd ever want to use this. Now that you have a table in your database, you probably want to put stuff in it.

##### Adding to your DB
``` ruby
Ship.new({name: "Millennium Falcon", pilot_id: 4}).save
```

##### Updating
``` ruby
ship = Ship.find(1)
ship.update({name: "Millennium Eagle"})
```

##### Other methods
- `first`
- `last`
- `find(id)`
- `all`
- `table_name`
- `columns`
- `attributes`

## Associating models

These associations allow you to call methods on your class and retrieve related class objects from the database. As a rule, the foreign_key is the table column in the other class's table, not the class you are writing the association in. This is not always the case, but should get you started.

##### belongs_to
The following are options for belongs_to:
- relation_name
- :foreign_key,
- :class_name,
- :primary_key

An example:
``` ruby
belongs_to :relation_name, foreign_key: :item_id, class_name: "Class", primary_key: :id
```

A ship belongs to a pilot:
``` ruby
class Ship < RubyRM
  belongs_to :pilot, foreign_key: :pilot_id

  finalize!
end
```

##### has_many
The following are options for has_many:
- relation_name
- :foreign_key,
- :class_name,
- :primary_key

A rank has many pilots:
``` ruby
class Rank < RubyRM
  has_many :pilots, foreign_key: :rank_id

  finalize!
end
```

##### has_one_through
`has_one_through(name, through_name, source_name)`
- *name* is the name of the method
- *through_name* is the method (association) you will travel through
- *source_name* is the method in that associated class that you want to call

``` ruby
class Pilot
  belongs_to :rank
  finalize!
end

class Ship
  belongs_to :pilot
  has_one_through :rank, :pilot, :rank

  self.finalize!
end
```
