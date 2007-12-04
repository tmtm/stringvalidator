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
    assert_equal 123, StringValidator.validate(Integer, "123")
    assert_equal 0, StringValidator.validate(Integer, "0")
    assert_equal(-213, StringValidator.validate(Integer, "-213"))
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(Integer, "1.2")}
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(Integer, "a")}
  end

  def test_validate_float()
    assert_equal 1.23, StringValidator.validate(Float, "1.23")
    assert_equal 123, StringValidator.validate(Float, "123")
    assert_equal 0, StringValidator.validate(Float, "0")
    assert_equal(-213, StringValidator.validate(Float, "-213"))
    assert_raises(StringValidator::Error::NotFloat){StringValidator.validate(Float, "a")}
  end

  def test_validate_integer_const()
    r = 987
    assert_equal 987, StringValidator.validate(r, "987")
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(r, "986")}
  end

  def test_validate_int_range()
    r = 3..45
    assert_equal 3, StringValidator.validate(r, "3")
    assert_equal 45, StringValidator.validate(r, "45")
    assert_equal 10, StringValidator.validate(r, "10")
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(r, "8.7")}
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(r, "2.9")}
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "46")}
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(r, "hoge")}
  end

  def test_validate_num_range()
    r = 3.0 .. 45
    assert_equal 3, StringValidator.validate(r, "3")
    assert_equal 45, StringValidator.validate(r, "45")
    assert_equal 10, StringValidator.validate(r, "10")
    assert_equal 8.7, StringValidator.validate(r, "8.7")
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "2.9")}
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "46")}
    assert_raises(StringValidator::Error::NotFloat){StringValidator.validate(r, "hoge")}
  end

  def test_validate_num_str()
    r = "abc" .. "xyz"
    assert_equal "abc", StringValidator.validate(r, "abc")
    assert_equal "tommy", StringValidator.validate(r, "tommy")
    assert_equal "xyz", StringValidator.validate(r, "xyz")
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "abb")}
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "xyzz")}
  end

  def test_validate_str()
    r = "hogehoge"
    assert_equal "hogehoge", StringValidator.validate(r, "hogehoge")
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(r, "123")}
  end

  def test_validate_regexp()
    r = /^[abc]$/
    assert_equal "a", StringValidator.validate(r, "a")
    assert_equal "b", StringValidator.validate(r, "b")
    assert_equal "c", StringValidator.validate(r, "c")
    assert_equal false, StringValidator.valid?(r, "abc")
    assert_equal false, StringValidator.valid?(r, "A")
    assert_raises(StringValidator::Error::RegexpMismatch){StringValidator.validate(r, "abc")}
    assert_raises(StringValidator::Error::RegexpMismatch){StringValidator.validate(r, "A")}
  end

  def test_validate_array()
    a = [123, "abc", /xyz/i]
    assert_equal 123, StringValidator.validate(a, "123")
    assert_equal "abc", StringValidator.validate(a, "abc")
    assert_equal "xxxXyZzzz", StringValidator.validate(a, "xxxXyZzzz")
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(a, "789")}
  end

  def test_validate_any()
    any = {:any => [1, 2, 4, 8]}
    assert_equal 1, StringValidator.validate(any, "1")[:any]
    assert_equal 2, StringValidator.validate(any, "2")[:any]
    assert_equal 4, StringValidator.validate(any, "4")[:any]
    assert_equal 8, StringValidator.validate(any, "8")[:any]
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(any, "5")}
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(any, "0")}
  end

  def test_validate_all()
    all = {:all => [Integer, 5..10]}
    assert_equal 5, StringValidator.validate(all, "5")[:all]
    assert_equal 7, StringValidator.validate(all, "7")[:all]
    assert_equal 10, StringValidator.validate(all, "10")[:all]
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(all, "8.5")}
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(all, "abc")}
  end

  def test_validate_rule()
    hash = {
      :rule => /abc/,
    }
    assert_equal "012abc345", StringValidator.validate(hash, "012abc345")[:rule]
    assert_raises(StringValidator::Error::RegexpMismatch){StringValidator.validate(hash, "12345")}
  end

  def test_validate_length()
    hash = {
      :length => 3,
    }
    assert_equal "123", StringValidator.validate(hash, "123")[:length]
    assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "1234")}
  end

  def test_validate_length_range()
    hash = {
      :length => 3..10,
    }
    assert_equal "123", StringValidator.validate(hash, "123")[:length]
    assert_equal "1234567890", StringValidator.validate(hash, "1234567890")[:length]
    assert_equal "12345", StringValidator.validate(hash, "12345")[:length]
    assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "12")}
    assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "12345678901")}
  end

  def test_validate_minlength()
    hash = {
      :minlength => 3,
    }
    assert_equal "1234", StringValidator.validate(hash, "1234")[:minlength]
    assert_equal "123", StringValidator.validate(hash, "123")[:minlength]
    assert_raises(StringValidator::Error::TooShort){StringValidator.validate(hash, "12")}
  end

  def test_validate_maxlength()
    hash = {
      :maxlength => 10,
    }
    assert_equal "123456789", StringValidator.validate(hash, "123456789")[:maxlength]
    assert_equal "1234567890", StringValidator.validate(hash, "1234567890")[:maxlength]
    assert_raises(StringValidator::Error::TooLong){StringValidator.validate(hash, "12345678901")}
  end

  def test_validate_charlength()
    kcode = $KCODE
    $KCODE = "U"
    hash = {
      :charlength => 3,
    }
    begin
      assert_equal "１２３", StringValidator.validate(hash, "１２３")[:charlength]
      assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "１２")}
      assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "１２３４")}
    ensure
      $KCODE = kcode
    end
  end

  def test_validate_charlength_range()
    kcode = $KCODE
    $KCODE = "U"
    hash = {
      :charlength => 3..10,
    }
    begin
      assert_equal "１２３", StringValidator.validate(hash, "１２３")[:charlength]
      assert_equal "１２３４５６７８９０", StringValidator.validate(hash, "１２３４５６７８９０")[:charlength]
      assert_equal "１２３４５", StringValidator.validate(hash, "１２３４５")[:charlength]
      assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "１２")}
      assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "１２３４５６７８９０１")}
    ensure
      $KCODE = kcode
    end
  end

  def test_validate_mincharlength()
    kcode = $KCODE
    $KCODE = "U"
    hash = {
      :mincharlength => 3,
    }
    begin
      assert_equal "１２３４", StringValidator.validate(hash, "１２３４")[:mincharlength]
      assert_equal "１２３", StringValidator.validate(hash, "１２３")[:mincharlength]
      assert_raises(StringValidator::Error::TooShort){StringValidator.validate(hash, "１２")}
    ensure
      $KCODE = kcode
    end
  end

  def test_validate_maxcharlength()
    kcode = $KCODE
    $KCODE = "U"
    hash = {
      :maxcharlength => 10,
    }
    begin
      assert_equal "１２３４５６７８９", StringValidator.validate(hash, "１２３４５６７８９")[:maxcharlength]
      assert_equal "１２３４５６７８９０", StringValidator.validate(hash, "１２３４５６７８９０")[:maxcharlength]
      assert_raises(StringValidator::Error::TooLong){StringValidator.validate(hash, "１２３４５６７８９０１")}
    ensure
      $KCODE = kcode
    end
  end

  def test_validate_hash_multiple
    hash = {
      :maxlength => 5,
      :rule => /\A\d+\z/,
    }
    str = "12345"
    assert_equal({:maxlength=>str, :rule=>str}, StringValidator.validate(hash, str))
  end

  def test_validate_invalid_hash
    hash = {
      :hoge => nil,
    }
    begin
      assert_raises(ArgumentError){StringValidator.validate(hash, "hoge")}
    end
  end

  def test_validate_proc()
    p = Proc.new{|a| a == "xyz" && 123}
    assert_equal 123, StringValidator.validate(p, "xyz")
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(p, "abc")}
  end

  require "pathname"
  def test_validate_class()
    r = Pathname
    assert_kind_of Pathname, StringValidator.validate(r, "abcdefg")
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(r, "abcd\0efg")}
  end

  def test_validate_rules()
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    assert_equal 123, s.validate(:hoge, "123")
    assert_equal "abc", s.validate(:fuga, "abc")
    assert_raises(StringValidator::Error::NotInteger){s.validate(:hoge, "abc")}
    assert_raises(StringValidator::Error::InvalidValue){s.validate(:fuga, "123")}
    assert_raises(ArgumentError){s.validate(:hage, "123")}
  end

  def test_validQ_rules()
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    assert_equal true, s.valid?(:hoge, "123")
    assert_equal true, s.valid?(:fuga, "abc")
    assert_equal false, s.valid?(:hoge, "abc")
    assert_equal false, s.valid?(:fuga, "123")
  end

  def test_validated_rule()
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    assert_equal :hoge, s.validated_rule("123")
    assert_equal :fuga, s.validated_rule("abc")
    assert_equal nil, s.validated_rule("xyz")
  end

end
