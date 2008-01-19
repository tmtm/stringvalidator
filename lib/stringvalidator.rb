# $Id$
# Copyright (C) 2007 TOMITA Masahiro
# mailto:tommy@tmtm.org
#
# = StringValidator
# Author:: TOMITA Masahiro <tommy@tmtm.org>
# License:: Ruby's. see http://www.ruby-lang.org/en/LICENSE.txt
#
# * 文字列が規則に従うかどうかを検査する
# * 規則は Ruby のリテラルで記述する。
#
# == Download
# * http://rubyforge.org/frs/?group_id=4776
# * http://tmtm.org/downloads/ruby/stringvalidator/
#
# == Install
#  $ make
#  $ make test
#  # make install
#
# == Usage
# StringValidator.validate(_rule_, _str) は _str_ が _rule_ に適合していれば、_rule_ に適したオブジェクトを返す。
# 適合しなければ StringValidator::Error 例外が発生する。
#
#  StringValidator.validate "abc", "abc"              # => "abc"
#  StringValidator.validate /hoge/, "ahoge"           # => "ahoge"
#  StringValidator.validate Integer, "123"            # => 123
#  StringValidator.validate 123, "123"                # => 123
#  StringValidator.validate 1..255, "128"             # => 128
#  StringValidator.validate 1.0..255, "10.9"          # => 10.9
#  str = "abc"
#  StringValidator.validate ["abc", "def"], str       # => str
#  StringValidator.validate({:length=>3..10}, str)    # => str
#  StringValidator.validate({:minlength=>3, :rule=>/abc/}, str)      # => str
#  StringValidator.validate Proc.new{|a| a == "abc" && 999}, str     # =>999
#  StringValidator.validate Proc.new{|s| Date.parse s}, "2007-10-02" # => Date object
#
# StringValidator.valid?(_rule_, _str_) は _str_ が _rule_ に適合していれば true、そうでなければ false を返す。
#
# 複数ルールの定義
#
#  rules = {
#    :port => 1..65535,
#    :domain => /\A[a-z0-9-]+(\.[a-z0-9-]+)+\z/i,
#  }
#  v = StringValidator.new rules
#  v.valid? :port, "8080"
#  v.valid? :domain, "tmtm.org"
#
# どのルールが適合したか
#
#   rules = {
#     :port => 1..65535,
#     :domain => /\A[a-z0-9]+(\.[a-z0-9]+)+\z/i
#   }
#   v = StringValidator.new rules
#   v.validated_rule "8080"     # => :port
#   v.validated_rule "tmtm.org" # => :domain
#   v.validated_rule "xyz"      # => nil

# == 文字列の正当性チェック
class StringValidator
  # エラーの基底クラス
  class Error < StandardError
    # _value_:: 対象文字列
    # _rule_:: ルールオブジェクト
    def initialize(value=nil, rule=nil)
      @rule = rule
      @value = value
      super self.class.errmsg
    end
    attr_reader :rule, :value

    def self.errmsg()
      @errmsg
    end
  end

  # Integer に適合しない場合
  class Error::NotInteger < Error
    @errmsg = "not integer"
  end
  # Float に適合しない場合
  class Error::NotFloat < Error
    @errmsg = "not float"
  end
  # Range に適合しない場合
  class Error::OutOfRange < Error
    @errmsg = "out of range"
  end
  # Array, Proc, Class に適合しない場合
  class Error::InvalidValue < Error
    @errmsg = "invalid value"
  end
  # Regexp に適合しない場合
  class Error::RegexpMismatch < Error
    @errmsg = "regexp mismatch"
  end
  # Hash(:length, :charlength) に適合しない場合
  class Error::InvalidLength < Error
    @errmsg = "invalid length"
  end
  # Hash(:minlength, :mincharlength) に適合しない場合
  class Error::TooShort < Error
    @errmsg = "too short"
  end
  # Hash(:maxlength, :maxcharlength) に適合しない場合
  class Error::TooLong < Error
    @errmsg = "too long"
  end

  # _rule_:: ルールオブジェクト
  # _str_:: 対象文字列
  #
  # _str_ が _rule_ に適合するか検査する。
  # 適合しない場合、StringValidator::Error 例外が発生する。
  #
  # === _rule_ の形式
  #
  # ==== Integer (Integer そのもの。Integer オブジェクトではない)
  # Integer(_str_) が成功した場合に _str_ を正当とみなす。
  # Integer オブジェクトを返す。
  # ==== Float (Float そのもの。Float オブジェクトではない)
  # Float(_str_) が成功した場合に _str_ を正当とみなす。
  # Float オブジェクトを返す。
  # ==== Range オブジェクト
  # _rule_ が _str_ を含んでいれば _str_ を正当とみなす。
  # _rule_ に応じて、Integer, Float, String オブジェクトを返す。
  # ==== Regexp オブジェクト
  # _str_ が _rule_ に適合すれば _str_ を正当とみなす。
  # _str_ を返す。
  # ==== Proc オブジェクト
  # _rule_.call(_str_) の結果が真であれば _str_ を正当とみなす。
  # _rule_.call(_str_) の結果を返す。
  # ==== Array オブジェクト
  # _rule_ の要素をルールとして評価し、正当な要素が一つでもあれば正当とみなす。
  # 最初に正当になったルールの結果を返す。
  # ==== Hash オブジェクト
  # 複数のルールが指定された場合は、すべてのルールを満たせば正当とみなす。
  # 結果は、:rule(なければ :any, :all)の評価結果。:rule, :any, :all のいずれもなければ str が評価結果となる。
  # [<tt>:any => _array_</tt>]
  #  Array と同じ。
  # [<tt>:all => _array_</tt>]
  #  _rule_ の要素をルールとして評価し、すべての要素が正当であれば正当とみなす。
  #  評価結果は、各ルールの評価結果の配列。
  # [<tt>:rule => _obj_</tt>]
  #  _obj_ をルールとして評価する。
  # [<tt>:length => _integer_ or _range_</tt>]
  #  _str_ の長さ(バイト数)が _integer_ に一致する場合、または _range_ 内であれば正当とみなす。
  #  評価結果は _str_。
  # [<tt>:maxlength => _integer_</tt>]
  #  _str_ の長さ(バイト数)が _integer_ 以下であれば正当とみなす。
  #  評価結果は _str_。
  # [<tt>:minlength => _integer_</tt>]
  #  _str_ の長さ(バイト数)が _integer_ 以上であれば正当とみなす。
  #  評価結果は _str_。
  # [<tt>:charlength => _integer_ or _range_</tt>]
  #  _str_ の長さ(文字数)が _integer_ に一致する場合、または _range_ 内であれば正当とみなす。文字数は $KCODE に依存する。
  #  評価結果は _str_。
  # [<tt>:maxcharlength => _integer_</tt>]
  #  _str_ の長さ(文字数)が _integer_ 以下であれば正当とみなす。文字数は $KCODE に依存する。
  #  評価結果は _str_。
  # [<tt>:mincharlength => _integer_</tt>]
  #  _str_ の長さ(文字数)が _integer_ 以上であれば正当とみなす。文字数は $KCODE に依存する。
  #  評価結果は _str_。
  # ==== Class オブジェクト
  # _rule_.new(_str_) が成功すれば正当とみなす。
  # _rule_.new(_str_) を返す。
  # ==== other
  # _str_ が _rule_.to_s と等しければ正当とみなす。
  # _rule_ を返す。
  #
  def self.validate(rule, str)
    if rule == Integer then
      begin
        return Integer(str)
      rescue ArgumentError
        raise Error::NotInteger.new(str, rule)
      end
    end
    if rule == Float then
      begin
        return Float(str)
      rescue ArgumentError
        raise Error::NotFloat.new(str, rule)
      end
    end
    case rule
    when Range then
      if rule.first.is_a? Integer and rule.last.is_a? Integer then
        validate(Integer, str)
        raise Error::OutOfRange.new(str, rule) unless rule.include?(str.to_i)
        return str.to_i
      elsif rule.first.is_a? Numeric then
        validate(Float, str)
        raise Error::OutOfRange.new(str, rule) unless rule.include?(str.to_f)
        return str.to_f
      end
      raise  Error::OutOfRange.new(str, rule) unless rule.include?(str)
      return str
    when Regexp then
      raise Error::RegexpMismatch.new(str, rule) unless rule =~ str
      return str
    when Proc then
      ret = rule.call(str)
      return ret if ret
      raise Error::InvalidValue.new(str, rule)
    when Array then
      rule.each do |i|
        begin
          return self.validate(i, str)
        rescue Error
          nil
        end
      end
      raise Error::InvalidValue.new(str, rule)
    when Hash then
      ret = {}
      rule.each do |k,v|
        case k
        when :any
          ret[k] = self.validate(v, str)
        when :all
          ret[k] = v.map{|i| self.validate(i, str)}.first
        when :rule
          ret[k] = self.validate(v, str)
        when :length
          begin
            self.validate v, str.length.to_s
          rescue Error
            raise Error::InvalidLength.new(str, rule)
          end
        when :maxlength
          raise Error::TooLong.new(str, rule) unless str.length <= v
        when :minlength
          raise Error::TooShort.new(str, rule) unless str.length >= v
        when :charlength
          begin
            self.validate v, str.split(//).length.to_s
          rescue Error
            raise Error::InvalidLength.new(str, rule)
          end
        when :maxcharlength
          raise Error::TooLong.new(str, rule) unless str.split(//).length <= v
        when :mincharlength
          raise Error::TooShort.new(str, rule) unless str.split(//).length >= v
        else
          raise ArgumentError, "Invalid key: #{k}"
        end
      end
      return ret[:rule] || ret[:any] || ret[:all] || str
    when Class then
      begin
        return rule.new(str)
      rescue
        raise Error::InvalidValue.new(str, rule)
      end
    else
      return rule if rule.to_s == str
    end
    raise Error::InvalidValue.new(str, rule)
  end

  # _rule_:: ルールオブジェクト
  # _str_:: 対象文字列
  #
  # validate(_rule_, _str_) が成功すれば true, そうでなければ false を返す。
  #
  def self.valid?(rule, str)
    begin
      self.validate(rule, str)
    rescue Error
      return false
    end
    return true
  end

  # _rule_:: Hash オブジェクト。{:key => rule_object, ...}
  def initialize(rule)
    @rule = rule
  end

  # _rule_:: ルールキー。initialize に与えた Hash のキー
  # _str_:: 対象文字列
  #
  # StringValidator.validate(@rule[_rule_], _str_) と同じ。
  #
  def validate(rule, str)
    raise ArgumentError, "No such rule: #{rule}" unless @rule.key? rule
    return self.class.validate(@rule[rule], str)
  end

  # _rule_:: ルールキー。initialize に与えた Hash のキー
  # _str_:: 対象文字列
  #
  # StringValidator#validate(_rule_, _str) が成功すれば true, そうでなければ false を返す。
  #
  def valid?(rule, str)
    begin
      validate(rule, str)
    rescue Error
      return false
    end
    return true
  end

  # _str_:: 対象文字列
  #
  # initialize に与えた Hash のキーのルールを順に評価し、最初に適合したキー値を返す。
  # 適合したルールがない場合は nil を返す。
  def validated_rule(str)
    @rule.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
      if self.class.valid?(@rule[k], str) then
        return k
      end
    end
    return nil
  end

end
