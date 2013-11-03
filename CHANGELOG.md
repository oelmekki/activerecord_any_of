# Changelog

## 1.2 - November 03, 2013

* Automatically expand single parameter hash ([#13](https://github.com/oelmekki/activerecord_any_of/issues/13))

  There was a lot of confusion about explit/implicit hash parameter notation,
  with people expecting this to generate an OR query :

    User.where.any_of(name: 'Doe', active: true)

  This wouldn't work, since there is only one parameter, here : `{name: 'Doe', active: true}`,
  so there's a single group of condition that is joined as a AND. To achieve
  expected result, this should have been used :

    User.where.any_of({name: 'Doe'}, {active: true})
    
  To be true to principle of least surprise, we now automatically expand
  parameters consisting of a single Hash as a hash for each key, so first
  query will indeed generate :

    User.where.any_of(name: 'Doe', active: true)
    # => SELECT * FROM users WHERE name = 'Doe' OR active = '1'


  Grouping conditions can still be achieved using explicit curly brackets :

    User.where.any_of({first_name: 'John', last_name: 'Doe'}, active: true)
    # => SELECT * FROM users WHERE (first_name = 'John' AND last_name = 'Doe') OR active = '1'


## 1.1 - August 31, 2013

* use WhereChain in rails-4 ([#7](https://github.com/oelmekki/activerecord_any_of/issues/7))

  `#any_of` and `#none_of` are now scoped behind WhereChain in rails-4 :

      User.where.any_of({name: 'Doe'}, {active: true})

  The point here is to make it clear we only handles *conditions*, not grouping or other
  more query modifiers.


## 1.0.0 - June 22, 2013

* handles joins in subqueries - ([#1](https://github.com/oelmekki/activerecord_any_of/issues/1))
* add `#none_of` ([#2](https://github.com/oelmekki/activerecord_any_of/issues/1))
* raise error when no arguments ([#2](https://github.com/oelmekki/activerecord_any_of/issues/2))


## 0.0.1 - Jun 18, 2013

Initial version.
