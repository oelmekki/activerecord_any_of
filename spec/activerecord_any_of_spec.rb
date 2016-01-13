require 'spec_helper'

describe ActiverecordAnyOf do
  fixtures :authors, :posts, :users

  describe 'finding with alternate conditions' do
    let(:davids) { Author.where(name: "David") }

    it "matches hash combinations" do
      if ActiveRecord::VERSION::MAJOR >= 4
        expect(Author.where.any_of({name: 'David'}, {name: 'Mary'})).to match_array(authors(:david, :mary))
      else
        expect(Author.any_of({name: 'David'}, {name: 'Mary'})).to match_array(authors(:david, :mary))
      end
    end

    it "matches combination of hash and array" do
      if ActiveRecord::VERSION::MAJOR >= 4
        expect(Author.where.any_of({name: 'David'}, ['name = ?', 'Mary'])).to match_array(authors(:david, :mary))
      else
        expect(Author.any_of({name: 'David'}, ['name = ?', 'Mary'])).to match_array(authors(:david, :mary))
      end
    end

    it "matches a combination of hashes, arrays, and AR relations" do
      if ActiveRecord::VERSION::MAJOR >= 4
        expect(Author.where.any_of(davids, ['name = ?', 'Mary'], {name: 'Bob'})).to match_array(authors(:david, :mary, :bob))
      else
        expect(Author.any_of(davids, ['name = ?', 'Mary'], {name: 'Bob'})).to match_array(authors(:david, :mary, :bob))
      end
    end

    it "matches a combination of strings, hashes, and AR relations" do
      if ActiveRecord::VERSION::MAJOR >= 4
        expect(Author.where.any_of(davids, "name = 'Mary'", {name: 'Bob', id: 3})).to match_array(authors(:david, :mary, :bob))
      else
        expect(Author.any_of(davids, "name = 'Mary'", {name: 'Bob', id: 3})).to match_array(authors(:david, :mary, :bob))
      end
    end

    it "doesn't find combinations previously filtered out" do
      if ActiveRecord::VERSION::MAJOR >= 4
        expect(Author.where.not(name: 'Mary').where.any_of(davids, ['name = ?', 'Mary'])).to match_array([authors(:david)])
      else
        expect(Author.where("name != 'Mary'").any_of(davids, ['name = ?', 'Mary'])).to match_array([authors(:david)])
      end
    end
  end

  it 'finding with alternate conditions on has_many association' do
    david = authors(:david)
    welcome = david.posts.where(body: 'Such a lovely day')
    expected = ['Welcome to the weblog', 'So I was thinking']

    if ActiveRecord::VERSION::MAJOR >= 4
      expect(david.posts.where.any_of(welcome, {type: 'SpecialPost'}).map(&:title)).to match_array(expected)
    else
      expect(david.posts.any_of(welcome, {type: 'SpecialPost'}).map(&:title)).to match_array(expected)
    end
  end

  it 'finds with combined polymorphic associations' do
    company = Company.create!
    university = University.create!

    company.users << users(:ezra)
    university.users << users(:aria)

    if ActiveRecord::VERSION::MAJOR >= 4
      expect(User.where.any_of(company.users, university.users)).to match_array(users(:ezra, :aria))
    else
      expect(User.any_of(company.users, university.users)).to match_array(users(:ezra, :aria))
    end
  end

  it 'finds with more than 2 combined polymorphic associations' do
    company = Company.create!
    university = University.create!
    company2 = Company.create!

    company.users << users(:ezra)
    university.users << users(:aria)
    company2.users << users(:james)

    if ActiveRecord::VERSION::MAJOR >= 4
      expect(User.where.any_of(company.users, university.users, company2.users)).to match_array(users(:ezra, :aria, :james))
    else
      expect(User.any_of(company.users, university.users, company2.users)).to match_array(users(:ezra, :aria, :james))
    end
  end

  it 'finds alternatives with combined has_many associations' do
    david, mary = authors(:david, :mary)

    if ActiveRecord::VERSION::MAJOR >= 4
      expect(Post.where.any_of(david.posts, mary.posts)).to match_array(david.posts + mary.posts)
    else
      expect(Post.any_of(david.posts, mary.posts)).to match_array(david.posts + mary.posts)
    end
  end

  it 'finds alternatives with more than 2 combined has_many associations' do
    david, mary, bob = authors(:david, :mary, :bob)

    if ActiveRecord::VERSION::MAJOR >= 4
      expect(Post.where.any_of(david.posts, mary.posts, bob.posts)).to match_array(david.posts + mary.posts + bob.posts)
    else
      expect(Post.any_of(david.posts, mary.posts, bob.posts)).to match_array(david.posts + mary.posts + bob.posts)
    end
  end

  describe 'finding alternate dynamically with joined queries' do
    it "matches combined AR relations with joins" do
      david = Author.where(posts: { title: 'Welcome to the weblog' }).joins(:posts)
      mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).joins(:posts)

      if ActiveRecord::VERSION::MAJOR >= 4
        expect(Author.where.any_of(david, mary)).to match_array(authors(:david, :mary))
      else
        expect(Author.any_of(david, mary)).to match_array(authors(:david, :mary))
      end
    end

    it "matches combined AR relations with joins and includes" do
      if ActiveRecord::VERSION::MAJOR >= 4
        david = Author.where(posts: { title: 'Welcome to the weblog' }).includes(:posts).references(:posts)
        mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).includes(:posts).references(:posts)
        expect(Author.where.any_of(david, mary)).to match_array(authors(:david, :mary))
      else
        david = Author.where(posts: { title: 'Welcome to the weblog' }).includes(:posts)
        mary = Author.where(posts: { title: "eager loading with OR'd conditions" }).includes(:posts)
        expect(Author.any_of(david, mary)).to match_array(authors(:david, :mary))
      end
    end
  end

  it 'finding with alternate negative conditions' do
    if ActiveRecord::VERSION::MAJOR >= 4
      expect(Author.where.none_of({name: 'David'}, {name: 'Mary'})).to match_array([authors(:bob)])
    else
      expect(Author.none_of({name: 'David'}, {name: 'Mary'})).to match_array([authors(:bob)])
    end
  end

  it 'finding with alternate negative conditions on association' do
    david = Author.where(name: 'David').first
    welcome = david.posts.where(body: 'Such a lovely day')
    expected = ['sti comments', 'sti me', 'habtm sti test']

    if ActiveRecord::VERSION::MAJOR >= 4
      expect(david.posts.where.none_of(welcome, {type: 'SpecialPost'}).map(&:title)).to match_array(expected)
    else
      expect(david.posts.none_of(welcome, {type: 'SpecialPost'}).map(&:title)).to match_array(expected)
    end
  end

  it 'calling #any_of with no argument raises exception' do
    if ActiveRecord::VERSION::MAJOR >= 4
      expect { Author.where.any_of }.to raise_exception(ArgumentError)
    else
      expect { Author.any_of }.to raise_exception(ArgumentError)
    end
  end

  it 'calling #none_of with no argument raises exception' do
    if ActiveRecord::VERSION::MAJOR >= 4
      expect { Author.where.none_of }.to raise_exception(ArgumentError)
    else
      expect { Author.none_of }.to raise_exception(ArgumentError)
    end
  end

  it 'calling #any_of after including via a hash does not raise an exception' do
    if ActiveRecord::VERSION::MAJOR >= 4
      expect { User.includes(memberships: :companies).where.any_of(user_id: 1, company_id: 1) }.
        to_not raise_exception
    else
      expect { User.includes(memberships: :companies).any_of(user_id: 1, company_id: 1) }.
        to_not raise_exception
    end
  end

  it 'calling #any_of after a wildcard query works' do
    if ActiveRecord::VERSION::MAJOR >= 4
      expect(Author.where("name like '%av%'").where.any_of({name: 'David'}, {name: 'Mary'})).to match_array([authors(:david)])
    else
      expect(Author.where("name like '%av%'").any_of({name: 'David'}, {name: 'Mary'})).to match_array([authors(:david)])
    end
  end

  it 'calling #any_of with a single Hash as parameter expands it' do
    if ActiveRecord::VERSION::MAJOR >= 4
      expect(Author.where.any_of(name: 'David', id: 2)).to match_array(authors(:david, :mary))
    else
      expect(Author.any_of(name: 'David', id: 2)).to match_array(authors(:david, :mary))
    end
  end

  it "does not fail on hudge number for bind values" do
    conditions = [
      { name: 'Mary' },
      { name: 'David' },
      { name: 'David1' },
      { name: 'David2' },
      { name: 'David3' },
      { name: 'David4' },
      { name: 'David5' },
      { name: 'David6' },
      { name: 'David7' },
      { name: 'David8' },
      { name: 'David9' },
      { name: 'David10' },
      { name: 'David11' },
      { name: 'David12' },
      { name: 'David13' },
      { name: 'David14' }
    ]

    if ActiveRecord::VERSION::MAJOR >= 4
      expect(Author.where.any_of(*conditions)).to match_array(authors(:david, :mary))
    else
      expect(Author.any_of(*conditions)).to match_array(authors(:david, :mary))
    end
  end

  if ActiveRecord::VERSION::MAJOR >= 4
    it 'calling directly #any_of is deprecated in rails-4' do
      allow(ActiveSupport::Deprecation).to receive(:warn)
      Author.any_of({name: 'David'}, {name: 'Mary'})
      expect(ActiveSupport::Deprecation).to have_received(:warn)
    end
  end
end
