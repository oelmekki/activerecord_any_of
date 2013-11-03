# ActiverecordAnyOf

## A note for < 1.2 users

There was a lot of confusion about explit/implicit hash parameter notation,
with people expecting this to generate an OR query :

```ruby
User.where.any_of(name: 'Doe', active: true)
```

This wouldn't work, since there is only one parameter, here : `{name: 'Doe', active: true}`,
so there's a single group of condition that is joined as a AND. To achieve
expected result, this should have been used :

```ruby
User.where.any_of({name: 'Doe'}, {active: true})
```

  
To be true to principle of least surprise, we now automatically expand
parameters consisting of a single Hash as a hash for each key, so first
query will indeed generate :

```ruby
User.where.any_of(name: 'Doe', active: true)
# => SELECT * FROM users WHERE name = 'Doe' OR active = '1'
```


Grouping conditions can still be achieved using explicit curly brackets :

```ruby
User.where.any_of({first_name: 'John', last_name: 'Doe'}, active: true)
# => SELECT * FROM users WHERE (first_name = 'John' AND last_name = 'Doe') OR active = '1'
```


## Introduction

This gem provides `#any_of` and `#none_of` on ActiveRecord.

`#any_of` is inspired by [any_of from mongoid](http://two.mongoid.org/docs/querying/criteria.html#any_of).

Its main purpose is to both :

* remove the need to write a sql string when we want an `OR`
* allows to write dynamic `OR` queries, which would be a pain with a string


## Usage

### `#any_of`

It allows to compute an `OR` like query that leverages AR's `#where` syntax:

```ruby
User.where.any_of(first_name: 'Joe', last_name: 'Joe')
# => SELECT * FROM users WHERE first_name = 'Joe' OR last_name = 'Joe'
```


You can separate sets of hash condition by explicitly group them as hashes :

```ruby
User.where.any_of({first_name: 'John', last_name: 'Joe'}, {first_name: 'Simon', last_name: 'Joe'})
# => SELECT * FROM users WHERE ( first_name = 'John' AND last_name = 'Joe' ) OR ( first_name = 'Simon' AND last_name = 'Joe' )
```


Each `#any_of` set is the same kind you would have passed to #where :

```ruby
Client.where.any_of("orders_count = '2'", ["name = ?", 'Joe'], {email: 'joe@example.com'})
```


You can as well pass `#any_of` to other relations :

```ruby
Client.where("orders_count = '2'").any_of({ email: 'joe@example.com' }, { email: 'john@example.com' })
```


And with associations :

```ruby
User.find(1).posts.any_of({published: false}, "user_id IS NULL")
```


The best part is that `#any_of` accepts other relations as parameter, to help compute
dynamic `OR` queries :

```ruby
banned_users = User.where(banned: true)
unconfirmed_users = User.where("confirmed_at IS NULL")
inactive_users = User.any_of(banned_users, unconfirmed_users)
```

### `#none_of`

`#none_of` is the negative version of `#any_of`. This will return all active users :

```ruby
banned_users = User.where(banned: true)
unconfirmed_users = User.where("confirmed_at IS NULL")
active_users = User.where.none_of(banned_users, unconfirmed_users)
```

## Rails-3

`activerecord_any_of` uses WhereChain, which has been introduced in rails-4. In
rails-3, simply call `#any_of` and `#none_of` directly, without using `#where` :

```ruby
manual_removal = User.where(id: params[:users][:destroy_ids])
User.any_of(manual_removal, "email like '%@example.com'", {banned: true})
@company.users.any_of(manual_removal, "email like '%@example.com'", {banned: true})
User.where(offline: false).any_of( manual_removal, "email like '%@example.com'", {banned: true})
```

## Installation

In your Gemfile :

```
gem 'activerecord_any_of'
```

Activerecord_any_of supports rails >= 3.2.13 and rails-4 (let me know if tests
pass for rails < 3.2.13, I may edit gem dependencies).


## Why not an `#or` method instead ?

```ruby
User.where( "email LIKE '%@example.com" ).where( active: true ).or( offline: true )
```

What does this query do ? `where (email LIKE '%@example.com' AND active = '1' )
OR offline = '1'` ? Or `where email LIKE '%@example.com' AND ( active = '1' OR
offline = '1' )` ? This can quickly get messy and counter intuitive.

The MongoId solution is quite elegant. Using `#any_of`, it is made clear which
conditions are grouped through `OR` and which are grouped through `AND` : 

* `User.where( "email LIKE '%@example.com" ).any_of({ active: true }, { offline: true })`
* `fakes = User.where( "email LIKE '%@example.com'" ).where( active: true ); User.any_of( fakes, { offline: true })` 


## I want this in active_record

You can [say it there](https://github.com/rails/rails/pull/10891).


## Running test

Activerecord_any_of allows to run tests against both rails-3 and rails-4. You
have to run them seperately, but it's ok to use the same directory / machine to
run both.

### Running tests with rails-4

```shell
# One time setup
bundle install --gemfile Gemfile.rails4
cd test/dummy_rails4
BUNDLE_GEMFILE=../../Gemfile.rails4 bundle exec rake db:migrate
BUNDLE_GEMFILE=../../Gemfile.rails4 bundle exec rake db:test:prepare
cd ../..

# Then
bundle exec rake test
```

### Running tests with rails-3

```shell
# One time setup
bundle install --gemfile Gemfile.rails3
cd test/dummy_rails3
BUNDLE_GEMFILE=../../Gemfile.rails3 bundle exec rake db:migrate
BUNDLE_GEMFILE=../../Gemfile.rails3 bundle exec rake db:test:prepare
cd ../..

# Then
RAILS_VERSION=3 bundle exec rake test
```


## Pull requests

This gem is extracted from a pull request made to activerecord core, and
still hope to be merged. So, any pull request here should respects usual
[Rails contributing rules](http://guides.rubyonrails.org/contributing_to_ruby_on_rails.html#contributing-to-the-rails-code)
when it makes sense (especially : coding conventions) to make integration
in source pull request easy.


## Licence

MIT-LICENSE.
