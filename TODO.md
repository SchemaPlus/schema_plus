## ALL

* ideally get rid of all uses of alias_method_chain outside schema_monkey (create middleware)

## schema_index_plus
* remove index specs that are testing things now handled by AR.  (then see if coverage is still 100%)
* shift pg enahancement to a separate schema_pg_index(?)
* dumper: don't output multiple t.index for the same column
* rename this to schema_plus_index?

## schema_foreign_keys
* move fk stuff into schema_foreign_keys

## schema_plus
* deprecate config => SchemaForeignKeys config

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

* boilerplate in README regarding the schema_plus family
* boilerplate in README regarding test matrix
* default 'rspec'
* don't bother changing rails if it's the current version anyway.
* rename 'refresh' to 'freshen'; get rid of the individual travis & gem commands
* have a .schema_dev file with current settings (make it obvious and easy
* to override) (auto update .gitignore to ignore it?)
* log files should go in log/ not in tmp/ (auto update .gitignore to ignore it?)
