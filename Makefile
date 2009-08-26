all:
	ruby ./setup.rb config
	ruby ./setup.rb setup

install:
	ruby ./setup.rb install

clean:
	ruby ./setup.rb clean

test: test_
test_:
	ruby -w test/test_stringvalidator.rb

doc: doc/index.html

doc/index.html: lib/stringvalidator.rb
	rdoc -c utf-8 lib
