# $Id$
# Copyright (C) 2007 TOMITA Masahiro
# mailto:tommy@tmtm.org

class StringValidator
  class Error < StandardError
  end

  def initialize(rule)
    @rule = rule
  end

  def validate(str, raise_flag=true)
    @rule.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
      if self.class.validate(@rule[k], str) then
        return k
      end
    end
    raise Error, str if raise_flag
    return nil
  end

  def validate_rule(rule, str)
    raise ArgumentError, "No such rule: #{rule}" unless @rule.key? rule
    self.class.validate(@rule[rule], str)
  end

  def self.validate(r, str)
    if r == Integer then
      begin
        Integer(str)
        return true
      rescue ArgumentError
        return false
      end
    end
    case r
    when Range then
      if r.first.is_a? Numeric then
        return r.include?(str.to_f)
      end
      return r.include?(str)
    when Regexp then
      return r =~ str
    when Array then
      case r.first
      when :ANY
        return r[1..-1].any?{|i| validate(i, str)}
      when :ALL
        return r[1..-1].all?{|i| validate(i, str)}
      else
        raise ArgumentError, "First argument must be :ALL or :ANY: #{r.inspect}"
      end
    when Hash then
      r.each do |k,v|
        case k
        when :rule
          return false if self.class.validate(v, str)
        when :maxlength
          return false if str.length > v
        when :minlength
          return false if str.length < v
        else
          raise ArgumentError, "Invalid key: #{k}"
        end
      end
      return true
    when Proc then
      return r.call(str)
    else
      return true if r.to_s == str
    end
    return false
  end

end
