Gem::Specification.new do |s|
  s.name = %q{gemist}
  s.version = "0.0.5"
  s.authors = ["Eric Lindvall"]
  s.date = %q{2008-06-25}
  s.description = s.summary = %q{Capistrano recipes for gem installation}
  s.email = %q{eric@5stops.com}
  s.homepage = %q{http://github.com/eric/gemist/}

  s.files = [
    "lib/gemist.rb",
    "README.rdoc"
  ]
  s.require_paths = ["lib"]

  s.add_dependency(%q<capistrano>)

  s.has_rdoc = false
  s.extra_rdoc_files = ["README.rdoc"]

  s.rubygems_version = %q{1.2.0}
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
end
