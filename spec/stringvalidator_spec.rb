# -*- encoding: utf-8 -*-
# Copyright (C) 2009 TOMITA Masahiro
# mailto:tommy@tmtm.org

require "pathname"
require File.expand_path "../lib/stringvalidator", File.dirname(__FILE__)

describe StringValidator do
  before do
    unless "".respond_to? :encoding
      @kcode = $KCODE
      $KCODE = "U"
    end
  end

  after do
    $KCODE = @kcode if @kcode
  end

  describe '.validate' do
    it 'Integer' do
      StringValidator.validate(Integer, "123").should == 123
      StringValidator.validate(Integer, "0").should == 0
      StringValidator.validate(Integer, "-213").should == -213
      lambda{StringValidator.validate(Integer, "1.2")}.should raise_error StringValidator::Error::NotInteger, 'not integer'
      lambda{StringValidator.validate(Integer, "a")}.should raise_error StringValidator::Error::NotInteger, 'not integer'
    end

    it 'Float' do
      StringValidator.validate(Float, "1.23").should == 1.23
      StringValidator.validate(Float, "123").should == 123
      StringValidator.validate(Float, "0").should == 0
      StringValidator.validate(Float, "-213").should == -213
      lambda{StringValidator.validate(Float, "a")}.should raise_error StringValidator::Error::NotFloat, 'not float'
    end

    it 'Integer const' do
      r = 987
      StringValidator.validate(r, "987").should == 987
      lambda{StringValidator.validate(r, "986")}.should raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end

    it 'Range of Integer' do
      r = 3..45
      StringValidator.validate(r, "3").should == 3
      StringValidator.validate(r, "45").should == 45
      StringValidator.validate(r, "10").should == 10
      lambda{StringValidator.validate(r, "8.7")}.should raise_error StringValidator::Error::NotInteger, 'not integer'
      lambda{StringValidator.validate(r, "2.9")}.should raise_error StringValidator::Error::NotInteger, 'not integer'
      lambda{StringValidator.validate(r, "46")}.should raise_error StringValidator::Error::OutOfRange, 'out of range'
      lambda{StringValidator.validate(r, "hoge")}.should raise_error StringValidator::Error::NotInteger, 'not integer'
    end

    it 'Range of Numeric' do
      r = 3.0 .. 45
      StringValidator.validate(r, "3").should == 3
      StringValidator.validate(r, "45").should == 45
      StringValidator.validate(r, "10").should == 10
      StringValidator.validate(r, "8.7").should == 8.7
      lambda{StringValidator.validate(r, "2.9")}.should raise_error StringValidator::Error::OutOfRange, 'out of range'
      lambda{StringValidator.validate(r, "46")}.should raise_error StringValidator::Error::OutOfRange, 'out of range'
      lambda{StringValidator.validate(r, "hoge")}.should raise_error StringValidator::Error::NotFloat, 'not float'
    end

    it 'Range of String' do
      r = "abc" .. "xyz"
      StringValidator.validate(r, "abc").should == "abc"
      StringValidator.validate(r, "lmn").should == "lmn"
      StringValidator.validate(r, "xyz").should == "xyz"
      lambda{StringValidator.validate(r, "abb")}.should raise_error StringValidator::Error::OutOfRange, 'out of range'
      lambda{StringValidator.validate(r, "xyzz")}.should raise_error StringValidator::Error::OutOfRange, 'out of range'
    end

    it 'String' do
      r = "hogehoge"
      StringValidator.validate(r, "hogehoge").should == "hogehoge"
      lambda{StringValidator.validate(r, "123")}.should raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end

    it 'Regexp' do
      r = /^[abc]$/
      StringValidator.validate(r, "a").should == "a"
      StringValidator.validate(r, "b").should == "b"
      StringValidator.validate(r, "c").should == "c"
      StringValidator.valid?(r, "abc").should == false
      StringValidator.valid?(r, "A").should == false
      lambda{StringValidator.validate(r, "abc")}.should raise_error StringValidator::Error::RegexpMismatch, 'regexp mismatch'
      lambda{StringValidator.validate(r, "A")}.should raise_error StringValidator::Error::RegexpMismatch, 'regexp mismatch'
    end

    it 'Array' do
      a = [123, "abc", /xyz/i]
      StringValidator.validate(a, "123").should == 123
      StringValidator.validate(a, "abc").should == "abc"
      StringValidator.validate(a, "xxxXyZzzz").should == "xxxXyZzzz"
      lambda{StringValidator.validate(a, "789")}.should raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end

    it ':any' do
      any = {:any => [1, 2, 4, 8]}
      StringValidator.validate(any, "1").should == 1
      StringValidator.validate(any, "2").should == 2
      StringValidator.validate(any, "4").should == 4
      StringValidator.validate(any, "8").should == 8
      lambda{StringValidator.validate(any, "5")}.should raise_error StringValidator::Error::InvalidValue, 'invalid value'
      lambda{StringValidator.validate(any, "0")}.should raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end

    it ':all' do
      all = {:all => [Integer, 5..10]}
      StringValidator.validate(all, "5").should == 5
      StringValidator.validate(all, "7").should == 7
      StringValidator.validate(all, "10").should == 10
      lambda{StringValidator.validate(all, "8.5")}.should raise_error StringValidator::Error::NotInteger, 'not integer'
      lambda{StringValidator.validate(all, "abc")}.should raise_error StringValidator::Error::NotInteger, 'not integer'
    end

    it ':rule' do
      hash = {:rule => /abc/}
      StringValidator.validate(hash, "012abc345").should == "012abc345"
      lambda{StringValidator.validate(hash, "12345")}.should raise_error StringValidator::Error::RegexpMismatch, 'regexp mismatch'
    end

    it ':length' do
      hash = {:length => 3}
      StringValidator.validate(hash, "123").should == "123"
      lambda{StringValidator.validate(hash, "1234")}.should raise_error StringValidator::Error::InvalidLength, 'invalid length'
    end

    it ':length as Range' do
      hash = {:length => 3..10}
      StringValidator.validate(hash, "123").should == "123"
      StringValidator.validate(hash, "1234567890").should == "1234567890"
      StringValidator.validate(hash, "12345").should == "12345"
      lambda{StringValidator.validate(hash, "12")}.should raise_error StringValidator::Error::InvalidLength, 'invalid length'
      lambda{StringValidator.validate(hash, "12345678901")}.should raise_error StringValidator::Error::InvalidLength, 'invalid length'
    end

    it ':minlength' do
      hash = {:minlength => 3}
      StringValidator.validate(hash, "1234").should == "1234"
      StringValidator.validate(hash, "123").should == "123"
      lambda{StringValidator.validate(hash, "12")}.should raise_error StringValidator::Error::TooShort, 'too short'
    end

    it ':maxlength' do
      hash = {:maxlength => 10}
      StringValidator.validate(hash, "123456789").should == "123456789"
      StringValidator.validate(hash, "1234567890").should == "1234567890"
      lambda{StringValidator.validate(hash, "12345678901")}.should raise_error StringValidator::Error::TooLong, 'too long'
    end

    it ':charlength' do
      hash = {:charlength => 3}
      StringValidator.validate(hash, "１２３").should == "１２３"
      lambda{StringValidator.validate(hash, "１２")}.should raise_error StringValidator::Error::InvalidLength, 'invalid length'
      lambda{StringValidator.validate(hash, "１２３４")}.should raise_error StringValidator::Error::InvalidLength, 'invalid length'
    end

    it ':charlength as Range' do
      hash = {:charlength => 3..10}
      StringValidator.validate(hash, "１２３").should == "１２３"
      StringValidator.validate(hash, "１２３４５６７８９０").should == "１２３４５６７８９０"
      StringValidator.validate(hash, "１２３４５").should == "１２３４５"
      lambda{StringValidator.validate(hash, "１２")}.should raise_error StringValidator::Error::InvalidLength, 'invalid length'
      lambda{StringValidator.validate(hash, "１２３４５６７８９０１")}.should raise_error StringValidator::Error::InvalidLength, 'invalid length'
    end

    it ':mincharlength' do
      hash = {:mincharlength => 3}
      StringValidator.validate(hash, "１２３４").should == "１２３４"
      StringValidator.validate(hash, "１２３").should == "１２３"
      lambda{StringValidator.validate(hash, "１２")}.should raise_error StringValidator::Error::TooShort, 'too short'
    end

    it ':maxcharlength' do
      hash = {:maxcharlength => 10}
      StringValidator.validate(hash, "１２３４５６７８９").should == "１２３４５６７８９"
      StringValidator.validate(hash, "１２３４５６７８９０").should == "１２３４５６７８９０"
      lambda{StringValidator.validate(hash, "１２３４５６７８９０１")}.should raise_error StringValidator::Error::TooLong, 'too long'
    end

    it 'multiple rule' do
      hash = {
        :maxlength => 5,
        :rule => /\A\d+\z/,
      }
      str = "12345"
      StringValidator.validate(hash, str).should == str
    end

    it ':rule, :any, :all' do
      hash = {
        :rule => proc{123},
        :any => ["12345", "abcde"],
        :all => [Integer, String],
      }
      str = "12345"
      StringValidator.validate(hash, str).should == 123
    end

    it 'invalid hash' do
      hash = {:hoge => nil}
      begin
        lambda{StringValidator.validate(hash, "hoge")}.should raise_error ArgumentError, 'Invalid key: hoge'
      end
    end

    it 'Proc' do
      p = Proc.new{|a| a == "xyz" && 123}
      StringValidator.validate(p, "xyz").should == 123
      StringValidator.validate(p, "abc").should == false
      p2 = Proc.new{raise "hoge"}
      lambda{StringValidator.validate(p2, "abc")}.should raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end

    it 'Pathname' do
      r = Pathname
      StringValidator.validate(r, "abcdefg").should be_kind_of Pathname
      lambda{StringValidator.validate(r, "abcd\0efg")}.should raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end
  end

  it '#validate' do
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    s.validate(:hoge, "123").should == 123
    s.validate(:fuga, "abc").should == "abc"
    lambda{s.validate(:hoge, "abc")}.should raise_error StringValidator::Error::NotInteger, 'not integer'
    lambda{s.validate(:fuga, "123")}.should raise_error StringValidator::Error::InvalidValue, 'invalid value'
    lambda{s.validate(:hage, "123")}.should raise_error ArgumentError, 'No such rule: hage'
  end

  it '#valid?' do
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    s.valid?(:hoge, "123").should == true
    s.valid?(:fuga, "abc").should == true
    s.valid?(:hoge, "abc").should == false
    s.valid?(:fuga, "123").should == false
  end

  it '#validated_rule' do
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    s.validated_rule("123").should == :hoge
    s.validated_rule("abc").should == :fuga
    s.validated_rule("xyz").should == nil
  end
end
