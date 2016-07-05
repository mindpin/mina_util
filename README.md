# MinaUtil

快速生成mina配置文件, 方便完成mina相关部署

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mina_util', git: "https://github.com/mindpin/mina_util.git"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mina_util

## 使用说明

```shell
$ rails g mina_utils:install
# 1. 项目名称:
# 2. 服务器域名/IP:
# 3. 服务器用户(默认为root):
# 4. 版本库地址:
# 5. 版本库分支(默认为master):

$ mina setup

# "=====mongoid配置===="
# 1. mongoid database:
# 2. mongoid host(默认为localhost):
# 3. mongoid port(默认为27017):
# "=====secrets配置===="
# 4. secrets(默认自动生成):
# "=====nginx配置===="
# 5. 访问域名，例(xx.4ye.me):
# "=====figaro配置===="
# 6+ 会根据config/application.yml.sample 询问所有key的value值。没有文件则跳过。
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mina_util. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

