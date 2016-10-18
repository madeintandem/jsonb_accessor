# JSONb Accessor

[![Gem Version](https://badge.fury.io/rb/jsonb_accessor.svg)](http://badge.fury.io/rb/jsonb_accessor) [![Build Status](https://travis-ci.org/devmynd/jsonb_accessor.svg)](https://travis-ci.org/devmynd/jsonb_accessor)

Adds typed `jsonb` backed fields as first class citizens to your `ActiveRecord` models. This gem is similar in spirit to [HstoreAccessor](https://github.com/devmynd/hstore_accessor), but the `jsonb` column in PostgreSQL has a few distinct advantages, mostly around nested documents and support for collections.

## Table of Contents

* [Installation](#installation)
* [Usage](#usage)
* [Validations](#validations)
* [Single-Table Inheritance](#single-table-inheritance)
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
    title: :string,
    id_value: :value,
    external_id: :integer,
    reviewed_at: :datetime
  )
end
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

## Dependencies

- ActiveRecord 5.0
- Ruby >= 2.2.2
- Postgres >= 9.4 (in order to use the [jsonb column type](http://www.postgresql.org/docs/9.4/static/datatype-json.html)).

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
