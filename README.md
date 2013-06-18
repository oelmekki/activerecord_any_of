# ActiverecordAnyOf

This method is inspired by [any_of from mongoid](http://two.mongoid.org/docs/querying/criteria.html#any_of).

It allows to compute an `OR` like query that leverages AR's `#where` syntax:

```ruby
users = User.any_of("email like '%@example.com'", {banned: true}).destroy_all
# DELETE FROM users WHERE email LIKE '%@example.com' OR banned = '1';
```

It can be used directly on model class, or through an association, or
behind an other relation.

```ruby
manual_removal = User.where(id: params[:users][:destroy_ids])
User.any_of(manual_removal, "email like '%@example.com'", {banned: true})
@company.users.any_of(manual_removal, "email like '%@example.com'", {banned: true})
User.where(offline: false).any_of( manual_removal, "email like '%@example.com'", {banned: true})
```

Its main purpose is to both :

* remove the need to write a sql string when we want an `OR`
* allows to write dynamic `OR` queries, which would be a pain with a string


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

What does this query do ? `where (email LIKE '%@example.com' AND active = '1' ) OR offline = '1'` ? Or `where email LIKE '%@example.com' AND ( active = '1' OR offline = '1' )` ? This can quickly get messy and counter intuitive.

The MongoId solution is quite elegant. Using `#any_of`, it is made clear which conditions are grouped through `OR` and which are grouped through `AND` : 

* `User.where( "email LIKE '%@example.com" ).any_of({ active: true }, { offline: true })`
* `fakes = User.where( "email LIKE '%@example.com'" ).where( active: true ); User.any_of( fakes, { offline: true })` 


## I want this in active_record

You can [say it there](https://github.com/rails/rails/pull/10891).


## Running test

```shell
# One time setup
cd test/dummy
rake db:migrate
rake db:test:prepare
cd ../..
# Then
rake test
```


## Pull requests

This gem is extracted from a pull request made to activerecord core, and
still hope to be merged. So, any pull request here should respects usual
[Rails contributing rules](http://guides.rubyonrails.org/contributing_to_ruby_on_rails.html#contributing-to-the-rails-code)
when it makes sense (especially : coding conventions) to make integration
in source pull request easy.


## Licence

MIT-LICENSE.
