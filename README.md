# rabl_to_jbuilder

This gem attempts to convert [RABL](https://github.com/nesquena/rabl) templates into the more widely used [JBuilder](https://github.com/rails/jbuilder).

## Installation

    $ gem install rabl_to_jbuilder

## Usage

```
rabl_to_jbuilder app/views/api/
```

or

```
rabl_to_jbuilder app/views/api/orders/show.rabl
```

## Limitations

RABL has more implicitness than JBuilder, so some behaviour can't be inferred.
rabl_to_jbuilder will serve as a good first pass but will usually require some manual editing.

**Partials**

RABL allows using any template as a partial. JBuilder expects partials to start with an `_` (like all Rails partials).
rabl_to_jbuilder doesn't figure out which templates should be partials and assumed everything is a top-level view. Manual renaming is required for now.

**Undefined/Missing data**

Rabl will ignore any nil data.
It also [treats any method missing as nil](https://github.com/nesquena/rabl/blob/c4a69f883629887d24544c8caf3519bf92b16064/lib/rabl/helpers.rb#L17), basically everything has an implicit `.try`.

rabl_to_jbuilder makes no attempt to replicate this. You'll have to add `if`s or similar around any sections of the template you expect to receive nil.

**Object name**

RABL has an implicit object. rabl_to_jbuilder guesses at a name using the name of the directory the RABL template is in. Similarly, the object name is guessed when rendering a partial.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jhawthorn/rabl_to_jbuilder. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

