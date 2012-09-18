# StoreField - Nested fields for ActiveRecord::Store

Rails 3.2 introduced [ActiveRecord::Store](http://api.rubyonrails.org/classes/ActiveRecord/Store.html), which offers simple single-column key-value stores.

It's a nice feature, but what it offers is limited to accessors for primitive values (e.g. `String` or `Integer`) and if you want to store structured values (e.g. `Hash` or `Set`), it doesn't work out of the box.

Here's an example.

```ruby
class User < ActiveRecord::Base
  store :options, accessors: [ :tutorials, :preference ]
end

user = User.new
user.tutorials[:quick_start] = :visited     # => NoMethodError: undefined method `[]=' for nil:NilClass
```

There are two ways to solve this problem - a. break down `options` into multiple columns like `tutorials` and `caches`, or b. define an accessor method for each to initialize the default value with an empty `Hash`.

The former is bad because the TEXT (or BLOB) datatype is generally stored off-page and it already requires doubled random I/O, and adding more columns leads to poor performance. Also, adding columns kills the primary purpose of having key-value store - you use this feature because you don't like migrations, right? So it's two-fold bad.

StoreField uses the latter approach. It adds accessors that sets an empty `Hash` or `Set` when accessed for the first time.

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

When option is not given, it defaults to the first serialized column with `Hash` datatype. So `store_field :tutorials` is equivalent to the following.

```ruby
store_field :tutorials, in: :storage, type: Hash
```

## Set support

In addition to `Hash`, StoreField supports `Set` datatype. To use Set, simply pass `type: Set` option.

It turns out that Set is extremely useful most of the time when you think what you need is `Array`.

```ruby
store_field :funnel, type: Set
```

It defines some utility methods - `set_[field]`, `unset_[field]`, `set_[field]?` and `unset_[field]?`.

```ruby
cart = Cart.new
cart.funnel                     # => #<Set: {}>
cart.set_funnel(:add_item)
cart.set_funnel(:checkout)
cart.set_funnel?(:checkout)     # => true
cart.funnel                     # => #<Set: {:add_to_cart, :checkout}>
```

`set_[field]` and `unset_[field]` return `self`, so you can call `save` in chain.

```ruby
cart.set_funnel(:checkout).save!    # => true
```

## Use cases for Set type

Set is a great way to store an arbitrary number of states.

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
  store_field :notified, type: Set
end

if user.bandwidth_usage > 250.megabytes and !user.set_notified?(:nearing_limit)
  Email.to user, message: 'Your data plan usage is nearing 300MB limit'
  user.set_notified(:nearing_limit).save
end
```

That way, the user won't receive the same alert again, until `unset_notified` is called when the next billing cycle starts.
