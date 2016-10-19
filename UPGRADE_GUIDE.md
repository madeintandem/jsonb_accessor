# Upgrading from 0.X.X to 1.0.0

## Jsonb Accessor declaration

In 0.X.X you would write:

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor :data,
    :count, # doesn't specify a type
    title: :string,
    external_id: :integer,
    reviewed_at: :date_time, # snake cased
    previous_rankings: :integer_array, # `:type_array` key
    external_rankings: :array # plain array
end
```

In 1.0.0 you would write:

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor :data,
    count: :value, # all fields must specify a type
    title: :string,
    external_id: :integer,
    reviewed_at: :datetime, # `:date_time` is now `:datetime`
    previous_rankings: [:integer, array: true], # now just the type followed by `array: true`
    external_rankings: [:value, array: true] # now the value type is specified as well as `array: true`
end
```

There are several important differences. All fields must now specify a type, `:date_time` is now `:datetime`, and arrays are specified using a type and `array: true` instead of `type_array`.

Also, in order to use the `value` type you need to register it:

```ruby
# in an initializer
ActiveRecord::Type.register(:value, ActiveRecord::Type::Value)
```

### Deeply nested objects

In 0.X.X you could write:

```ruby
class Product < ActiveRecord::Base
  jsonb_accessor :data,
    ranking_info: {
      original_rank: integer,
      current_rank: integer,
      metadata: {
        ranked_on: :date
      }
    }
end
```

Which would allow you to use getter and setter methods at any point in the structure.

```ruby
Product.new(ranking_info: { original_rank: 3, current_rank: 5, metadata: { ranked_on: Date.today } })
product.ranking_info.original_rank # 3
product.ranking_info.metadata.ranked_on # Date.today
```

1.0.0 does not support this syntax. If you need these sort of methods, you can create your own type `class` and register it with `ActiveRecord::Type`. [Here's an example](http://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute).
