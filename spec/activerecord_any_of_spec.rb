# frozen_string_literal: true

require 'spec_helper'

describe 'ActiverecordAnyOf' do
  fixtures :authors, :posts, :users
  let(:davids) { Author.where(name: 'David') }

  it 'matches hash combinations' do
    expect(Author.where.any_of({ name: 'David' }, { name: 'Mary' })).to match_array(authors(:david, :mary))
  end

  it 'matches combination of hash and array' do
    expect(Author.where.any_of({ name: 'David' }, ['name = ?', 'Mary'])).to match_array(authors(:david, :mary))
  end

  it 'matches a combination of hashes, arrays, and AR relations' do
    expect(Author.where.any_of(davids, ['name = ?', 'Mary'],
                               { name: 'Bob' })).to match_array(authors(:david, :mary, :bob))
  end

  it 'matches a combination of strings, hashes, and AR relations' do
    expect(Author.where.any_of(davids, "name = 'Mary'",
                               { name: 'Bob', id: 3 })).to match_array(authors(:david, :mary, :bob))
  end

  it 'matches a combination of only strings' do
    expect(Author.where.any_of("name = 'David'", "name = 'Mary'")).to match_array(authors(:david, :mary))
  end

  it "doesn't match combinations previously filtered out" do
    expect(Author.where.not(name: 'Mary').where.any_of(davids,
                                                       ['name = ?', 'Mary'])).to contain_exactly(authors(:david))
  end

  it 'matches with alternate conditions on has_many association' do
    david = authors(:david)
    welcome = david.posts.where(body: 'Such a lovely day')
    expected = ['Welcome to the weblog', 'So I was thinking']

    expect(david.posts.where.any_of(welcome, { type: 'SpecialPost' }).map(&:title)).to match_array(expected)
  end

  describe 'with polymorphic associations' do
    let(:company) { Company.create! }
    let(:university) { University.create! }
    let(:company2) { Company.create! }

    it 'matches with combined polymorphic associations' do
      company.users << users(:ezra)
      university.users << users(:aria)

      expect(User.where.any_of(company.users, university.users)).to match_array(users(:ezra, :aria))
    end

    it 'matches with more than 2 combined polymorphic associations' do
      company.users << users(:ezra)
      university.users << users(:aria)
      company2.users << users(:james)

      expect(User.where.any_of(company.users, university.users,
                               company2.users)).to match_array(users(:ezra, :aria, :james))
    end
  end

  it 'matches alternatives with combined has_many associations' do
    david, mary = authors(:david, :mary)

    expect(Post.where.any_of(david.posts, mary.posts)).to match_array(david.posts + mary.posts)
  end

  it 'matches alternatives with more than 2 combined has_many associations' do
    david, mary, bob = authors(:david, :mary, :bob)

    expect(Post.where.any_of(david.posts, mary.posts, bob.posts)).to match_array(david.posts + mary.posts + bob.posts)
  end

  describe 'finding alternate dynamically with joined queries' do
    it 'matches combined AR relations with joins' do
      david = Author.where(posts: { title: 'Welcome to the weblog' }).joins(:posts)
      mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).joins(:posts)

      expect(Author.where.any_of(david, mary)).to match_array(authors(:david, :mary))
    end

    it 'matches combined AR relations with joins and includes' do
      david = Author.where(posts: { title: 'Welcome to the weblog' }).includes(:posts).references(:posts)
      mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).includes(:posts).references(:posts)

      expect(Author.where.any_of(david, mary)).to match_array(authors(:david, :mary))
    end
  end

  describe 'with alternate negative conditions' do
    it 'filters out matching records' do
      expect(Author.where.none_of({ name: 'David' }, { name: 'Mary' })).to contain_exactly(authors(:bob))
    end

    it 'filters out matching records with only strings' do
      expect(Author.where.none_of("name = 'David'", "name = 'Mary'")).to contain_exactly(authors(:bob))
    end

    it 'filters out matching records with associations' do
      david = Author.where(name: 'David').first
      welcome = david.posts.where(body: 'Such a lovely day')
      expected = ['sti comments', 'sti me', 'habtm sti test']

      expect(david.posts.where.none_of(welcome, { type: 'SpecialPost' }).map(&:title)).to match_array(expected)
    end
  end

  describe 'calling #any_of with no argument' do
    it 'raises exception' do
      expect { Author.where.any_of }.to raise_exception(ArgumentError)
    end
  end

  describe 'calling #none_of with no argument' do
    it 'raises exception' do
      expect { Author.where.none_of }.to raise_exception(ArgumentError)
    end
  end

  describe 'calling #any_of after including via a hash' do
    it 'does not raise an exception' do
      expect { User.includes(memberships: :companies).where.any_of(user_id: 1, company_id: 1) }
        .not_to raise_exception
    end
  end

  describe 'calling #any_of after a wildcard query' do
    it 'matches the records matching the wildcard' do
      expect(Author.where("name like '%av%'").where.any_of({ name: 'David' },
                                                           { name: 'Mary' })).to contain_exactly(authors(:david))
    end
  end

  describe 'calling #any_of with a single Hash as parameter' do
    it 'expands the hash as multiple parameters' do
      expect(Author.where.any_of(name: 'David', id: 2)).to match_array(authors(:david, :mary))
    end
  end

  describe 'using a huge number of bind values' do
    it 'does not crash' do
      conditions = [{ name: 'Mary' }, { name: 'David' }]
      (1..14).each { |i| conditions << { name: "David#{i}" } }
      expect(Author.where.any_of(*conditions)).to match_array(authors(:david, :mary))
    end
  end

  it 'makes rubocop and simplecov be happy together' do
    alternative = ActiverecordAnyOf::AlternativeBuilder.new(:positive, [], 'foo = 1')
    expect(alternative.instance_variable_get(:@builder)).to respond_to :each
  end
end
