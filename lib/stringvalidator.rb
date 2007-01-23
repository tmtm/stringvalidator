# $Id$
# Copyright (C) 2007 TOMITA Masahiro
# mailto:tommy@tmtm.org

class StringValidator
  class Error < StandardError
  end
  class Error::NotInteger < Error
  end
  class Error::NotFloat < Error
  end
  class Error::OutOfRange < Error
  end
  class Error::InvalidValue < Error
  end
  class Error::RegexpMismatch < Error
  end
  class Error::InvalidLength < Error
  end
  class Error::TooShort < Error
  end
  class Error::TooLong < Error
  end

  def initialize(rule)
    @rule = rule
  end

  def validated_rule(str)
    @rule.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
      if self.class.valid?(@rule[k], str) then
        return k
      end
    end
    return nil
  end

  def valid?(rule, str)
    begin
      validate(rule, str)
    rescue Error
      return false
    end
    return true
  end

  def validate(rule, str)
    raise ArgumentError, "No such rule: #{rule}" unless @rule.key? rule
    ret = self.class.validate(@rule[rule], str)
    return ret
  end

  def self.valid?(r, str)
    begin
      self.validate(r, str)
    rescue Error
      return false
    end
    return true
  end

  def self.validate(r, str)
    if r == Integer then
      begin
        Integer(str)
        return true
      rescue ArgumentError
        raise Error::NotInteger, str
      end
    end
    if r == Float then
      begin
        Float(str)
        return true
      rescue ArgumentError
        raise Error::NotFloat, str
      end
    end
    case r
    when Range then
      if r.first.is_a? Integer and r.last.is_a? Integer then
        validate(Integer, str)
        raise Error::OutOfRange, str unless r.include?(str.to_i)
        return true
      elsif r.first.is_a? Numeric then
        validate(Float, str)
        raise Error::OutOfRange, str unless r.include?(str.to_f)
        return true
      end
      raise  Error::OutOfRange, str unless r.include?(str)
      return true
    when Regexp then
      raise Error::RegexpMismatch, str unless r =~ str
      return true
    when Proc then
      raise Error::InvalidValue, str unless r.call(str)
      return true
    when Array then
      raise Error::InvalidValue, str unless r.any?{|i| self.valid?(i, str)}
      return true
    when Hash then
      r.each do |k,v|
        case k
        when :any
          raise Error::InvalidValue, str unless v.any?{|i| self.valid?(i, str)}
        when :all
          v.each{|i| self.validate(i, str)}
        when :rule
          self.validate(v, str)
        when :length
          if v.is_a? Range then
            raise Error::InvalidLength, str unless v.include? str.length
          else
            raise Error::InvalidLength, str unless str.length == v
          end
        when :maxlength
          raise Error::TooLong, str unless str.length <= v
        when :minlength
          raise Error::TooShort, str unless str.length >= v
        else
          raise ArgumentError, "Invalid key: #{k}"
        end
      end
      return true
    else
      return true if r.to_s == str
    end
    raise Error::InvalidValue, str
  end

end
