# JSONb Accessor

Created by &nbsp;&nbsp;&nbsp; [<img src="https://raw.githubusercontent.com/madeintandem/jsonb_accessor/master/tandem-logo.png" alt="Tandem Logo" />](https://www.madeintandem.com/)

[![Gem Version](https://badge.fury.io/rb/jsonb_accessor.svg)](http://badge.fury.io/rb/jsonb_accessor) &nbsp;&nbsp;&nbsp;![CI](https://github.com/madeintandem/jsonb_accessor/actions/workflows/ci.yml/badge.svg) <img src="https://raw.githubusercontent.com/madeintandem/jsonb_accessor/master/json-bee.png" alt="JSONb Accessor Logo" align="right" />

Adds typed `jsonb` backed fields as first class citizens to your `ActiveRecord` models. This gem is similar in spirit to [HstoreAccessor](https://github.com/madeintandem/hstore_accessor), but the `jsonb` column in PostgreSQL has a few distinct advantages, mostly around nested documents and support for collections.

It also adds generic scopes for querying `jsonb` columns.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Scopes](#scopes)
- [Single-Table Inheritance](#single-table-inheritance)
- [Dependencies](#dependencies)
- [Validations](#validations)
- [Upgrading](#upgrading)
- [Development](#development)
- [Contributing](#contributing)

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
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.jsonb :data
    end
  end
end
```

We can then declare the `jsonb` fields we wish to expose via the accessor:

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor :data,
    title: :string,
    external_id: :integer,
    reviewed_at: :datetime
end
```

Any type the [`attribute` API](http://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute) supports. You can also implement your own type by following the example in the `attribute` documentation.

To pass through options like `default` and `array` to the `attribute` API, just put them in an array.

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor :data,
    title: [:string, default: "Untitled"],
    previous_titles: [:string, array: true, default: []]
end
```

The `default` option works pretty much as you would expect in practice; if no values are set for the attributes, a hash of the specified default values is saved to the jsonb column.

You can also pass in a `store_key` option.

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor :data, title: [:string, store_key: :t]
end
```

This allows you to use `title` for your getters and setters, but use `t` as the key in the `jsonb` column.

```ruby
product = Product.new(title: "Foo")
product.title #=> "Foo"
product.data #=> { "t" => "Foo" }
```

## Scopes

Jsonb Accessor provides several scopes to make it easier to query `jsonb` columns. `jsonb_contains`, `jsonb_number_where`, `jsonb_time_where`, and `jsonb_where` are available on all `ActiveRecord::Base` subclasses and don't require that you make use of the `jsonb_accessor` declaration.

If a class does have a `jsonb_accessor` declaration, then we define one custom scope. So, let's say we have a class that looks like this:

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor :data,
    name: :string,
    price: [:integer, store_key: :p],
    price_in_cents: :integer,
    reviewed_at: :datetime
end
```

Jsonb Accessor will add a `scope` to `Product` called like the json column with `_where` suffix, in our case `data_where`.

```ruby
Product.all.data_where(name: "Granite Towel", price: 17)
```

Similarly, it will also add a `data_where_not` `scope` to `Product`.

```ruby
Product.all.data_where_not(name: "Plasma Fork")
```

For number fields you can query using `<` or `>`or use plain english if that's what you prefer.

```ruby
Product.all.data_where(price: { <: 15 })
Product.all.data_where(price: { <=: 15 })
Product.all.data_where(price: { less_than: 15 })
Product.all.data_where(price: { less_than_or_equal_to: 15 })

Product.all.data_where(price: { >: 15 })
Product.all.data_where(price: { >=: 15 })
Product.all.data_where(price: { greater_than: 15 })
Product.all.data_where(price: { greater_than_or_equal_to: 15 })

Product.all.data_where(price: { greater_than: 15, less_than: 30 })
```

For time related fields you can query using `before` and `after`.

```ruby
Product.all.data_where(reviewed_at: { before: Time.current.beginning_of_week, after: 4.weeks.ago })
```

If you want to search for records within a certain time, date, or number range, just pass in the range (Note: this is just shorthand for the above mentioned `before`/`after`/`less_than`/`less_than_or_equal_to`/`greater_than_or_equal_to`/etc options).

```ruby
Product.all.data_where(price: 10..20)
Product.all.data_where(price: 10...20)
Product.all.data_where(reviewed_at: Time.current..3.days.from_now)
```

This scope is a convenient wrapper around the `jsonb_where` `scope` that saves you from having to convert the given keys to the store keys and from specifying the column.

### `jsonb_where`

Works just like the [`scope` above](#scopes) except that it does not convert the given keys to store keys and you must specify the column name. For example:

```ruby
Product.all.jsonb_where(:data, reviewed_at: { before: Time.current }, p: { greater_than: 5 })

# instead of

Product.all.data_where(reviewed_at: { before: Time.current }, price: { greater_than: 5 })
```

This scope makes use of the `jsonb_contains`, `jsonb_number_where`, and `jsonb_time_where` `scope`s.

### `jsonb_where_not`

Just the opposite of `jsonb_where`. Note that this will automatically exclude all records that contain `null` in their jsonb column (the `data` column, in the example below).

```ruby
Product.all.jsonb_where_not(:data, reviewed_at: { before: Time.current }, p: { greater_than: 5 })
```

### `<jsonb_attribute>_order`

Orders your query according to values in the Jsonb Accessor fields similar to ActiveRecord's `order`.

```ruby
Product.all.data_order(:price)
Product.all.data_order(:price, :reviewed_at)
Product.all.data_order(:price, reviewed_at: :desc)
```

It will convert your given keys into store keys if necessary.

### `jsonb_order`

Allows you to order by a Jsonb Accessor field.

```ruby
Product.all.jsonb_order(:data, :price, :asc)
Product.all.jsonb_order(:data, :price, :desc)
```

### `jsonb_contains`

Returns all records that contain the given JSON paths.

```ruby
Product.all.jsonb_contains(:data, title: "foo")
Product.all.jsonb_contains(:data, reviewed_at: 10.minutes.ago, p: 12) # Using the store key
```

**Note:** Under the hood, `jsonb_contains` uses the [`@>` operator in Postgres](https://www.postgresql.org/docs/9.5/static/functions-json.html) so when you include an array query, the stored array and the array used for the query do not need to match exactly. For example, when queried with `[1, 2]`, records that have arrays of `[2, 1, 3]` will be returned.

### `jsonb_excludes`

Returns all records that exclude the given JSON paths. Pretty much the opposite of `jsonb_contains`. Note that this will automatically exclude all records that contain `null` in their jsonb column (the `data` column, in the example below).

```ruby
Product.all.jsonb_excludes(:data, title: "foo")
Product.all.jsonb_excludes(:data, reviewed_at: 10.minutes.ago, p: 12) # Using the store key
```

### `jsonb_number_where`

Returns all records that match the given criteria.

```ruby
Product.all.jsonb_number_where(:data, :price_in_cents, :greater_than, 300)
```

It supports:

- `>`
- `>=`
- `greater_than`
- `greater_than_or_equal_to`
- `<`
- `<=`
- `less_than`
- `less_than_or_equal_to`

and it is indifferent to strings/symbols.

### `jsonb_number_where_not`

Returns all records that do not match the given criteria. It's the opposite of `jsonb_number_where`. Note that this will automatically exclude all records that contain `null` in their jsonb column (the `data` column, in the example below).

```ruby
Product.all.jsonb_number_where_not(:data, :price_in_cents, :greater_than, 300)
```

### `jsonb_time_where`

Returns all records that match the given criteria.

```ruby
Product.all.jsonb_time_where(:data, :reviewed_at, :before, 2.days.ago)
```

It supports `before` and `after` and is indifferent to strings/symbols.

### `jsonb_time_where_not`

Returns all records that match the given criteria. The opposite of `jsonb_time_where`. Note that this will automatically exclude all records that contain `null` in their jsonb column (the `data` column, in the example below).

```ruby
Product.all.jsonb_time_where_not(:data, :reviewed_at, :before, 2.days.ago)
```

## Single-Table Inheritance

One of the big issues with `ActiveRecord` single-table inheritance (STI)
is sparse columns. Essentially, as sub-types of the original table
diverge further from their parent more columns are left empty in a given
table. Postgres' `jsonb` type provides part of the solution in that
the values in an `jsonb` column does not impose a structure - different
rows can have different values.

We set up our table with an `jsonb` field:

```ruby
# db/migration/<timestamp>_create_players.rb
class CreateVehicles < ActiveRecord::Migration
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
`jsonb` column avoiding sparse data. Indices can also be created on
individual fields in an `jsonb` column.

This approach was originally conceived by Joe Hirn in [this blog
post](https://madeintandem.com/blog/2013-3-single-table-inheritance-hstore-lovely-combination/).

## Validations

Because this gem promotes attributes nested into the JSON column to first level attributes, most validations should just work. Please leave us feedback if they're not working as expected.

## Dependencies

- ActiveRecord >= 5.0
- Postgres >= 9.4 (in order to use the [jsonb column type](http://www.postgresql.org/docs/9.4/static/datatype-json.html)).

## Upgrading

See the [upgrade guide](UPGRADE_GUIDE.md).

## Development

### On your local machine

After checking out the repo, run `bin/setup` to install dependencies (make sure postgres is running first).

Run `bin/console` for an interactive prompt that will allow you to experiment.

`rake` will run Rubocop and the specs.

### With Docker

```
# setup
docker-compose build
docker-compose run ruby rake db:migrate
# run test suite
docker-compose run ruby rake spec
```

## Contributing

1. [Fork it](https://github.com/madeintandem/jsonb_accessor/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Add tests and changes (run the tests with `rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
