## schema_index_plus
* use middleware to look up enhanced postgresql index options
* move index definition additions to schema_index_plus
* move AR::Base.indexes into schema_index_plus
* pull out the index specs
* remove index specs that are testing things now handled by AR.  (then see if coverage is still 100%)
* shift pg enahancement to a separate schema_pg_index(?)
* dumper: don't output multiple t.index for the same column

## schema_foreign_keys
* move ColumnOptionsHandler entirely into middleware (no need to include it elsewhere)
* move fk stuff into schema_plus_fk

## schema_plus
* deprecate config => SchemaForeignKeys config


## schema_monkey
* consider automating the autoloads
* make middleware for loading a schema
* make middleware for defining a table
* make a way to insert middleware for just a specific adapter
* specs for schema_monkey
* (try it on AR 4.1?  nah)

## general
* rename schema_pg_enum to just schema_enum?
* pull apart READMEs

## schema_dev things:

* boilerplate in README regarding the schema_plus family
* boilerplate in README regarding test matrix
* default 'rspec'
* don't bother changing rails if it's the current version anyway.
