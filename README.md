# StoreField - Nested fields for ActiveRecord::Store

Rails 3.2 introduced [ActiveRecord::Store](http://api.rubyonrails.org/classes/ActiveRecord/Store.html), which offers simple single-column key-value stores.

It's a nice feature, but its accessors are limited to primitive values (e.g. `String`, `Integer`, etc.) and it doesn't work out of the box if you want to store structured values. (e.g. `Hash`, `Set`, etc.)

Here's an example.

```ruby
class User < ActiveRecord::Base
  store :options, accessors: [ :tutorials, :preference ]
end

user = User.new
user.tutorials[:quick_start] = :visited     # => NoMethodError: undefined method `[]=' for nil:NilClass
```

There are two ways to solve this problem - a. break down `options` into multiple columns like `tutorials` and `preference`, or b. define an accessor method for each to initialize with an empty `Hash` when accessed for the first time.

The former is bad because the TEXT (or BLOB) column type could be stored off-page when it gets big and you could hit some [strange bugs and/or performance penalty](http://www.mysqlperformanceblog.com/2010/02/09/blob-storage-in-innodb/). Furthermore, adding columns kills the primary purpose of having key-value store - you use this feature because you don't like migrations, right? So it's two-fold bad.

StoreField takes the latter approach. It defines accessors that initialize with an empty `Hash` or `Set` automatically. Now you have a single TEXT column for everything!

## Usage

Add this line to your application's Gemfile.

```ruby
gem 'store_field'
```

Define `store_field` in a model class, following the `store` method.

```ruby
class User < ActiveRecord::Base
  store :storage
  store_field :tutorials
end
```

Now the previous example works perfectly.

```ruby
user = User.new
user.tutorials[:quick_start] = :finished
```

When no option is given, it defaults to the first serialized column, using the `Hash` datatype. So `store_field :tutorials` is equivalent to the following.

```ruby
store_field :tutorials, in: :storage, type: Hash
```

## Typing support for Set

In addition to `Hash`, StoreField supports the `Set` data type. To use Set, simply pass `type: Set` option.

It turns out that Set is extremely useful most of the time when you think what you need is `Array`.

```ruby
store_field :funnel, type: Set
```

It defines several utility methods - `set_[field]`, `unset_[field]`, `set_[field]?` and `unset_[field]?`.

```ruby
cart = Cart.new
cart.funnel                     # => #<Set: {}>
cart.set_funnel(:add_item)
cart.set_funnel(:checkout)
cart.set_funnel?(:checkout)     # => true
cart.funnel                     # => #<Set: {:add_item, :checkout}>
```

`set_[field]` and `unset_[field]` return `self`, so you can call `save` in chain.

```ruby
cart.set_funnel(:checkout).save!    # => true
```

Also you can enumerate acceptable values, which will be validated in the `set_[field]` method.

```ruby
store_field :funnel, type: Set, values: [ :add_item, :checkout ]
```

With the definition above, the following code will raise an exception.

```ruby
set_funnel(:bogus)  # => ArgumentError: :bogus is not allowed
```

## Use cases for the Set type

Set is a great way to store an arbitrary number of named states.

Consider you have a system that sends an alert when some criteria have been met.

```ruby
if user.bandwidth_usage > 250.megabytes
  Email.to user, message: 'Your data plan usage is nearing 300MB limit'
end
```

Depending on at what time the above code gets run (daily, hourly, etc.), email could be sent multiple times. To prevent duplicate alerts, you need to store the state in the database when one is successfully delivered.

```ruby
class User < ActiveRecord::Base
  store :storage
  store_field :delivered, type: Set
end

if user.bandwidth_usage > 250.megabytes and !user.set_delivered?(:nearing_limit)
  Email.to user, message: 'Your data plan usage is nearing 300MB limit'
  user.set_delivered(:nearing_limit).save
end
```

That way, the user won't receive the same alert again, until `unset_delivered` is called when the next billing cycle starts.

## YAML serialization

ActiveRecord::Store uses YAML to serialize Ruby objects. A StoreField will be stored as follows:

```yaml
---
:funnel: !ruby/object:Set
  hash:
    :add_item: true
    :checkout: true
```

As you can see, the `Set` class internally uses `Hash` for its storage.

There is a [known compatibility problem](http://bugs.ruby-lang.org/issues/6910) between `psych` and `syck`, be sure to use `psych` from the beginning.

```ruby
YAML::ENGINE.yamler     # => "psych"
```

If you are using Ruby 1.9.2 or later, `psych` should be used by default.

## Other Solutions

* [StoreConfigurable](https://github.com/metaskills/store_configurable) - A zero-configuration recursive Hash for storing a tree of options.

