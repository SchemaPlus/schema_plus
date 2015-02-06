## ALL

* ideally get rid of all uses of alias_method_chain outside schema_monkey (create middleware)

## schema_plus_tables

* depcrecate cascade: true in favor of force: cascade
* use middleware
* move specs over

## schema_plus_index
* remove index specs that are testing things now handled by AR.  (then see if coverage is still 100%)

## schema_plus_pg_index
* pull over recent 1.8 fix for expression

## schema_plus_foreign_keys
* add specs to cover the deprecations
* just do fk enhancements rather than replace AR's add_foreign_key and remove_foreign_key methods and foreign key lookups
* pull over knojoot's failing spec & solution for circular fk dumping problems from 1.x branch.

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

## general
* rename schema_pg_enum to just schema_enum?
* pull apart READMEs
* test each gem separately to make sure they don't accidentally depend on each other

## schema_dev things:

* boilerplate in README regarding installation
* initial schema_dev shouldn't include ruby 1.9.3
* create initial Gemfile.local, move byebug into it
* use 'gem' instead of 'spec' in gemfile
* figure out why Gemfile.local is being read twice?
* don't bother changing ruby if it's the current version anyway.
* have a .schema_dev file with current settings
  * make it obvious and easy to override
  * auto update .gitignore to ignore it?
