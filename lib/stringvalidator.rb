# $Id$
# Copyright (C) 2007 TOMITA Masahiro
# mailto:tommy@tmtm.org

class StringValidator
  class Error < StandardError
  end

  def initialize(rule, raise_flag=true)
    @rule = rule
    @raise_flag = raise_flag
  end

  def validated_rule(str)
    @rule.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
      if self.class.validate(@rule[k], str) then
        return k
      end
    end
    return nil
  end

  def validate(rule, str)
    raise ArgumentError, "No such rule: #{rule}" unless @rule.key? rule
    ret = self.class.validate(@rule[rule], str)
    raise Error, str if @raise_flag and not ret
    return ret
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
    when Proc then
      return r.call(str)
    when Hash then
      r.each do |k,v|
        case k
        when :any
          return false if not v.any?{|i|validate(i, str)}
        when :all
          return false if not v.all?{|i|validate(i, str)}
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
    else
      return true if r.to_s == str
    end
    return false
  end

end
