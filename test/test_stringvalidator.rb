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

  def test_validate_integer()
    assert(StringValidator.validate(Integer, "123"))
    assert(StringValidator.validate(Integer, "0"))
    assert(StringValidator.validate(Integer, "-213"))
    assert(!StringValidator.validate(Integer, "a"))
  end

  def test_validate_integer_const()
    r = 987
    assert(StringValidator.validate(r, "987"))
    assert(!StringValidator.validate(r, "986"))
  end

  def test_validate_range()
    r = 3..45
    assert(StringValidator.validate(r, "3"))
    assert(StringValidator.validate(r, "45"))
    assert(StringValidator.validate(r, "10"))
    assert(StringValidator.validate(r, "8.7"))
    assert(!StringValidator.validate(r, "2.9"))
    assert(!StringValidator.validate(r, "46"))
    assert(!StringValidator.validate(r, "hoge"))
  end

  def test_validate_str()
    r = "hogehoge"
    assert(StringValidator.validate(r, "hogehoge"))
    assert(!StringValidator.validate(r, "xxxx"))
    assert(!StringValidator.validate(r, "123"))
  end

  def test_validate_regexp()
    r = /^[abc]$/
    assert(StringValidator.validate(r, "a"))
    assert(StringValidator.validate(r, "b"))
    assert(StringValidator.validate(r, "c"))
    assert(!StringValidator.validate(r, "abc"))
    assert(!StringValidator.validate(r, "A"))
  end

  def test_validate_any()
    any = {:any => [1, 2, 4, 8]}
    assert(StringValidator.validate(any, "1"))
    assert(StringValidator.validate(any, "2"))
    assert(StringValidator.validate(any, "4"))
    assert(StringValidator.validate(any, "8"))
    assert(!StringValidator.validate(any, "5"))
    assert(!StringValidator.validate(any, "0"))
  end

  def test_validate_all()
    all = {:all => [Integer, 5..10]}
    assert(StringValidator.validate(all, "5"))
    assert(StringValidator.validate(all, "7"))
    assert(StringValidator.validate(all, "10"))
    assert(!StringValidator.validate(all, "8.5"))
    assert(!StringValidator.validate(all, "abc"))
  end

  def test_validate_length()
    hash = {
      :maxlength => 10,
      :minlength => 3,
    }
    assert(StringValidator.validate(hash, "123"))
    assert(StringValidator.validate(hash, "1234567890"))
    assert(!StringValidator.validate(hash, "12"))
    assert(!StringValidator.validate(hash, "12345678901"))
  end

  def test_validate_proc()
    p = Proc.new{|a| a == "xyz"}
    assert(StringValidator.validate(p, "xyz"))
    assert(!StringValidator.validate(p, "abc"))
  end

  def test_validate()
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    assert(s.validate(:hoge, "123"))
    assert(s.validate(:fuga, "abc"))
    assert_raises(StringValidator::Error){s.validate(:hoge, "abc")}
    assert_raises(StringValidator::Error){s.validate(:fuga, "123")}
  end

  def test_validate_rule_noraise()
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule, false)
    assert(s.validate(:hoge, "123"))
    assert(s.validate(:fuga, "abc"))
    assert(!s.validate(:hoge, "abc"))
    assert(!s.validate(:fuga, "123"))
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
