# ActiverecordAnyOf

This gem provides `#any_of` and `#none_of` on ActiveRecord.

`#any_of` is inspired by [any_of from mongoid](http://two.mongoid.org/docs/querying/criteria.html#any_of).

It allows to compute an `OR` like query that leverages AR's `#where` syntax:

```ruby
users = User.where.any_of("email like '%@example.com'", {banned: true}).destroy_all
# DELETE FROM users WHERE email LIKE '%@example.com' OR banned = '1';
```

It can be used anywhere `#where` is valid :

```ruby
manual_removal = User.where(id: params[:users][:destroy_ids])
User.where.any_of(manual_removal, "email like '%@example.com'", {banned: true})
@company.users.where.any_of(manual_removal, "email like '%@example.com'", {banned: true})
User.where(offline: false).where.any_of( manual_removal, "email like '%@example.com'", {banned: true})
```

Its main purpose is to both :

* remove the need to write a sql string when we want an `OR`
* allows to write dynamic `OR` queries, which would be a pain with a string

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
