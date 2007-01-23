# $Id$
# Copyright (C) 2007 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "test/unit"
require "stringvalidator"

class TC_StringValidator < Test::Unit::TestCase
  def setup()
  end
  def teardown()
  end

  def test_valid_integer()
    assert(StringValidator.valid?(Integer, "123"))
    assert(StringValidator.valid?(Integer, "0"))
    assert(StringValidator.valid?(Integer, "-213"))
    assert(!StringValidator.valid?(Integer, "1.2"))
    assert(!StringValidator.valid?(Integer, "a"))
    assert_nothing_raised{StringValidator.validate(Integer, "123")}
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(Integer, "a")}
  end

  def test_valid_float()
    assert(StringValidator.valid?(Float, "1.23"))
    assert(StringValidator.valid?(Float, "123"))
    assert(StringValidator.valid?(Float, "0"))
    assert(StringValidator.valid?(Float, "-213"))
    assert(!StringValidator.valid?(Float, "a"))
    assert_nothing_raised{StringValidator.validate(Float, "1.23")}
    assert_raises(StringValidator::Error::NotFloat){StringValidator.validate(Float, "a")}
  end

  def test_valid_integer_const()
    r = 987
    assert(StringValidator.valid?(r, "987"))
    assert(!StringValidator.valid?(r, "986"))
    assert_nothing_raised{StringValidator.validate(r, "987")}
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(r, "986")}
  end

  def test_valid_int_range()
    r = 3..45
    assert(StringValidator.valid?(r, "3"))
    assert(StringValidator.valid?(r, "45"))
    assert(StringValidator.valid?(r, "10"))
    assert(!StringValidator.valid?(r, "8.7"))
    assert(!StringValidator.valid?(r, "2.9"))
    assert(!StringValidator.valid?(r, "46"))
    assert(!StringValidator.valid?(r, "hoge"))
    assert_nothing_raised{StringValidator.validate(r, "10")}
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(r, "2.9")}
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "46")}
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(r, "hoge")}
  end

  def test_valid_num_range()
    r = 3.0 .. 45
    assert(StringValidator.valid?(r, "3"))
    assert(StringValidator.valid?(r, "45"))
    assert(StringValidator.valid?(r, "10"))
    assert(StringValidator.valid?(r, "8.7"))
    assert(!StringValidator.valid?(r, "2.9"))
    assert(!StringValidator.valid?(r, "46"))
    assert(!StringValidator.valid?(r, "hoge"))
    assert_nothing_raised{StringValidator.validate(r, "10")}
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "2.9")}
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "46")}
    assert_raises(StringValidator::Error::NotFloat){StringValidator.validate(r, "hoge")}
  end

  def test_valid_num_str()
    r = "abc" .. "xyz"
    assert(StringValidator.valid?(r, "abc"))
    assert(StringValidator.valid?(r, "tommy"))
    assert(StringValidator.valid?(r, "xyz"))
    assert(!StringValidator.valid?(r, "abb"))
    assert(!StringValidator.valid?(r, "xyzz"))
    assert_nothing_raised{StringValidator.validate(r, "tommy")}
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "zzz")}
  end

  def test_valid_str()
    r = "hogehoge"
    assert(StringValidator.valid?(r, "hogehoge"))
    assert(!StringValidator.valid?(r, "123"))
    assert_nothing_raised{StringValidator.validate(r, "hogehoge")}
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(r, "123")}
  end

  def test_valid_regexp()
    r = /^[abc]$/
    assert(StringValidator.valid?(r, "a"))
    assert(StringValidator.valid?(r, "b"))
    assert(StringValidator.valid?(r, "c"))
    assert(!StringValidator.valid?(r, "abc"))
    assert(!StringValidator.valid?(r, "A"))
    assert_nothing_raised{StringValidator.validate(r, "a")}
    assert_raises(StringValidator::Error::RegexpMismatch){StringValidator.validate(r, "A")}
  end

  def test_valid_array()
    a = [123, "abc", /xyz/i]
    assert(StringValidator.valid?(a, "123"))
    assert(StringValidator.valid?(a, "abc"))
    assert(StringValidator.valid?(a, "xxxXyZzzz"))
    assert(!StringValidator.valid?(a, "789"))
    assert_nothing_raised{StringValidator.validate(a, "abc")}
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(a, "789")}
  end

  def test_valid_any()
    any = {:any => [1, 2, 4, 8]}
    assert(StringValidator.valid?(any, "1"))
    assert(StringValidator.valid?(any, "2"))
    assert(StringValidator.valid?(any, "4"))
    assert(StringValidator.valid?(any, "8"))
    assert(!StringValidator.valid?(any, "5"))
    assert(!StringValidator.valid?(any, "0"))
    assert_nothing_raised{StringValidator.validate(any, "1")}
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(any, "0")}
  end

  def test_valid_all()
    all = {:all => [Integer, 5..10]}
    assert(StringValidator.valid?(all, "5"))
    assert(StringValidator.valid?(all, "7"))
    assert(StringValidator.valid?(all, "10"))
    assert(!StringValidator.valid?(all, "8.5"))
    assert(!StringValidator.valid?(all, "abc"))
    assert_nothing_raised{StringValidator.validate(all, "7")}
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(all, "abc")}
  end

  def test_valid_rule()
    hash = {
      :rule => /abc/,
    }
    assert(StringValidator.valid?(hash, "012abc345"))
    assert(!StringValidator.valid?(hash, "12345"))
    assert_nothing_raised{StringValidator.validate(hash, "012abc345")}
    assert_raises(StringValidator::Error::RegexpMismatch){StringValidator.validate(hash, "12345")}
  end

  def test_valid_length()
    hash = {
      :length => 3,
    }
    assert(StringValidator.valid?(hash, "123"))
    assert(!StringValidator.valid?(hash, "12"))
    assert(!StringValidator.valid?(hash, "1234"))
    assert_nothing_raised{StringValidator.validate(hash, "123")}
    assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "1234")}
  end

  def test_valid_length_range()
    hash = {
      :length => 3..10,
    }
    assert(StringValidator.valid?(hash, "123"))
    assert(StringValidator.valid?(hash, "1234567890"))
    assert(StringValidator.valid?(hash, "12345"))
    assert(!StringValidator.valid?(hash, "12"))
    assert(!StringValidator.valid?(hash, "12345678901"))
    assert_nothing_raised{StringValidator.validate(hash, "123")}
    assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "12345678901")}
  end

  def test_valid_minlength()
    hash = {
      :minlength => 3,
    }
    assert(StringValidator.valid?(hash, "1234"))
    assert(StringValidator.valid?(hash, "123"))
    assert(!StringValidator.valid?(hash, "12"))
    assert_nothing_raised{StringValidator.validate(hash, "123")}
    assert_raises(StringValidator::Error::TooShort){StringValidator.validate(hash, "12")}
  end

  def test_valid_maxlength()
    hash = {
      :maxlength => 10,
    }
    assert(StringValidator.valid?(hash, "123456789"))
    assert(StringValidator.valid?(hash, "1234567890"))
    assert(!StringValidator.valid?(hash, "12345678901"))
    assert_nothing_raised{StringValidator.validate(hash, "123456789")}
    assert_raises(StringValidator::Error::TooLong){StringValidator.validate(hash, "12345678901")}
  end

  def test_valid_proc()
    p = Proc.new{|a| a == "xyz"}
    assert(StringValidator.valid?(p, "xyz"))
    assert(!StringValidator.valid?(p, "abc"))
    assert_nothing_raised{StringValidator.validate(p, "xyz")}
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(p, "abc")}
  end

  def test_validate_rules()
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    assert(s.validate(:hoge, "123"))
    assert(s.validate(:fuga, "abc"))
    assert_raises(StringValidator::Error::NotInteger){s.validate(:hoge, "abc")}
    assert_raises(StringValidator::Error::InvalidValue){s.validate(:fuga, "123")}
    assert_raises(ArgumentError){s.validate(:hage, "123")}
  end

  def test_valid_rules()
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    assert(s.valid?(:hoge, "123"))
    assert(s.valid?(:fuga, "abc"))
    assert(!s.valid?(:hoge, "abc"))
    assert(!s.valid?(:fuga, "123"))
  end

  def test_validated_rule()
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    assert_equal(:hoge, s.validated_rule("123"))
    assert_equal(:fuga, s.validated_rule("abc"))
    assert_equal(nil, s.validated_rule("xyz"))
  end

end
