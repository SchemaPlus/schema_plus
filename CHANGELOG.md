# SchemaPlus

## Change Log

### 1.5.1

* Now respects ActiveRecord::SchemaDumper.ignore_tables for views (issue #153)

### 1.5.0
* Can now be used with activerecord standalone, doesn't need all of rails.
* `views` ignores postgres internal views, thanks to [@everplays](https://github.com/everplays) (issue #147)

### 1.4.1

* Bug fixes `migration.add_references` with `polymophic: true` (issue #145 and others)

### 1.4.0

* Supports jruby & mysql, thanks to [@rzenha](https://github.com/razenha)
* Works with MRI ruby & rails 4.1.0beta3
* Run tests against MRI 2.1.0

### 1.3.3

* Bug fix, dump unique index with expression (Issue #142)


### 1.3.2

* Bug fix, remove_index with if_exists but no name
* Sort indexes alphabetically when dumping, like rails does

### 1.3.1

* Regression bug fix, non-option arguemnts to remove_index

### 1.3.0

* Added :if_exists option for remove_index
* Initial jruby support (rails 3.2, postgresql), due to efforts of [@donv](https://github.com/donv)
* Preliminatry groundwork for rails 4.1, due to efforts of [@tovodeverett](https://github.com/tovodeverett)
* Bug fix for change_table
* Bug fix for schema_dump postgresql non-btree indexes
* Bug fix regarding expressions that cast non-string columns to strings in a lower()

### 1.2.0
*   Now works with rails 4, due to efforts of [@tovodeverett](https://github.com/tovodeverett)
*   Test against MRI ruby 2.0.0, no longer test against 1.9.2

### 1.1.2
*   Now works with rails 3.2.13 (fixed railtie initialization)

### 1.1.1

*   Dependency constraint to rails 3.2.12 max, since schema_plus doesn't
    currently work with 3.2.13.rc2

### 1.1.0

*   Add support for drop_table :cascade => true.  Note that until now,
    :cascade was implicitly true.  So this change might break existing code
    that relied on the incorrect implicit cascade behavior.
*   Add support for :deferrable => :initially_deferred (thanks to
    [@bhavinkamani](https://github.com/bhavinkamani))
*   Works with PostGIS (thanks to [@pete](https://github.com/pete))
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
