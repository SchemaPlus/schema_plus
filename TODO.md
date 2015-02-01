## ALL

* ideally get rid of all uses of alias_method_chain outside schema_monkey (create middleware)

## schema_plus_tables

* depcrecate cascade: true in favor of force: cascade
* use middleware
* move specs over

## schema_plus_index
* remove index specs that are testing things now handled by AR.  (then see if coverage is still 100%)

## schema_plus_foreign_keys
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
* pull out schema_monkey_rails into its own gem

## general
* rename schema_pg_enum to just schema_enum?
* pull apart READMEs
* test each gem separately to make sure they don't accidentally depend on each other

## schema_dev things:

* boilerplate in README regarding installation, especially if schema_monkey_rails gets pulled out
* don't bother changing ruby if it's the current version anyway.
* have a .schema_dev file with current settings
  * make it obvious and easy to override
  * auto update .gitignore to ignore it?
