# JSONb Accessor

Adds typed `jsonb` backed fields as first class citizens to your `ActiveRecord` models. This gem is similar in spirit to [HstoreAccessor](https://github.com/devmynd/hstore_accessor), but the `jsonb` column in PostgreSQL has a few distinct advantages, mostly around nested documents and support for collections.

**This gem is under heavy development. Please use cautiously and help us with feedback by opening issues for defects and feature requests. The current API is subject to change.**

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem "jsonb_accessor"
```

And then execute:

    $ bundle install

## Usage

First we must create a model which has a `jsonb` column available to store data into it:

```ruby
class CreateProductsTable < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.jsonb :options
    end
  end
end
```

We can then declare the `jsonb` fields we wish to expose via the accessor:

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor(
    :options,
    :count, # => value type
    title: :string,
    id_value: :value,
    external_id: :integer,
    reviewed_at: :datetime
  )
end
```

JSONb Accessor accepts both untyped and typed key definitions. Untyped keys are treated as-is and no additional casting is performed. This allows the freedom of dynamic values alongside the power types, which is especially convenient when saving nested form attributes. Typed keys will be cast to their respective values using the same mechanism ActiveRecord uses to coerce standard attribute columns. It's as close to a real column as you can get and the goal is to keep it that way.

All untyped keys must be defined prior to typed columns. You can declare a typed column with type `value` for explicit dynamic behavior. For reference, the `jsonb_accessor` macro is defined thusly.

```ruby
def jsonb_accessor(jsonb_attribute, *value_fields, **typed_fields)
  ...
end
```

There's quite a bit more to do do and document but we're excited to get this out there while we work on it some more.

## ActiveRecord Methods Generated for Fields

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor :data, field: :string
end
```

* `field`
* `field=`
* `field?`
* `field_changed?`
* `field_was`
* `field_change`
* `reset_field!`
* `restore_field!`
* `field_will_change!`

### Supported Types

The following types are supported, including typed collections:

```
:array,
:boolean,
:boolean_array,
:date,
:date_array,
:datetime,
:datetime_array,
:decimal,
:decimal_array,
:float,
:float_array,
:integer,
:integer_array,
:string,
:string_array,
:time,
:time_array,
:value
```

Support for nested types is also available but experimental at this point. If you must, you may try something like this for nested objects.

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor(
    :options,
    nested_object: { key: :integer }
  )
end

p = Product.new
p.nested_object.key = "10"
puts p.nested_object.key #=> 10
```

## Validations

Because this gem promotes attributes nested into the JSON column to first level attributes, most validations should just work. We still have to add some testing and support around this feature but feel free to try and leave us feedback if they're not working as expected.

## Single-Table Inheritance

You can use it for STI in the same spirit as [hstore_accessor, which documented here.](https://github.com/devmynd/hstore_accessor#single-table-inheritance).

## Scopes

Coming soon...

## Migrations

Coming soon...

`jsonb` supports `GIN`, `GIST`, `btree` and `hash` indexes over `json` column. We have plans to add migrations helpers for generating these indexes for you.

## Dependencies

- ActiveRecord 4.2
- Postgres 9.4 (in order to use the [jsonb column type](http://www.postgresql.org/docs/9.4/static/datatype-json.html)).

## Development

After checking out the repo, run `bin/setup` to install dependencies (make sure postgres is running first).

Run `bin/console` for an interactive prompt that will allow you to experiment.

`rake` will run Rubocop and the specs.

## Contributing

1. [Fork it](https://github.com/devmynd/jsonb_accessor/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Add tests and changes (run the tests with `rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
