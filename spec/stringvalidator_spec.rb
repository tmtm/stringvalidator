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
      expect(StringValidator.validate(Integer, "123")).to eq 123
      expect(StringValidator.validate(Integer, "0")).to eq 0
      expect(StringValidator.validate(Integer, "-213")).to eq(-213)
      expect{StringValidator.validate(Integer, "1.2")}.to raise_error StringValidator::Error::NotInteger, 'not integer'
      expect{StringValidator.validate(Integer, "a")}.to raise_error StringValidator::Error::NotInteger, 'not integer'
    end

    it 'Float' do
      expect(StringValidator.validate(Float, "1.23")).to eq 1.23
      expect(StringValidator.validate(Float, "123")).to eq 123
      expect(StringValidator.validate(Float, "0")).to eq 0
      expect(StringValidator.validate(Float, "-213")).to eq(-213)
      expect{StringValidator.validate(Float, "a")}.to raise_error StringValidator::Error::NotFloat, 'not float'
    end

    it 'Integer const' do
      r = 987
      expect(StringValidator.validate(r, "987")).to eq 987
      expect{StringValidator.validate(r, "986")}.to raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end

    it 'Range of Integer' do
      r = 3..45
      expect(StringValidator.validate(r, "3")).to eq 3
      expect(StringValidator.validate(r, "45")).to eq 45
      expect(StringValidator.validate(r, "10")).to eq 10
      expect{StringValidator.validate(r, "8.7")}.to raise_error StringValidator::Error::NotInteger, 'not integer'
      expect{StringValidator.validate(r, "2.9")}.to raise_error StringValidator::Error::NotInteger, 'not integer'
      expect{StringValidator.validate(r, "46")}.to raise_error StringValidator::Error::OutOfRange, 'out of range'
      expect{StringValidator.validate(r, "hoge")}.to raise_error StringValidator::Error::NotInteger, 'not integer'
    end

    it 'Range of Numeric' do
      r = 3.0 .. 45
      expect(StringValidator.validate(r, "3")).to eq 3
      expect(StringValidator.validate(r, "45")).to eq 45
      expect(StringValidator.validate(r, "10")).to eq 10
      expect(StringValidator.validate(r, "8.7")).to eq 8.7
      expect{StringValidator.validate(r, "2.9")}.to raise_error StringValidator::Error::OutOfRange, 'out of range'
      expect{StringValidator.validate(r, "46")}.to raise_error StringValidator::Error::OutOfRange, 'out of range'
      expect{StringValidator.validate(r, "hoge")}.to raise_error StringValidator::Error::NotFloat, 'not float'
    end

    it 'Range of String' do
      r = "abc" .. "xyz"
      expect(StringValidator.validate(r, "abc")).to eq "abc"
      expect(StringValidator.validate(r, "lmn")).to eq "lmn"
      expect(StringValidator.validate(r, "xyz")).to eq "xyz"
      expect{StringValidator.validate(r, "abb")}.to raise_error StringValidator::Error::OutOfRange, 'out of range'
      expect{StringValidator.validate(r, "xyzz")}.to raise_error StringValidator::Error::OutOfRange, 'out of range'
    end

    it 'String' do
      r = "hogehoge"
      expect(StringValidator.validate(r, "hogehoge")).to eq "hogehoge"
      expect{StringValidator.validate(r, "123")}.to raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end

    it 'Regexp' do
      r = /^[abc]$/
      expect(StringValidator.validate(r, "a")).to eq "a"
      expect(StringValidator.validate(r, "b")).to eq "b"
      expect(StringValidator.validate(r, "c")).to eq "c"
      expect(StringValidator.valid?(r, "abc")).to eq false
      expect(StringValidator.valid?(r, "A")).to eq false
      expect{StringValidator.validate(r, "abc")}.to raise_error StringValidator::Error::RegexpMismatch, 'regexp mismatch'
      expect{StringValidator.validate(r, "A")}.to raise_error StringValidator::Error::RegexpMismatch, 'regexp mismatch'
    end

    it 'Array' do
      a = [123, "abc", /xyz/i]
      expect(StringValidator.validate(a, "123")).to eq 123
      expect(StringValidator.validate(a, "abc")).to eq "abc"
      expect(StringValidator.validate(a, "xxxXyZzzz")).to eq "xxxXyZzzz"
      expect{StringValidator.validate(a, "789")}.to raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end

    it ':any' do
      any = {:any => [1, 2, 4, 8]}
      expect(StringValidator.validate(any, "1")).to eq 1
      expect(StringValidator.validate(any, "2")).to eq 2
      expect(StringValidator.validate(any, "4")).to eq 4
      expect(StringValidator.validate(any, "8")).to eq 8
      expect{StringValidator.validate(any, "5")}.to raise_error StringValidator::Error::InvalidValue, 'invalid value'
      expect{StringValidator.validate(any, "0")}.to raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end

    it ':all' do
      all = {:all => [Integer, 5..10]}
      expect(StringValidator.validate(all, "5")).to eq 5
      expect(StringValidator.validate(all, "7")).to eq 7
      expect(StringValidator.validate(all, "10")).to eq 10
      expect{StringValidator.validate(all, "8.5")}.to raise_error StringValidator::Error::NotInteger, 'not integer'
      expect{StringValidator.validate(all, "abc")}.to raise_error StringValidator::Error::NotInteger, 'not integer'
    end

    it ':rule' do
      hash = {:rule => /abc/}
      expect(StringValidator.validate(hash, "012abc345")).to eq "012abc345"
      expect{StringValidator.validate(hash, "12345")}.to raise_error StringValidator::Error::RegexpMismatch, 'regexp mismatch'
    end

    it ':length' do
      hash = {:length => 3}
      expect(StringValidator.validate(hash, "123")).to eq "123"
      expect{StringValidator.validate(hash, "1234")}.to raise_error StringValidator::Error::InvalidLength, 'invalid length'
    end

    it ':length as Range' do
      hash = {:length => 3..10}
      expect(StringValidator.validate(hash, "123")).to eq "123"
      expect(StringValidator.validate(hash, "1234567890")).to eq "1234567890"
      expect(StringValidator.validate(hash, "12345")).to eq "12345"
      expect{StringValidator.validate(hash, "12")}.to raise_error StringValidator::Error::InvalidLength, 'invalid length'
      expect{StringValidator.validate(hash, "12345678901")}.to raise_error StringValidator::Error::InvalidLength, 'invalid length'
    end

    it ':minlength' do
      hash = {:minlength => 3}
      expect(StringValidator.validate(hash, "1234")).to eq "1234"
      expect(StringValidator.validate(hash, "123")).to eq "123"
      expect{StringValidator.validate(hash, "12")}.to raise_error StringValidator::Error::TooShort, 'too short'
    end

    it ':maxlength' do
      hash = {:maxlength => 10}
      expect(StringValidator.validate(hash, "123456789")).to eq "123456789"
      expect(StringValidator.validate(hash, "1234567890")).to eq "1234567890"
      expect{StringValidator.validate(hash, "12345678901")}.to raise_error StringValidator::Error::TooLong, 'too long'
    end

    it ':charlength' do
      hash = {:charlength => 3}
      expect(StringValidator.validate(hash, "１２３")).to eq "１２３"
      expect{StringValidator.validate(hash, "１２")}.to raise_error StringValidator::Error::InvalidLength, 'invalid length'
      expect{StringValidator.validate(hash, "１２３４")}.to raise_error StringValidator::Error::InvalidLength, 'invalid length'
    end

    it ':charlength as Range' do
      hash = {:charlength => 3..10}
      expect(StringValidator.validate(hash, "１２３")).to eq "１２３"
      expect(StringValidator.validate(hash, "１２３４５６７８９０")).to eq "１２３４５６７８９０"
      expect(StringValidator.validate(hash, "１２３４５")).to eq "１２３４５"
      expect{StringValidator.validate(hash, "１２")}.to raise_error StringValidator::Error::InvalidLength, 'invalid length'
      expect{StringValidator.validate(hash, "１２３４５６７８９０１")}.to raise_error StringValidator::Error::InvalidLength, 'invalid length'
    end

    it ':mincharlength' do
      hash = {:mincharlength => 3}
      expect(StringValidator.validate(hash, "１２３４")).to eq "１２３４"
      expect(StringValidator.validate(hash, "１２３")).to eq "１２３"
      expect{StringValidator.validate(hash, "１２")}.to raise_error StringValidator::Error::TooShort, 'too short'
    end

    it ':maxcharlength' do
      hash = {:maxcharlength => 10}
      expect(StringValidator.validate(hash, "１２３４５６７８９")).to eq "１２３４５６７８９"
      expect(StringValidator.validate(hash, "１２３４５６７８９０")).to eq "１２３４５６７８９０"
      expect{StringValidator.validate(hash, "１２３４５６７８９０１")}.to raise_error StringValidator::Error::TooLong, 'too long'
    end

    it 'multiple rule' do
      hash = {
        :maxlength => 5,
        :rule => /\A\d+\z/,
      }
      str = "12345"
      expect(StringValidator.validate(hash, str)).to eq str
    end

    it ':rule, :any, :all' do
      hash = {
        :rule => proc{123},
        :any => ["12345", "abcde"],
        :all => [Integer, String],
      }
      str = "12345"
      expect(StringValidator.validate(hash, str)).to eq 123
    end

    it 'invalid hash' do
      hash = {:hoge => nil}
      begin
        expect{StringValidator.validate(hash, "hoge")}.to raise_error ArgumentError, 'Invalid key: hoge'
      end
    end

    it 'Proc' do
      p = Proc.new{|a| a == "xyz" && 123}
      expect(StringValidator.validate(p, "xyz")).to eq 123
      expect(StringValidator.validate(p, "abc")).to eq false
      p2 = Proc.new{raise "hoge"}
      expect{StringValidator.validate(p2, "abc")}.to raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end

    it 'Pathname' do
      r = Pathname
      expect(StringValidator.validate(r, "abcdefg")).to be_kind_of Pathname
      expect{StringValidator.validate(r, "abcd\0efg")}.to raise_error StringValidator::Error::InvalidValue, 'invalid value'
    end
  end

  it '#validate' do
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    expect(s.validate(:hoge, "123")).to eq 123
    expect(s.validate(:fuga, "abc")).to eq "abc"
    expect(s.validate(Integer, "123")).to eq 123
    expect(s.validate([:hoge, :fuga], "abc")).to eq "abc"
    expect{s.validate(:hoge, "abc")}.to raise_error StringValidator::Error::NotInteger, 'not integer'
    expect{s.validate(:fuga, "123")}.to raise_error StringValidator::Error::InvalidValue, 'invalid value'
    expect{s.validate(:hage, "123")}.to raise_error ArgumentError, 'No such rule: hage'
  end

  it '#valid?' do
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    expect(s.valid?(:hoge, "123")).to eq true
    expect(s.valid?(:fuga, "abc")).to eq true
    expect(s.valid?(:hoge, "abc")).to eq false
    expect(s.valid?(:fuga, "123")).to eq false
  end

  it '#validated_rule' do
    rule = {
      :hoge => Integer,
      :fuga => "abc",
    }
    s = StringValidator.new(rule)
    expect(s.validated_rule("123")).to eq :hoge
    expect(s.validated_rule("abc")).to eq :fuga
    expect(s.validated_rule("xyz")).to eq nil
  end
end
