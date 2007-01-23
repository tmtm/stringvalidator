= StringValidator =

文字列の形式/値を検証する。

== 作者 ==

とみたまさひろ <tommy@tmtm.org>

== ライセンス ==

Ruby ライセンス http://www.ruby-lang.org/ja/LICENSE.txt と同等。

== 機能 ==

 * 文字列が規則に従うかどうかの検査。
 * 規則は Ruby のリテラルで記述する。

== ダウンロード ==

 * http://tmtm.org/downloads/ruby/stringvalidator/

== インストール ==

{{{
$ make
$ make test
# make install
}}}

== 使用例 ==

str が "abc"？
{{{
StringValidator.valid?("abc", str)
}}}

str が正規表現に一致？
{{{
StringValidator.valid?(/hoge/, str)
}}}

str が 123 の数値？
{{{
StringValidator.valid?(123, str)
}}}

str が 1〜255 の整数？
{{{
StringValidator.valid?(1..255, str)
}}}

str が 1〜255 の数値？
{{{
StringValidator.valid?(1.0..255, str)
}}}

str が "abc" または "def"？
{{{
StringValidator.valid?(["abc", "def"], str)
}}}

str の長さが 3〜10？
{{{
StringValidator.valid?({:length=>3..10}, str)
}}}

str の長さが 10文字以上で正規表現に一致？
{{{
StringValidator.valid?({:minlength=>10, rule=>/abc/}, str)
}}}

ブロックを呼び出した結果が真？
{{{
p = Proc.new{|a| a == "xyz"}
StringValidator.valid?(p, "xyz")
}}}

複数のルールを定義して利用
{{{
rules = {
  :port => 1..65535,
  :domain => /\A[a-z0-9-]+(\.[a-z0-9-]+)+\z/i
}
v = StringValidator.new(rules)
v.valid?(:port, "8080")
v.valid?(:domain, "tmtm.org")
}}}

どのルールに適合したか？
{{{
rules = {
  :port => 1..65535,
  :domain => /\A[a-z0-9]+(\.[a-z0-9]+)+\z/i
}
v = StringValidator.new(rules)
v.validated_rule("8080")     # => :port
v.validated_rule("tmtm.org") # => :domain
v.validated_rule("xyz")      # => nil
}}}

=== メソッド ===

==== StringValidator.validate(rule, str) ====

str が rule に適合しなければ例外を発生させる。

rule は次のように評価される。

 Integer::
  整数かどうか。

  例外:
  * StringValidator::Error::NotInteger

 Float::
  実数かどうか。

  例外:
  * StringValidator::Error::NotFloat

 Rangeオブジェクト::
  rule.first と rule.last が整数であれば、rule.include?(str.to_i)。

  例外:
   * StringValidator::Error::OutOfRange (範囲外)
   * StringValidator::Error::NotInteger (str が整数でない)

  rule.first が実数であれば、rule.include?(str.to_f)。

  例外:
   * StringValidator::Error::OutOfRange (範囲外)
   * StringValidator::Error::NotFloat (str が実数でない)

  それ以外の場合、rule.include?(str)。

  例外:
   * StringValidator::Error::OutOfRange (範囲外)

 Regexpオブジェクト::
  rule =~ str が真。

  例外:
   * StringValidator::Error::RegexpMismatch (非適合)

 Procオブジェクト::
  rule.call(str) が真

  例外:
   * StringValidator::Error::InvalidValue (結果が偽)

 Arrayオブジェクト::
  配列の各要素について valid?() で評価し、ひとつでも真であれば真

  例外:
   * StringValidator::Error::InvalidValue (結果が偽)

 Hashオブジェクト::
  Hash の各要素について以下を評価し、すべてが真であれば真

  :any => [ ... ]
    配列の各要素について valid?() で評価し、ひとつでも真であれば真。Array と同じ。
  :all => [ ... ]
    配列の各要素について validate() で評価し、すべてが真であれば真。
  :rule => obj
    obj を validate() で評価。
  :length => obj
    obj が Range オブジェクトの場合は obj.include? str.length。
    そうでなければ、obj == str.length。
  :maxlength => n
    str の文字数が n 以下であれば真。
  :minlength => n
    str の文字数が n 以上であれば真。

  例外:
   * StringValidator::Error::InvalidValue (:ary に非適合)
   * StringValidator::Error::InvalidLength (:length に非適合)
   * StringValidator::Error::TooLong (:maxlength に非適合)
   * StringValidator::Error::TooShort (:minlength に非適合)

 上記以外::
  rule.to_s == str を評価。

  例外:
   * StringValidator::Error::InvalidValue (非適合)

==== StringValidator.valid?(rule, str) ====

validate(rule, str) と同じ評価を行ない、結果を true / false で返す。

==== StringValidator.new(rule_list) ====

rule_list のルール群を持つ StringValidator オブジェクトを生成する。

rule_list は Hash で以下の形式。
{{{
  {
    name => rule, ...
  }
}}}

rule は StringValidator.validate() の第１引数と同じ形式で規則を指定する。

==== StringValidator#validate(rule_name, str) ====

rule_list[rule_name] の規則で str を評価する。
適合しない場合は StringValidator::Error::* の例外が発生する。

==== StringValidator#valid?(rule_name, str) ====

StringValidator#validator(rule_name, str) と同じだが、結果を true / false で返す。

==== StringValidator#validated_rule(str) ====

rule_list の各規則で str を評価し、一致した結果の name を返す。
どの規則にも一致しない場合は nil を返す。

rule_list の規則は name の順に評価される。
