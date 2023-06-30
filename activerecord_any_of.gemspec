# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'activerecord_any_of/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'activerecord_any_of'
  s.version     = ActiverecordAnyOf::VERSION
  s.authors     = ['Olivier El Mekki']
  s.email       = ['olivier@el-mekki.com']
  s.homepage    = 'https://github.com/oelmekki/activerecord_any_of'
  s.summary     = "Mongoid's any_of like implementation for activerecord"
  s.description = 'Any_of allows to compute dynamic OR queries.'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.7.0'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'activerecord', '>= 6', '< 8'

  s.metadata['rubygems_mfa_required'] = 'true'
end
