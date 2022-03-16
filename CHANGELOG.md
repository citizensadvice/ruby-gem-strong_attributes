# Change log

## v0.0.12

- Inspect will truncate long string and escape dates

## v0.0.11

- Nested and array attributes now take `initial_value` rather than `default`
- Do not set a default value using a proc if the getter returns anything but nil

## v0.0.10

- Changed the initialization order so default values are set after the attributes are set

## v0.0.9

- Added the `replace` option to `nested_attributes`
- Fix support for `primary_key` and allow for a false value
- Fix array attribute supporting changes in place
- Remove the `param_name` option.
- `nested_array_attributes` will name anonymous classes using singular names

## v0.0.8

- Add an attributes setter

## v0.0.7

- Fixed confusing error message for an unknown setter
- Fixed name of class on inline definitions
- Support `mark_for_destruction`
- Add `replace` option to `nested_array_attributes`
