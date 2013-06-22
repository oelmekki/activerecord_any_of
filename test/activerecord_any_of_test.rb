require 'test_helper'

class ActiverecordAnyOfTest < ActiveSupport::TestCase
  fixtures :authors, :posts

  test 'finding with alternate conditions' do
    assert_equal ['David', 'Mary'], Author.any_of({name: 'David'}, {name: 'Mary'}).map(&:name)
    assert_equal ['David', 'Mary'], Author.any_of({name: 'David'}, ['name = ?', 'Mary']).map(&:name)

    davids = Author.where(name: 'David')
    assert_equal ['David', 'Mary', 'Bob'], Author.any_of(davids, ['name = ?', 'Mary'], {name: 'Bob'}).map(&:name)
    assert_equal ['David', 'Mary', 'Bob'], Author.any_of(davids, "name = 'Mary'", {name: 'Bob', id: 3}).map(&:name)

    if Rails.version >= '4'
      assert_equal ['David'], Author.where.not(name: 'Mary').any_of(davids, ['name = ?', 'Mary']).map(&:name)
    else
      assert_equal ['David'], Author.where("name IS NOT 'Mary'").any_of(davids, ['name = ?', 'Mary']).map(&:name)
    end
  end

  test 'finding with alternate conditions on association' do
    david = Author.where(name: 'David').first
    welcome = david.posts.where(body: 'Such a lovely day')
    expected = ['Welcome to the weblog', 'So I was thinking']
    assert_equal expected, david.posts.any_of(welcome, {type: 'SpecialPost'}).map(&:title)
  end

  test 'finding alternate dynamically with joined queries' do
    david = Author.where(posts: { title: 'Welcome to the weblog' }).joins(:posts)
    mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).joins(:posts)

    assert_equal ['David', 'Mary'], Author.any_of(david, mary).map(&:name)

    if Rails.version >= '4'
      david = Author.where(posts: { title: 'Welcome to the weblog' }).includes(:posts).references(:posts)
      mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).includes(:posts).references(:posts)
    else
      david = Author.where(posts: { title: 'Welcome to the weblog' }).includes(:posts)
      mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).includes(:posts)
    end

    assert_equal ['David', 'Mary'], Author.any_of(david, mary).map(&:name)
  end

  test 'finding with alternate negative conditions' do
    assert_equal ['Bob'], Author.none_of({name: 'David'}, {name: 'Mary'}).map(&:name)
  end

  test 'finding with alternate negative conditions on association' do
    david = Author.where(name: 'David').first
    welcome = david.posts.where(body: 'Such a lovely day')
    expected = ['sti comments', 'sti me', 'habtm sti test']
    assert_equal expected, david.posts.none_of(welcome, {type: 'SpecialPost'}).map(&:title)
  end
end
