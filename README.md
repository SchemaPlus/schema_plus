# SchemaPlus

SchemaPlus is an ActiveRecord extension that provides enhanced capabilities
for schema definition and querying, including: enhanced and more DRY index
capabilities, support and automation for foreign key constraints, and support
for views.

For added rails DRYness see also the gems
[schema_associations](http://rubygems.org/gems/schema_associations) and
[schema_validations](http://rubygems.org/gems/schema_validations)

[<img
src="https://secure.travis-ci.org/lomba/schema_plus.png"/>](http://travis-ci.o
rg/lomba/schema_plus) [<img src="https://gemnasium.com/lomba/schema_plus.png"
alt="Dependency Status" />](https://gemnasium.com/lomba/schema_plus)

## Compatibility

SchemaPlus supports all combinations of:
*   rails 3.2
*   PostgreSQL, MySQL (using mysql or mysql2 gem), or SQLite3 (using sqlite3
    3.7.7 which has foreign key support)
*   MRI ruby 1.9.2 or 1.9.3


Note: As of version 1.0.0, SchemaPlus no longer supports rails 2.3, 3.0 and
3.1 and ruby 1.8.7.  The last version to support them was 0.4.1.

## Installation

Install from http://rubygems.org via

    $ gem install "schema_plus"

or in a Gemfile

    gem "schema_plus"

## Features

Here some examples that show off the high points.  For full details see the
[RDoc documentation](http://rubydoc.info/gems/schema_plus).

### Indexes

With standard rails migrations, you specify indexes separately from the table
definition:

    # Standard Rails approach...
    create_table :parts do |t|
      t.string :name
      t.string :product_code
    end

    add_index :parts, :name     # index repeats table and column names and is defined separately
    add_index :parts, :product_code, unique: true

But with SchemaPlus you can specify your indexes when you define each column,
with options as desired

    # More DRY way...
    create_table :parts do |t|
      t.string :name,           index: true
      t.string :product_code,   index: { unique: true }
    end

The options hash can include an index name:

    t.string :product_code,     index: { unique: true, name: "my_index_name" }

You can also create multi-column indexes, for example:

    t.string :first_name
    t.string :last_name,        index: { with: :first_name }

    t.string :country_code
    t.string :area_code
    t.string :local_number      index: { with: [:country_code, :area_code], unique: true }

And you can specify index orders:

    t.string :first_name
    t.string :last_name,        index: { with: :first_name, order: { first_name: :desc, last_name: :asc}}

As a convenient shorthand, the :unique option can be specified as

    t.string :product_code,   index: :unique

which is equivalent to

    t.string :product_code,   index: { unique: true }

If you're using Postgresql, SchemaPlus provides support for conditions,
expressions, index methods, and case-insensitive indexes:

    t.string :last_name,  index: { conditions: 'deleted_at IS NULL' }
    t.string :last_name,  index: { expression: 'upper(last_name)' }
    t.string :last_name,  index: { kind: 'hash' }
    t.string :last_name,  index: { case_sensitive: false }        # shorthand for expression: 'lower(last_name)'

These features are available also in ActiveRecord::Migration.add_index.  See
doc at SchemaPlus::ActiveRecord::ConnectionAdapters::PostgresqlAdapter and
SchemaPlus::ActiveRecord::ConnectionAdapters::IndexDefinition

When you query column information using ActiveRecord::Base#columns, SchemaPlus
analogously provides index information relevant to each column: which indexes
reference the column, whether the column must be unique, etc.  See doc at
SchemaPlus::ActiveRecord::ConnectionAdapters::Column

SchemaPlus also tidies some index-related behavior:

*   Rails' various db adapters have inconsistent behavior regarding an attempt
    to create a duplicate index: some quietly ignore the attempt, some raise
    an error.   SchemaPlus regularizes the behavor to ignore the attempt for
    all db adapters.

*   If you rename a table, indexes named using rails' automatic naming
    convention will be renamed correspondingly.


### Foreign Key Constraints

SchemaPlus adds support for foreign key constraints. In fact, for the common
convention that you name a column with suffix `_id` to indicate that it's a
foreign key, SchemaPlus automatically defines the appropriate constraint.

SchemaPlus also creates foreign key constraints for rails' `t.references` or
`t.belongs_to`, which take the singular of the referenced table name and
implicitly create the column suffixed with `_id`.

You can explicitly specify whether or not to generate a foreign key
constraint, and specify or override automatic options, using the
`:foreign_key` keyword

Here are some examples:

    t.integer :author_id                              # automatically references table 'authors', key id
    t.integer :parent_id                              # special name parent_id automatically references its own table (for tree nodes)
    t.integer :author_id, foreign_key: true           # same as default automatic behavior
    t.integer :author,    foreign_key: true           # non-conventional column name needs to force creation, table name is assumed to be 'authors'
    t.integer :author_id, foreign_key: false          # don't create a constraint

    t.integer :author_id, foreign_key: { references: :authors }        # same as automatic behavior
    t.integer :author,    foreign_key: { reference: :authors}          # same default name
    t.integer :author_id, foreign_key: { references: [:authors, :id] } # same as automatic behavior
    t.integer :author_id, foreign_key: { references: :people }         # override table name
    t.integer :author_id, foreign_key: { references: [:people, :ssn] } # override table name and key
    t.integer :author_id, foreign_key: { references: nil }             # don't create a constraint
    t.integer :author_id, foreign_key: { name: "my_fk" }               # override default generated constraint name
    t.integer :author_id, foreign_key: { on_delete: :cascade }
    t.integer :author_id, foreign_key: { on_update: :set_null }
    t.integer :author_id, foreign_key: { deferrable: true }
    t.integer :author_id, foreign_key: { deferrable: :initially_deferred }

Of course the options can be combined, e.g.

    t.integer :author_id, foreign_key: { name: "my_fk", on_delete: :no_action }

As a shorthand, all options except `:name` can be specified without placing
them in a hash, e.g.

    t.integer :author_id, on_delete: :cascade
    t.integer :author_id, references: nil

The foreign key behavior can be configured globally (see Config) or per-table
(see create_table).

To examine your foreign key constraints, `connection.foreign_keys` returns a
list of foreign key constraints defined for a given table, and
`connection.reverse_foreign_keys` returns a list of foreign key constraints
that reference a given table.  See
SchemaPlus::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.

### Tables

SchemaPlus extends rails' `drop_table` method to accept these options:

    drop_table :table_name                    # same as rails
    drop_table :table_name, if_exists: true   # no error if table doesn't exist
    drop_table :table_name, cascade: true     # delete dependencies

The `:cascade` option is particularly useful given foreign key constraints. 
For Postgresql it is implemented using `DROP TABLE...CASCADE` which deletes
all dependencies.  For MySQL, SchemaPlus implements the `:cascade` option to
delete foreign key references, but does not delete any other dependencies. 
For Sqlite3, the `:cascade` option is ignored, but Sqlite3 always drops tables
with cascade-like behavior.

SchemaPlus likewise extends `create_table ... force: true` to use `:cascade`

### Views

SchemaPlus provides support for creating and dropping views.  In a migration,
a view can be created using a rails relation or literal sql:

    create_view :posts_commented_by_staff,  Post.joins(comment: user).where(users: {role: 'staff'}).uniq
    create_view :uncommented_posts,        "SELECT * FROM posts LEFT OUTER JOIN comments ON comments.post_id = posts.id WHERE comments.id IS NULL"

And can be dropped:

    drop_view :posts_commented_by_staff
    drop_view :uncommented_posts

ActiveRecord works with views the same as with ordinary tables.  That is, for
the above views you can define

    class PostCommentedByStaff < ActiveRecord::Base
      table_name = "posts_commented_by_staff"
    end

    class UncommentedPost < ActiveRecord::Base
    end

### Column Defaults: Expressions

SchemaPlus allows defaults to be set using expressions or constant values:

    t.datetime :seen_at, default: { expr: 'NOW()' }
    t.datetime :seen_at, default: { value: "2011-12-11 00:00:00" }

Note that in MySQL only the TIMESTAMP column data type accepts SQL column
defaults and Rails uses DATETIME, so expressions can't be used with MySQL.

The standard syntax will still work as usual:

    t.datetime :seen_at, default: "2011-12-11 00:00:00"

Also, as a convenience

    t.datetime :seen_at, default: :now

resolves to:

    NOW()                 # PostgreSQL
    (DATETIME('now'))     # SQLite3
    invalid               # MySQL

### Column Defaults: Using

SchemaPlus introduces a constant `ActiveRecord::DB_DEFAULT` that you can use
to explicitly instruct the database to use the column default value (or
expression).  For example:

    Post.create(category: ActiveRecord::DB_DEFAULT)
    post.update_attributes(category: ActiveRecord::DB_DEFAULT)

(Without `ActiveRecord::DB_DEFAULT`, you can update a value to `NULL` but not
to its default value.) 

Note that after updating, you would need to reload a record to replace
`ActiveRecord::DB_DEFAULT` with the value assigned by the database.

Note also that Sqlite3 does not support `ActiveRecord::DB_DEFAULT`; attempting
to use it will raise `ActiveRecord::StatementInvalid`

### Schema Dump and Load (schema.rb)

When dumping `schema.rb`, SchemaPlus orders the views and tables in the schema
dump alphabetically, but subject to the requirement that each table or view be
defined before those that depend on it.  This allows all foreign key
constraints to be defined within the scope of the table definition. (Unless
there are cyclical dependencies, in which case some foreign keys constraints
must be defined later.)

Also, when dumping `schema.rb`, SchemaPlus dumps explicit foreign key
definition statements rather than relying on the auto-creation behavior, for
maximum clarity and for independence from global config.  And correspondingly,
when loading a schema, i.e. with the context of `ActiveRecord::Schema.define`,
SchemaPlus ensures that auto creation of foreign key constraints is turned off
regardless of the global setting.  But if for some reason you are creating
your schema.rb file by hand, and would like to take advantage of auto-creation
of foreign key constraints, you can re-enable it:

    ActiveRecord::Schema.define do
        SchemaPlus.config.foreign_keys.auto_create = true
        SchemaPlus.config.foreign_keys.auto_index = true

        create_table ...etc...
    end

## Release notes:

### 1.1.0

*   Add support for drop_table :cascade => true.  Note that until now,
    :cascade was implicitly true.  So this change might break existing code
    that relied on the incorrect implicit cascade behavior.
*   Add support for :deferrable => :initially_deferred (thanks to
    [@bhavinkamani](https://github.com/bhavinkamani))
*   Bug fix: Circular Reference/Stack Level Too Deep in Column#to_json. 
    Thanks to [@robdimarco](https://github.com/robdimarco) for tracking down the problem
*   Bug fix: More robust handling of foreign keys with schema namespaces


### 1.0.1

*   README cleanups (thanks to [@denispeplin](https://github.com/denispeplin))
*   Now raises ArgumentError if index has both :case_sensitive => false and an
    :expression
*   Now creates consistent default name for foreign key constraints
*   Bug fix: respect :length keyword for index (thanks to [@teleological](https://github.com/teleological))
*   Bug fix: renaming table with multiple foreign key constraints (thanks to
    [@teleological](https://github.com/teleological))
*   Bug fix: don't dump :case_sensitive => false for index with an expression
    that includes "lower(name)".
*   Bug fix: Properly dump multi-column case-insensitive indexes


### 1.0.0

*   No longer support rails < 3.2 and ruby < 1.9
*   New feature: specify foreign key constraints using :foreign_key => { ...
    }, motivated in particular to support :name (suggested by [@daniele-m](https://github.com/daniele-m))
*   New feature: create view using ActiveRecord relation
*   New feature: `ActiveRecord::DB_DEFAULT` (suggested by
    [@zaadjis](https://github.com/zaadjis))
*   New feature: renaming a table renames its indexes and constraints
    correspondingly.
*   Bug fix for postgres :kind index attribute (thanks to [@eugenebolshakov](https://github.com/eugenebolshakov))
*   Sort fks in dump for stability (thanks to [@zephyr-dev](https://github.com/zephyr-dev))
*   Bug fix: change_column should maintain foreign key constraints even when
    config.foreign_keys.auto_create is false
*   Bug fix: quote default expressions in schema dump (thanks to [@jonleighton](https://github.com/jonleighton))
*   Bug fix: when removing a foreign key constraint, remove its auto-generated
    index.
*   Bug fix: SchemaDumper.ignore_tables needs to support regexps (suggested by
    [@mtalcott](https://github.com/mtalcott))
*   Bug fix: More robust handling of Postgresql schema_search path (suggested
    by [@mtalcott](https://github.com/mtalcott))
*   Bug fix: Only get index, view, and foreign key information from current
    schema (thanks to [@bhavinkamani](https://github.com/bhavinkamani))


### Earlier releases
*   0.4.1 - Bug fix: don't attempt foreign key creation for t.belongs_to ...
    :polymorphic => true
*   0.4.0 - Add :force for create_view (suggested by [@greglazarev](https://github.com/greglazarev)).  cleanups
    by [@betelgeuse](https://github.com/betelgeuse)
*   0.3.4 - Bug fix: regression causing :default => false to be ignored
*   0.3.3 - Bug fix: properly handle boolean defaults in mysql
*   0.3.2 - Bug fix: make sure rake db:schema:load initializes schema_plus 
*   0.3.1 - Bug fix for PostgreSQL schema dump after change_column_default(...
    nil)
*   0.3.0 - Add :default => expressions (Thanks to Luke Saunders).  support
    rails 3.2 and ruby 1.9.3
*   0.2.1 - Suppress duplicate add_indexes.  compatibility with rails
    3.2.0.rc2


## History

*   SchemaPlus is derived from several "Red Hill On Rails" plugins originally
    created by [@harukizaemon](https://github.com/harukizaemon)

*   SchemaPlus was created in 2011 by [@mlomnicki](https://github.com/mlomnicki) and [@ronen](https://github.com/ronen)

*   And [lots of
    contributors](https://github.com/lomba/schema_plus/graphs/contributors)
    since then

