# ActiverecordAnyOf


## Hey, want to take over?

These days, I write less and less ruby and more and more golang. I will
continue to maintain this project, because there are people using it (don't
worry, I won't let you down!).

That being said I would love if someone could take over. Please let me know in
[that issue](https://github.com/oelmekki/activerecord_any_of/issues/38) if you're interested.

## Introduction

This gem provides `#any_of` and `#none_of` on ActiveRecord.

`#any_of` is inspired by [any_of from mongoid](http://two.mongoid.org/docs/querying/criteria.html#any_of).

Its main purpose is to both :

* remove the need to write a sql string when we want an `OR`
* allows to write dynamic `OR` queries, which would be a pain with a string


## Usage

### `#any_of`

It allows to compute an `OR` like query that leverages AR's `#where` syntax:


#### basics

```ruby
User.where.any_of(first_name: 'Joe', last_name: 'Joe')
# => SELECT * FROM users WHERE first_name = 'Joe' OR last_name = 'Joe'
```


#### grouped conditions

You can separate sets of hash condition by explicitly group them as hashes :

```ruby
User.where.any_of({first_name: 'John', last_name: 'Joe'}, {first_name: 'Simon', last_name: 'Joe'})
# => SELECT * FROM users WHERE ( first_name = 'John' AND last_name = 'Joe' ) OR ( first_name = 'Simon' AND last_name = 'Joe' )
```


#### it's plain #where syntax

Each `#any_of` set is the same kind you would have passed to #where :

```ruby
Client.where.any_of("orders_count = '2'", ["name = ?", 'Joe'], {email: 'joe@example.com'})
```


#### with relations

You can as well pass `#any_of` to other relations :

```ruby
Client.where("orders_count = '2'").where.any_of({ email: 'joe@example.com' }, { email: 'john@example.com' })
```


#### with associations

And with associations :

```ruby
User.find(1).posts.where.any_of({published: false}, "user_id IS NULL")
```


#### dynamic OR queries

The best part is that `#any_of` accepts other relations as parameter, to help compute
dynamic `OR` queries :

```ruby
banned_users = User.where(banned: true)
unconfirmed_users = User.where("confirmed_at IS NULL")
inactive_users = User.where.any_of(banned_users, unconfirmed_users)
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

* `User.where( "email LIKE '%@example.com" ).where.any_of({ active: true }, { offline: true })`
* `fakes = User.where( "email LIKE '%@example.com'" ).where( active: true ); User.where.any_of( fakes, { offline: true })`


## Running test

Testing is done using TravisCI. You can use the wonderful [wwtd gem](https://github.com/grosser/wwtd) to run all tests locally. By default, the task to run is `bundle exec rake spec`, and will run against `sqlite3` in memory. You can change the database like so: `DB=postgresql bundle exec rake spec`. Please note that you may need to change the credentials for your database in the `database.yml` file. *Do not commit those changes.*

## Pull requests

This gem is extracted from a pull request made to activerecord core, and
still hope to be merged. So, any pull request here should respects usual
[Rails contributing rules](http://guides.rubyonrails.org/contributing_to_ruby_on_rails.html#contributing-to-the-rails-code)
when it makes sense (especially : coding conventions) to make integration
in source pull request easy.


## Licence

MIT-LICENSE.
