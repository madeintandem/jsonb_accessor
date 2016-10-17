# JSONb Accessor

[![Gem Version](https://badge.fury.io/rb/jsonb_accessor.svg)](http://badge.fury.io/rb/jsonb_accessor) [![Build Status](https://travis-ci.org/devmynd/jsonb_accessor.svg)](https://travis-ci.org/devmynd/jsonb_accessor) 

Adds typed `jsonb` backed fields as first class citizens to your `ActiveRecord` models. This gem is similar in spirit to [HstoreAccessor](https://github.com/devmynd/hstore_accessor), but the `jsonb` column in PostgreSQL has a few distinct advantages, mostly around nested documents and support for collections.

## Table of Contents

* [Installation](#installation)
* [Rails 5](#rails-5)
* [Usage](#usage)
* [ActiveRecord Methods Generated for Fields](#activerecord-methods-generated-for-fields)
* [Validations](#validations)
* [Single-Table Inheritance](#single-table-inheritance)
* [Scopes](#scopes)
* [Migrations](#migrations)
* [Dependencies](#dependencies)
* [Development](#development)
* [Contributing](#contributing)

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem "jsonb_accessor"
```

And then execute:

    $ bundle install

## Rails 5

Version 0.4.X will run on Rails 5, but behavior around type coercion for array and other collection field types behaves differently. When you upgrade to 0.4.X make sure you do not depend on subtle type coercion rules.

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
    reviewed_at: :date_time
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

Because the underlying storage mechanism is JSON, we attempt to abide by the limitations of what can be represented natively. We use [ActiveRecord::Type](https://github.com/rails/rails/blob/master/activerecord/lib/active_record/type.rb) for seralization, but any type defined in the [Postgres connection adapter](https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql/oid.rb) will also be accepted. Beware of the impact of using complex Postgres column types such as inet, enum, hstore, etc... We plan to restrict which types are allowed in a future patch.

The following types are explicitly supported.

* big_integer
* binary
* boolean
* date
* date_time
* decimal
* float
* integer
* string
* text
* time
* value


Typed arrays are also supported by specifying `:type_array` (i.e. `:float_array`). `:array` is interpreted as an array of `value` types.

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

One of the big issues with `ActiveRecord` single-table inheritance (STI)
is sparse columns.  Essentially, as sub-types of the original table
diverge further from their parent more columns are left empty in a given
table.  Postgres' `jsonb` type provides part of the solution in that
the values in an `jsonb` column does not impose a structure - different
rows can have different values.

We set up our table with an `jsonb` field:

```ruby
# db/migration/<timestamp>_create_players_table.rb
class CreateVehiclesTable < ActiveRecord::Migration
  def change
    create_table :vehicles do |t|
      t.string :make
      t.string :model
      t.integer :model_year
      t.string :type
      t.jsonb :data
    end
  end
end
```

And for our models:

```ruby
# app/models/vehicle.rb
class Vehicle < ActiveRecord::Base
end

# app/models/vehicles/automobile.rb
class Automobile < Vehicle
  jsonb_accessor :data,
    axle_count: :integer,
    weight: :float
end

# app/models/vehicles/airplane.rb
class Airplane < Vehicle
  jsonb_accessor :data,
    engine_type: :string,
    safety_rating: :integer
end
```

From here any attributes specific to any sub-class can be stored in the
`jsonb` column avoiding sparse data.  Indices can also be created on
individual fields in an `jsonb` column.

This approach was originally concieved by Joe Hirn in [this blog
post](http://www.devmynd.com/blog/2013-3-single-table-inheritance-hstore-lovely-combination).

## Scopes

JsonbAccessor currently supports several scopes. Let's say we have a class that looks like this:

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor :data,
    approved: :boolean,
    name: :string,
    price: :integer,
    previous_prices: :integer_array,
    reviewed_at: :date_time
end
```

### General Scopes

#### `<jsonb_field>_contains`

**Description:** returns all records that contain matching attributes in the specified `jsonb` field. 

```ruby
product_1 = Product.create!(name: "foo", approved: true, reviewed_at: 3.days.ago)
product_2 = Product.create!(name: "bar", approved: true)
product_3 = Product.create!(name: "foo", approved: false)

Product.data_contains(name: "foo", approved: true) # => [product_1]
```

**Note:** when including an array attribute, the stored array and the array used for the query do not need to match exactly. For example, when queried with `[1, 2]`, records that have arrays of `[2, 1, 3]` will be returned. 

#### `with_<jsonb_defined_field>`

**Description:** returns all records with the given value in the field. This is defined for all `jsonb_accessor` defined fields. It's a convenience method that allows you to do `Product.with_name("foo")` instead of `Product.data_contains(name: "foo")`.

```ruby
product_1 = Product.create!(name: "foo")
product_2 = Product.create!(name: "bar")

Product.with_name("foo") # => [product_1]
```

**Note:** when including an array attribute, the stored array and the array used for the query do not need to match exactly. For example, when queried with `[1, 2]`, records that have arrays of `[2, 1, 3]` will be returned. 

### Integer, Big Integer, Decimal, and Float Scopes

#### `<jsonb_defined_field>_gt`

**Description:** returns all records with a value that is greater than the argument.

```ruby
product_1 = Product.create!(price: 10)
product_2 = Product.create!(price: 11)

Product.price_gt(10) # => [product_2]
```

#### `<jsonb_defined_field>_gte`

**Description:** returns all records with a value that is greater than or equal to the argument.

```ruby
product_1 = Product.create!(price: 10)
product_2 = Product.create!(price: 11)
product_3 = Product.create!(price: 9)

Product.price_gte(10) # => [product_1, product_2]
```

#### `<jsonb_defined_field>_lt`

**Description:** returns all records with a value that is less than the argument.

```ruby
product_1 = Product.create!(price: 10)
product_2 = Product.create!(price: 11)

Product.price_lt(11) # => [product_1]
```

#### `<jsonb_defined_field>_lte`

**Description:** returns all records with a value that is less than or equal to the argument.

```ruby
product_1 = Product.create!(price: 10)
product_2 = Product.create!(price: 11)
product_3 = Product.create!(price: 12)

Product.price_lte(11) # => [product_1, product_2]
```


### Boolean Scopes

#### `is_<jsonb_defined_field>`

**Description:** returns all records where the value is `true`.

```ruby
product_1 = Product.create!(approved: true)
product_2 = Product.create!(approved: false)

Product.is_approved # => [product_1]
```

#### `not_<jsonb_defined_field>`

**Description:** returns all records where the value is `false`.

```ruby
product_1 = Product.create!(approved: true)
product_2 = Product.create!(approved: false)

Product.not_approved # => [product_2]
```

### Date, DateTime Scopes

#### `<jsonb_defined_field>_before`

**Description:** returns all records where the value is before the argument. Also supports JSON string arguments.

```ruby
product_1 = Product.create!(reviewed_at: 3.days.ago)
product_2 = Product.create!(reviewed_at: 5.days.ago)

Product.reviewed_at_before(4.days.ago) # => [product_2]
Product.reviewed_at_before(4.days.ago.to_json) # => [product_2]
```

#### `<jsonb_defined_field>_after`

**Description:** returns all records where the value is after the argument. Also supports JSON string arguments.

```ruby
product_1 = Product.create!(reviewed_at: 3.days.from_now)
product_2 = Product.create!(reviewed_at: 5.days.from_now)

Product.reviewed_at_after(4.days.from_now) # => [product_2]
Product.reviewed_at_after(4.days.from_now.to_json) # => [product_2]
```

### Array Scopes

#### `<jsonb_defined_fields>_contains`

**Description:** returns all records where the value is contained in the array field.

```ruby
product_1 = Product.create!(previous_prices: [3])
product_2 = Product.create!(previous_prices: [4, 5, 6])

Product.previous_prices_contains(5) # => [product_2]
```

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
