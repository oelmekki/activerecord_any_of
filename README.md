# ActiverecordAnyOf

## Introduction

This gem provides `#any_of` and `#none_of` on ActiveRecord.

`#any_of` is inspired by [any_of from mongoid](http://two.mongoid.org/docs/querying/criteria.html#any_of).

It was released before `#or` was implemented in ActiveRecord. Its main purpose was to both :

* remove the need to write a sql string when we want an `OR`
* allows to write dynamic `OR` queries, which would be a pain with a string

It can still be useful today given the various ways you can call it. While
ActiveRecord's `#or` only accepts relations, you can pass to `#any_of` and
`#none_of` the same kind of conditions you would pass to `#where`:


```ruby
User.where.any_of({ active: true }, ['offline = ?', required_status], 'posts_count > 0')
```

And you can still use relations, like AR's `#or`:

```ruby
inactive_users = User.not_activated
offline_users = User.offline

User.where.any_of(inactive_users, offline)
```

## Installation

In your Gemfile :

```
gem 'activerecord_any_of'
```

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
User.where.any_of({ first_name: 'John', last_name: 'Joe' }, { first_name: 'Simon', last_name: 'Joe' })
# => SELECT * FROM users WHERE ( first_name = 'John' AND last_name = 'Joe' ) OR ( first_name = 'Simon' AND last_name = 'Joe' )
```

#### it's plain #where syntax

Each `#any_of` set is the same kind you would have passed to #where :

```ruby
Client.where.any_of("orders_count = '2'", ["name = ?", 'Joe'], { email: 'joe@example.com' })
```

#### with relations

You can as well pass `#any_of` to other relations :

```ruby
Client.where("orders_count = '2'").where.any_of({ email: 'joe@example.com' }, { email: 'john@example.com' })
```

#### with associations

And with associations :

```ruby
User.find(1).posts.where.any_of({ published: false }, 'user_id IS NULL')
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
unconfirmed_users = User.where('confirmed_at IS NULL')
active_users = User.where.none_of(banned_users, unconfirmed_users)
```
