require 'test_helper'

class ActiverecordAnyOfTest < ActiveSupport::TestCase
  fixtures :authors, :posts

  test 'finding with alternate conditions' do
    if Rails.version >= '4'
      assert_equal ['David', 'Mary'], Author.where.any_of({name: 'David'}, {name: 'Mary'}).map(&:name)
      assert_equal ['David', 'Mary'], Author.where.any_of({name: 'David'}, ['name = ?', 'Mary']).map(&:name)

      davids = Author.where(name: 'David')
      assert_equal ['David', 'Mary', 'Bob'], Author.where.any_of(davids, ['name = ?', 'Mary'], {name: 'Bob'}).map(&:name)
      assert_equal ['David', 'Mary', 'Bob'], Author.where.any_of(davids, "name = 'Mary'", {name: 'Bob', id: 3}).map(&:name)
      assert_equal ['David'], Author.where.not(name: 'Mary').where.any_of(davids, ['name = ?', 'Mary']).map(&:name)
    else
      assert_equal ['David', 'Mary'], Author.any_of({name: 'David'}, {name: 'Mary'}).map(&:name)
      assert_equal ['David', 'Mary'], Author.any_of({name: 'David'}, ['name = ?', 'Mary']).map(&:name)

      davids = Author.where(name: 'David')
      assert_equal ['David', 'Mary', 'Bob'], Author.any_of(davids, ['name = ?', 'Mary'], {name: 'Bob'}).map(&:name)
      assert_equal ['David', 'Mary', 'Bob'], Author.any_of(davids, "name = 'Mary'", {name: 'Bob', id: 3}).map(&:name)
      assert_equal ['David'], Author.where("name IS NOT 'Mary'").any_of(davids, ['name = ?', 'Mary']).map(&:name)
    end
  end

  test 'finding with alternate conditions on association' do
    david = Author.where(name: 'David').first
    welcome = david.posts.where(body: 'Such a lovely day')
    expected = ['Welcome to the weblog', 'So I was thinking']

    if Rails.version >= '4'
      assert_equal expected, david.posts.where.any_of(welcome, {type: 'SpecialPost'}).map(&:title)
    else
      assert_equal expected, david.posts.any_of(welcome, {type: 'SpecialPost'}).map(&:title)
    end
  end

  test 'finding alternate dynamically with joined queries' do
    david = Author.where(posts: { title: 'Welcome to the weblog' }).joins(:posts)
    mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).joins(:posts)

    if Rails.version >= '4'
      assert_equal ['David', 'Mary'], Author.where.any_of(david, mary).map(&:name)
    else
      assert_equal ['David', 'Mary'], Author.any_of(david, mary).map(&:name)
    end

    if Rails.version >= '4'
      david = Author.where(posts: { title: 'Welcome to the weblog' }).includes(:posts).references(:posts)
      mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).includes(:posts).references(:posts)
      assert_equal ['David', 'Mary'], Author.where.any_of(david, mary).map(&:name)
    else
      david = Author.where(posts: { title: 'Welcome to the weblog' }).includes(:posts)
      mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).includes(:posts)
      assert_equal ['David', 'Mary'], Author.any_of(david, mary).map(&:name)
    end
  end

  test 'finding with alternate negative conditions' do
    if Rails.version >= '4'
      assert_equal ['Bob'], Author.where.none_of({name: 'David'}, {name: 'Mary'}).map(&:name)
    else
      assert_equal ['Bob'], Author.none_of({name: 'David'}, {name: 'Mary'}).map(&:name)
    end
  end

  test 'finding with alternate negative conditions on association' do
    david = Author.where(name: 'David').first
    welcome = david.posts.where(body: 'Such a lovely day')
    expected = ['sti comments', 'sti me', 'habtm sti test']

    if Rails.version >= '4'
      assert_equal expected, david.posts.where.none_of(welcome, {type: 'SpecialPost'}).map(&:title)
    else
      assert_equal expected, david.posts.none_of(welcome, {type: 'SpecialPost'}).map(&:title)
    end
  end

  test 'calling #any_of with no argument raise exception' do
    if Rails.version >= '4'
      assert_raise(ArgumentError) { Author.where.any_of }
    else
      assert_raise(ArgumentError) { Author.any_of }
    end
  end

  test 'calling #none_of with no argument raise exception' do
    if Rails.version >= '4'
      assert_raise(ArgumentError) { Author.where.none_of }
    else
      assert_raise(ArgumentError) { Author.none_of }
    end
  end

  test 'calling #any_of after a wildcard query works' do
    if Rails.version >= '4'
      assert_equal ['David'], Author.where("name like '%av%'").where.any_of({name: 'David'}, {name: 'Mary'}).map(&:name)
    else
      assert_equal ['David'], Author.where("name like '%av%'").any_of({name: 'David'}, {name: 'Mary'}).map(&:name)
    end
  end

  if Rails.version >= '4'
    test 'calling directly #any_of is deprecated in rails-4' do
      assert_deprecated do
        Author.any_of({name: 'David'}, {name: 'Mary'}).map(&:name)
      end
    end
  end
end
