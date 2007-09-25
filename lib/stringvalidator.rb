# $Id$
# Copyright (C) 2007 TOMITA Masahiro
# mailto:tommy@tmtm.org

class StringValidator
  class Error < StandardError
    def initialize(value, rule=nil)
      @rule = rule
      @value = value
      super self.class.errmsg
    end
    attr_reader :rule, :value

    def self.errmsg()
      @errmsg
    end
  end
  class Error::NotInteger < Error
    @errmsg = "not integer"
  end
  class Error::NotFloat < Error
    @errmsg = "not float"
  end
  class Error::OutOfRange < Error
    @errmsg = "out of range"
  end
  class Error::InvalidValue < Error
    @errmsg = "invalid value"
  end
  class Error::RegexpMismatch < Error
    @errmsg = "regexp mismatch"
  end
  class Error::InvalidLength < Error
    @errmsg = "invalid length"
  end
  class Error::TooShort < Error
    @errmsg = "too short"
  end
  class Error::TooLong < Error
    @errmsg = "too long"
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
    return self.class.validate(@rule[rule], str)
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
        return Integer(str)
      rescue ArgumentError
        raise Error::NotInteger.new(str, r)
      end
    end
    if r == Float then
      begin
        return Float(str)
      rescue ArgumentError
        raise Error::NotFloat.new(str, r)
      end
    end
    case r
    when Range then
      if r.first.is_a? Integer and r.last.is_a? Integer then
        validate(Integer, str)
        raise Error::OutOfRange.new(str, r) unless r.include?(str.to_i)
        return str.to_i
      elsif r.first.is_a? Numeric then
        validate(Float, str)
        raise Error::OutOfRange.new(str, r) unless r.include?(str.to_f)
        return str.to_f
      end
      raise  Error::OutOfRange.new(str, r) unless r.include?(str)
      return str
    when Regexp then
      raise Error::RegexpMismatch.new(str, r) unless r =~ str
      return str
    when Proc then
      ret = r.call(str)
      return ret if ret
      raise Error::InvalidValue.new(str, r)
    when Array then
      r.each do |i|
        begin
          return self.validate(i, str)
        rescue Error
          # dunno
        end
      end
      raise Error::InvalidValue.new(str, r)
    when Hash then
      r.each do |k,v|
        case k
        when :any
          return self.validate(v, str)
        when :all
          ret = nil
          v.each do |i|
            ret = self.validate(i, str)
          end
          return ret
        when :rule
          return self.validate(v, str)
        when :length
          begin
            self.validate v, str.length.to_s
            return str
          rescue Error
            raise Error::InvalidLength.new(str, r)
          end
        when :maxlength
          raise Error::TooLong.new(str, r) unless str.length <= v
          return str
        when :minlength
          raise Error::TooShort.new(str, r) unless str.length >= v
          return str
        when :maxcharlength
          raise Error::TooLong.new(str, r) unless str.split(//).length <= v
          return str
        when :mincharlength
          raise Error::TooShort.new(str, r) unless str.split(//).length >= v
          return str
        else
          raise ArgumentError, "Invalid key: #{k}"
        end
      end
      return true
    else
      return r if r.to_s == str
    end
    raise Error::InvalidValue.new(str, r)
  end

end
