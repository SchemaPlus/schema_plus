# Notice (2022-05-13)

This wrapper gem is no longer being updated. Please use the individual gems for the functionality you need.

# SchemaPlus family

The SchemaPlus family of gems provide various extensions and enhancements to ActiveRecord >= 4.2.  There are two varieties:

* **Gems that provide new default automatic behavior**

    These gems run with the spirit of DRY and convention over configuration -- and automatically take care of things for you.  Just include any of these gems and they'll get to work.

    Gem | Description 
    ----| ----------- 
    [schema_associations](https://github.com/SchemaPlus/schema_associations) | DRY up your models!  Why manually define associations (and their inverses) in the models, when you've already defined those relations in the database?
    [schema_auto_foreign_keys](https://github.com/SchemaPlus/schema_auto_foreign_keys) | DRY up your migrations!  It goes without saying that a foreign key relationship should have a foreign key constraint -- it should also go without typing.
    [schema_validations](https://github.com/SchemaPlus/schema_validations) | DRY up your validations!  The database has constraints in it, your models should automatically validate based on those constraints.

* **Gems that extend ActiveRecord's feature set**

    These gems provide new features and capabilities to ActiveRecord that you may wish to take advantage of.  None of these have default automagic; once you include the gem the new features are available, but you need to invoke them to use them.

    Gem | Description 
    ----| ----------- 
    [schema_plus_columns](https://github.com/SchemaPlus/schema_plus_columns) | Column attributes including `column.indexes` and `column.unique?`
    [schema_plus_db_default](https://github.com/SchemaPlus/schema_plus_db_default) | Use `ActiveRecord::DB_DEFAULT` to set an attribute to the database default
    [schema_plus_default_expr](https://github.com/SchemaPlus/schema_plus_default_expr)  | Use SQL expressions for database default values
    [schema_plus_enums](https://github.com/SchemaPlus/schema_plus_enums) | Define enum types in migrations
    [schema_plus_foreign_keys](https://github.com/SchemaPlus/schema_plus_foreign_keys) | Extended support for foreign keys, including creation as column options, `:deferrable`, and SQLite3 support
    [schema_plus_indexes](https://github.com/SchemaPlus/schema_plus_indexes) | Convenience and consistency in using indexes
    [schema_plus_multischema](https://github.com/SchemaPlus/schema_plus_multischema) | Support for using multiple PostgreSQL schemas in a single database
    [schema_plus_pg_indexes](https://github.com/SchemaPlus/schema_plus_pg_indexes) |PostgreSQL index features: `case_insensitive`, `expression` and `operator_class`
    [schema_plus_tables](https://github.com/SchemaPlus/schema_plus_tables) | Convenience and consistency in using tables
    [schema_plus_views](https://github.com/SchemaPlus/schema_plus_views) | Create and drop views in migrations

See detailed documentation in each gem's README.

*Is there some other capability you wish SchemaPlus had a gem for?*  Open an issue here. Or try implementing it yourself -- creating ActiveRecord extensions is easy and fun using SchemaPlus's tools [schema_monkey](https://github.com/SchemaPlus/schema_monkey) and [schema_plus_core](https://github.com/SchemaPlus/schema_plus_core)!!

---
# The `schema_plus` gem

[![Gem Version](https://badge.fury.io/rb/schema_plus.svg)](http://badge.fury.io/rb/schema_plus)
[![Build Status](https://secure.travis-ci.org/SchemaPlus/schema_plus.svg)](http://travis-ci.org/SchemaPlus/schema_plus)
[![Coverage Status](https://img.shields.io/coveralls/SchemaPlus/schema_plus.svg)](https://coveralls.io/r/SchemaPlus/schema_plus)
[![Dependency Status](https://gemnasium.com/lomba/schema_plus.svg)](https://gemnasium.com/SchemaPlus/schema_plus)

The `schema_plus` gem (v2.0) is a wrapper that pulls in a collection of gems from the SchemaPlus family.  For the most part we recommend skipping this gem and directly including the specific feature gems you're interested in using.

This wrapper is mostly provided for easy upgrade for those who were using schema_plus v1.8, which was a single monolothic gem.  This wrapper pulls in the gems that provide the same set of features and automatic behavior as the previous version:

* [schema_auto_foreign_keys](https://github.com/SchemaPlus/schema_auto_foreign_keys) 
* [schema_plus_columns](https://github.com/SchemaPlus/schema_plus_columns)     
* [schema_plus_db_default](https://github.com/SchemaPlus/schema_plus_db_default)
* [schema_plus_default_expr](https://github.com/SchemaPlus/schema_plus_default_expr)
* [schema_plus_enums](https://github.com/SchemaPlus/schema_plus_enums) 
* [schema_plus_foreign_keys](https://github.com/SchemaPlus/schema_plus_foreign_keys)
* [schema_plus_indexes](https://github.com/SchemaPlus/schema_plus_indexes)
* [schema_plus_pg_indexes](https://github.com/SchemaPlus/schema_plus_pg_indexes)
* [schema_plus_tables](https://github.com/SchemaPlus/schema_plus_tables)
* [schema_plus_views](https://github.com/SchemaPlus/schema_plus_views)

Note that the earlier version (1.x) supports earlier versions of ActiveRecord: 3.1, 4.0, 4.1, and 4.2.0.  For more info about that version, see the [schema_plus 1.x](https://github.com/SchemaPlus/schema_plus/tree/1.x) branch README.


### Upgrading from `schema_plus` 1.8.x

`schema_plus` 2.0 intends to be a completely backwards-compatible drop-in replacement for SchemaPlus 1.8.x, through restricted to ActiveRecord >= 4.2 and Ruby >= 2.1

If you find any incompatibilities, please report an issue!

#### Deprecations
In cases where ActiveRecord 4.2 has introduced features previously supported only by SchemaPlus, but using different names, the SchemaPlus 2.0 family of gems now issue deprecation warnings in favor of the rails form.  The complete list of deprecations:

* Index definition deprecates these options:
  * `:conditions` => `:where`
  * `:kind` => `:using`

* `drop_table` deprecates this option:
  * `cascade: true` => `force: :cascade`

* Foreign key definitions deprecate options to `:on_update` and `:on_delete`:
  * `:set_null` => `:nullify`

* `add_foreign_key` and `remove_foreign_key` deprecate the method signature:
  * `(from_table, columns, to_table, primary_keys, options)` => `(from_table, to_table, options)`

* `ForeignKeyDefinition` deprecates accessors:
  * `#table_name` in favor of `#from_table`
  * `#column_names` in favor of `Array.wrap(#column)`
  * `#references_column_names` in favor of `#primary_key`
  * `#references_table_name in favor of `#to_table`

* `IndexDefinition` deprecates accessors:
  * `#conditions` in favor of `#where`
  * `#kind` in favor of `#using.to_s`

## Compatibility

SchemaPlus 2.x is tested against all combinations of:

<!-- SCHEMA_DEV: MATRIX - begin -->
<!-- These lines are auto-generated by schema_dev based on schema_dev.yml -->
* ruby **2.1.5** with activerecord **4.2.0**, using **mysql2**, **sqlite3** or **postgresql**
* ruby **2.1.5** with activerecord **4.2.1**, using **mysql2**, **sqlite3** or **postgresql**

<!-- SCHEMA_DEV: MATRIX - end -->

## Installation

Install from http://rubygems.org via

    $ gem install "schema_plus"

or in a Gemfile

    gem "schema_plus"

## History

*   See [CHANGELOG](CHANGELOG.md) for per-version release notes.

*   SchemaPlus was originally derived from several "Red Hill On Rails" plugins created by [@harukizaemon](https://github.com/harukizaemon)

*   SchemaPlus was created in 2011 by [@mlomnicki](https://github.com/mlomnicki) and [@ronen](https://github.com/ronen)

*   And [lots of contributors](https://github.com/SchemaPlus/schema_plus/graphs/contributors) since then.

*   In 2015, the monolithic schema_plus gem was split into the SchemaPlus family of specific feature gems.
