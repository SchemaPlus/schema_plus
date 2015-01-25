## ALL

* ideally get rid of all uses of alias_method_chain outside schema_monkey (create middleware)
* rename everything to schema_plus_* (except schema_monkey and schema_plus)

## schema_plus_tables

* depcrecate cascade: true in favor of force: cascade
* use middleware
* move specs over


## schema_plus_index
* remove index specs that are testing things now handled by AR.  (then see if coverage is still 100%)
* shift pg enahancement to a separate schema_pg_index(?)
* dumper: don't output multiple t.index for the same column
* rename this to schema_plus_index?

## schema_plus
* deprecate config => SchemaForeignKeys config
* move fk stuff into schema_foreign_keys
* add specs to cover the deprecations
* just do fk enhancements rather than replace AR's add_foreign_key and remove_foreign_key methods and foreign key lookups

## schema_monkey
* consider automating the autoloads
* make middleware for remove_index
* make middleware for remove_column
* make middleware for rename_table
* make middleware for create_table
* make middleware for visit_TableDefinition
* make middleware for loading a schema
* make middleware for defining a table
* make ExecCache middleware work for all three adapters.
* @dump should include the header for consistency
* specs for schema_monkey
* README to document it -- the conventions and internal API
* (try it on AR 4.1?  nah)

## general
* rename schema_pg_enum to just schema_enum?
* pull apart READMEs
* test each gem separately to make sure they don't accidentally depend on each other

## schema_dev things:

* boilerplate in README regarding the schema_plus family?
* boilerplate in README regarding test matrix?
* default 'rspec'
* don't bother changing ruby if it's the current version anyway.
* rename 'refresh' to 'freshen'; get rid of the individual travis & gem commands
* have a .schema_dev file with current settings
  * make it obvious and easy to override
  * auto update .gitignore to ignore it?
* log files should go in log/ not in tmp/ (auto update .gitignore to ignore it?)
