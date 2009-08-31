all:
	ruby ./setup.rb config
	ruby ./setup.rb setup

install:
	ruby ./setup.rb install

clean:
	ruby ./setup.rb clean

test:
	spec -c spec/stringvalidator_spec.rb

doc: doc/index.html

doc/index.html: lib/stringvalidator.rb
	rdoc -c utf-8 lib
