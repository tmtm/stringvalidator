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
    assert_equal true, StringValidator.valid?(Integer, "123")
    assert_equal true, StringValidator.valid?(Integer, "0")
    assert_equal true, StringValidator.valid?(Integer, "-213")
    assert_equal false, StringValidator.valid?(Integer, "1.2")
    assert_equal false, StringValidator.valid?(Integer, "a")
    assert_equal 123, StringValidator.validate(Integer, "123")
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(Integer, "a")}
  end

  def test_valid_float()
    assert_equal true, StringValidator.valid?(Float, "1.23")
    assert_equal true, StringValidator.valid?(Float, "123")
    assert_equal true, StringValidator.valid?(Float, "0")
    assert_equal true, StringValidator.valid?(Float, "-213")
    assert_equal false, StringValidator.valid?(Float, "a")
    assert_equal 1.23, StringValidator.validate(Float, "1.23")
    assert_raises(StringValidator::Error::NotFloat){StringValidator.validate(Float, "a")}
  end

  def test_valid_integer_const()
    r = 987
    assert_equal true, StringValidator.valid?(r, "987")
    assert_equal false, StringValidator.valid?(r, "986")
    assert_equal 987, StringValidator.validate(r, "987")
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(r, "986")}
  end

  def test_valid_int_range()
    r = 3..45
    assert_equal true, StringValidator.valid?(r, "3")
    assert_equal true, StringValidator.valid?(r, "45")
    assert_equal true, StringValidator.valid?(r, "10")
    assert_equal false, StringValidator.valid?(r, "8.7")
    assert_equal false, StringValidator.valid?(r, "2.9")
    assert_equal false, StringValidator.valid?(r, "46")
    assert_equal false, StringValidator.valid?(r, "hoge")
    assert_equal 10, StringValidator.validate(r, "10")
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(r, "2.9")}
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "46")}
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(r, "hoge")}
  end

  def test_valid_num_range()
    r = 3.0 .. 45
    assert_equal true, StringValidator.valid?(r, "3")
    assert_equal true, StringValidator.valid?(r, "45")
    assert_equal true, StringValidator.valid?(r, "10")
    assert_equal true, StringValidator.valid?(r, "8.7")
    assert_equal false, StringValidator.valid?(r, "2.9")
    assert_equal false, StringValidator.valid?(r, "46")
    assert_equal false, StringValidator.valid?(r, "hoge")
    assert_equal 10, StringValidator.validate(r, "10")
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "2.9")}
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "46")}
    assert_raises(StringValidator::Error::NotFloat){StringValidator.validate(r, "hoge")}
  end

  def test_valid_num_str()
    r = "abc" .. "xyz"
    assert_equal true, StringValidator.valid?(r, "abc")
    assert_equal true, StringValidator.valid?(r, "tommy")
    assert_equal true, StringValidator.valid?(r, "xyz")
    assert_equal false, StringValidator.valid?(r, "abb")
    assert_equal false, StringValidator.valid?(r, "xyzz")
    assert_equal "tommy", StringValidator.validate(r, "tommy")
    assert_raises(StringValidator::Error::OutOfRange){StringValidator.validate(r, "zzz")}
  end

  def test_valid_str()
    r = "hogehoge"
    assert_equal true, StringValidator.valid?(r, "hogehoge")
    assert_equal false, StringValidator.valid?(r, "123")
    assert_equal "hogehoge", StringValidator.validate(r, "hogehoge")
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(r, "123")}
  end

  def test_valid_regexp()
    r = /^[abc]$/
    assert_equal true, StringValidator.valid?(r, "a")
    assert_equal true, StringValidator.valid?(r, "b")
    assert_equal true, StringValidator.valid?(r, "c")
    assert_equal false, StringValidator.valid?(r, "abc")
    assert_equal false, StringValidator.valid?(r, "A")
    assert_equal "a", StringValidator.validate(r, "a")
    assert_raises(StringValidator::Error::RegexpMismatch){StringValidator.validate(r, "A")}
  end

  def test_valid_array()
    a = [123, "abc", /xyz/i]
    assert_equal true, StringValidator.valid?(a, "123")
    assert_equal true, StringValidator.valid?(a, "abc")
    assert_equal true, StringValidator.valid?(a, "xxxXyZzzz")
    assert_equal false, StringValidator.valid?(a, "789")
    assert_equal "abc", StringValidator.validate(a, "abc")
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(a, "789")}
  end

  def test_valid_any()
    any = {:any => [1, 2, 4, 8]}
    assert_equal true, StringValidator.valid?(any, "1")
    assert_equal true, StringValidator.valid?(any, "2")
    assert_equal true, StringValidator.valid?(any, "4")
    assert_equal true, StringValidator.valid?(any, "8")
    assert_equal false, StringValidator.valid?(any, "5")
    assert_equal false, StringValidator.valid?(any, "0")
    assert_equal 1, StringValidator.validate(any, "1")
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(any, "0")}
  end

  def test_valid_all()
    all = {:all => [Integer, 5..10]}
    assert_equal true, StringValidator.valid?(all, "5")
    assert_equal true, StringValidator.valid?(all, "7")
    assert_equal true, StringValidator.valid?(all, "10")
    assert_equal false, StringValidator.valid?(all, "8.5")
    assert_equal false, StringValidator.valid?(all, "abc")
    assert_equal 7, StringValidator.validate(all, "7")
    assert_raises(StringValidator::Error::NotInteger){StringValidator.validate(all, "abc")}
  end

  def test_valid_rule()
    hash = {
      :rule => /abc/,
    }
    assert_equal true, StringValidator.valid?(hash, "012abc345")
    assert_equal false, StringValidator.valid?(hash, "12345")
    assert_equal "012abc345", StringValidator.validate(hash, "012abc345")
    assert_raises(StringValidator::Error::RegexpMismatch){StringValidator.validate(hash, "12345")}
  end

  def test_valid_length()
    hash = {
      :length => 3,
    }
    assert_equal true, StringValidator.valid?(hash, "123")
    assert_equal false, StringValidator.valid?(hash, "12")
    assert_equal false, StringValidator.valid?(hash, "1234")
    assert_equal "123", StringValidator.validate(hash, "123")
    assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "1234")}
  end

  def test_valid_length_range()
    hash = {
      :length => 3..10,
    }
    assert_equal true, StringValidator.valid?(hash, "123")
    assert_equal true, StringValidator.valid?(hash, "1234567890")
    assert_equal true, StringValidator.valid?(hash, "12345")
    assert_equal false, StringValidator.valid?(hash, "12")
    assert_equal false, StringValidator.valid?(hash, "12345678901")
    assert_equal "123", StringValidator.validate(hash, "123")
    assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "12345678901")}
  end

  def test_valid_minlength()
    hash = {
      :minlength => 3,
    }
    assert_equal true, StringValidator.valid?(hash, "1234")
    assert_equal true, StringValidator.valid?(hash, "123")
    assert_equal false, StringValidator.valid?(hash, "12")
    assert_equal "123", StringValidator.validate(hash, "123")
    assert_raises(StringValidator::Error::TooShort){StringValidator.validate(hash, "12")}
  end

  def test_valid_maxlength()
    hash = {
      :maxlength => 10,
    }
    assert_equal true, StringValidator.valid?(hash, "123456789")
    assert_equal true, StringValidator.valid?(hash, "1234567890")
    assert_equal false, StringValidator.valid?(hash, "12345678901")
    assert_equal "123456789", StringValidator.validate(hash, "123456789")
    assert_raises(StringValidator::Error::TooLong){StringValidator.validate(hash, "12345678901")}
  end

  def test_valid_charlength()
    kcode = $KCODE
    $KCODE = "U"
    hash = {
      :charlength => 3,
    }
    begin
      assert_equal true, StringValidator.valid?(hash, "１２３")
      assert_equal false, StringValidator.valid?(hash, "１２")
      assert_equal false, StringValidator.valid?(hash, "１２３４")
      assert_equal "１２３", StringValidator.validate(hash, "１２３")
      assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "１２３４")}
    ensure
      $KCODE = kcode
    end
  end

  def test_valid_charlength_range()
    kcode = $KCODE
    $KCODE = "U"
    hash = {
      :charlength => 3..10,
    }
    begin
      assert_equal true, StringValidator.valid?(hash, "１２３")
      assert_equal true, StringValidator.valid?(hash, "１２３４５６７８９０")
      assert_equal true, StringValidator.valid?(hash, "１２３４５")
      assert_equal false, StringValidator.valid?(hash, "１２")
      assert_equal false, StringValidator.valid?(hash, "１２３４５６７８９０１")
      assert_equal "１２３", StringValidator.validate(hash, "１２３")
      assert_raises(StringValidator::Error::InvalidLength){StringValidator.validate(hash, "１２３４５６７８９０１")}
    ensure
      $KCODE = kcode
    end
  end

  def test_valid_mincharlength()
    kcode = $KCODE
    $KCODE = "U"
    hash = {
      :mincharlength => 3,
    }
    begin
      assert_equal true, StringValidator.valid?(hash, "１２３４")
      assert_equal true, StringValidator.valid?(hash, "１２３")
      assert_equal false, StringValidator.valid?(hash, "１２")
      assert_equal "１２３", StringValidator.validate(hash, "１２３")
      assert_raises(StringValidator::Error::TooShort){StringValidator.validate(hash, "１２")}
    ensure
      $KCODE = kcode
    end
  end

  def test_valid_maxcharlength()
    kcode = $KCODE
    $KCODE = "U"
    hash = {
      :maxcharlength => 10,
    }
    begin
      assert_equal true, StringValidator.valid?(hash, "１２３４５６７８９")
      assert_equal true, StringValidator.valid?(hash, "１２３４５６７８９０")
      assert_equal false, StringValidator.valid?(hash, "１２３４５６７８９０１")
      assert_equal "１２３４５６７８９", StringValidator.validate(hash, "１２３４５６７８９")
      assert_raises(StringValidator::Error::TooLong){StringValidator.validate(hash, "１２３４５６７８９０１")}
    ensure
      $KCODE = kcode
    end
  end

  def test_valid_invalid_hash
    hash = {
      :hoge => nil,
    }
    begin
      assert_raises(ArgumentError){StringValidator.validate(hash, "hoge")}
    end
  end

  def test_valid_proc()
    p = Proc.new{|a| a == "xyz" && 123}
    assert_equal true, StringValidator.valid?(p, "xyz")
    assert_equal false, StringValidator.valid?(p, "abc")
    assert_equal 123, StringValidator.validate(p, "xyz")
    assert_raises(StringValidator::Error::InvalidValue){StringValidator.validate(p, "abc")}
  end

  require "pathname"
  def test_valid_class()
    r = Pathname
    assert_equal true, StringValidator.valid?(r, "abcdefg")
    assert_equal false, StringValidator.valid?(r, "abcd\0efg")
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

  def test_valid_rules()
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
