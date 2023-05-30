build-gem:
	@docker build --build-arg RUBY_PLATFORM=ruby --build-arg RUBY_VERSION=3.2.2 -t jsonb_accessor-ruby:3.2.2 .
	@docker run --rm -v $(PWD):/usr/src/app -w /usr/src/app jsonb_accessor-ruby:3.2.2 gem build

build-gem-java:
	@docker build --build-arg RUBY_PLATFORM=jruby --build-arg RUBY_VERSION=9.4.2-jdk -t jsonb_accessor-jruby:9.4.2-jdk .
	@docker run --rm -v $(PWD):/usr/src/app -w /usr/src/app jsonb_accessor-jruby:9.4.2-jdk gem build --platform java
