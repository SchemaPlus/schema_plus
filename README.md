


# SchemaPlus family

The SchemaPlus family of gems provide various extensions and enhancements to ActiveRecord.  

Listed alphabetically:

Gem | Description | Included In `schema_plus` gem?
----| ----------- |:------------------------------:
[schema_associations](https://github.com/SchemaPlus/schema_associations) | Automatically defines model associations based on foreign key relations |
<p style="color:grey">schema_auto_foreign_keys</p> | Automatically creates foreign keys on referencing columns | Y
[schema_plus_columns](https://github.com/SchemaPlus/schema_plus_columns) | Column attributes including `column.indexes` and `column.unique?` | Y
[schema_plus_db_default](https://github.com/SchemaPlus/schema_plus_db_default) | Use `ActiveRecord::DB_DEFAULT` to set an attribute to the database default | Y
[schema_plus_default_expr](https://github.com/SchemaPlus/schema_plus_default_expr)  | Use SQL expressions for database default values | Y
[schema_plus_enums](https://github.com/SchemaPlus/schema_plus_enums) | Define enum types in migrations | Y
[schema_plus_foreign_keys](https://github.com/SchemaPlus/schema_plus_foreign_keys) | Extended support for foreign keys, including creation as column options, `:deferrable`, and SQLite3 support | Y
[schema_plus_indexes](https://github.com/SchemaPlus/schema_plus_indexes) | Convenience and consistency in using indexes | Y
[schema_plus_pg_indexes](https://github.com/SchemaPlus/schema_plus_pg_indexes) |PostgreSQL index features: `case_insenstive`, `expression` and `operator_class` | Y
[schema_plus_tables](https://github.com/SchemaPlus/schema_plus_tables) | Convenience and consistency in using tables | Y
[schema_plus_views](https://github.com/SchemaPlus/schema_plus_views) | Create and drop views in migrations | Y
[schema_validations](https://github.com/SchemaPlus/schema_validations) | Automatically defines ActiveRecord validations based on database constraints |

See detailed documentation in each gem's README.

*Is there some other capability you wish SchemaPlus had a gem for?*  Open an issue here. Or try implementing it yourself -- creating ActiveRecord extensions is easy and fun using SchemaPlus's tools [schema_monkey](https://github.com/SchemaPlus/schema_monkey) and [schema_plus_core](https://github.com/SchemaPlus/schema_plus_core)!!

---
# The `schema_plus` gem

[![Gem Version](https://badge.fury.io/rb/schema_plus.svg)](http://badge.fury.io/rb/schema_plus)
[![Build Status](https://secure.travis-ci.org/SchemaPlus/schema_plus.svg)](http://travis-ci.org/SchemaPlus/schema_plus)
[![Coverage Status](https://img.shields.io/coveralls/SchemaPlus/schema_plus.svg)](https://coveralls.io/r/SchemaPlus/schema_plus)
[![Dependency Status](https://gemnasium.com/lomba/schema_plus.svg)](https://gemnasium.com/SchemaPlus/schema_plus)


> ## This is the README for schema_plus 2.0.0.pre16
> which supports Rails >= 4.2.0.  This prerelease is completely usable. It's still officially a prerelease rather than formal release because some features have yet to be migrated into their own gems.
>  
> For info about the 1.x releases which support Rails 3.1, 4.0, 4.1, and 4.2.0, see the [schema_plus 1.x](https://github.com/SchemaPlus/schema_plus/tree/1.x) branch

---


The `schema_plus` gem is a wrapper that pulls in a common collection of gems from the SchemaPlus family.   But you can feel free to ignore this gem and mix and match to get just the gems you want.

Note: Prior to version 2.0, `schema_plus` was a single monolothic gem that implemented in itself all the features that are now included by the wrapper.


> **IN PROGRESS:** In the prerelease versions of SchemaPlus 2.0, some features have yet to be migrated out to their own gems, and their code is still in the body of schema_plus.  Those gems are greyed out in the list above.  The documentation for their features is at the end of this README.


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

---
---

# Prerelease:  Documentation of features still be moved into separate feature gems


### Auto Foreign Key Constraints

SchemaPlus adds support for the common convention that you name a column
with suffix `_id` to indicate that it's a foreign key, SchemaPlus
automatically defines the appropriate constraint.

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

