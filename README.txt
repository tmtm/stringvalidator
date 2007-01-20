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
StringValidator.validate("abc", str)
}}}

str が正規表現に一致？
{{{
StringValidator.validate(/hoge/, str)
}}}

str が 123 の数値？
{{{
StringValidator.validate(123, str)
}}}

str が 1〜255 の数値？
{{{
StringValidator.validate(1..255, str)
}}}

str が 1〜255 の整数？
{{{
StringValidator.validate({:all=>[Integer, 1..255]}, str)
}}}

str が "abc" または "def"？
{{{
StringValidator.validate({:any=>["abc", "def"]}, str)
}}}

str の長さが 3〜10？
{{{
StringValidator.validate({:minlength=>3, :maxlength=>10}, str)
}}}

str の長さが 3〜10 で正規表現に一致？
{{{
StringValidator.validate({:minlength=>3, :maxlength=>10, rule=>/abc/}, str)
}}}

ブロックを呼び出した結果が真？
{{{
p = Proc.new{|a| a == "xyz"}
StringValidator.validate(p, "xyz")
}}}

複数のルールを定義して利用
{{{
rules = {
  :port => 1..65535,
  :domain => /\A[a-z0-9]+(\.[a-z0-9]+)+\z/i
}
v = StringValidator.new(rules)
v.validate(:port, "8080")
v.validate(:domain, "tmtm.org")
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

str が rule に一致しているかどうかを真偽値で返す。

rule は次のように評価される。

 Integer::
  整数かどうかを判定。

 Rangeオブジェクト::
  rule.include?(str) の結果を返す。
  rule.first が数値であれば rule.include?(str.to_f)。

 Regexpオブジェクト::
  rule =~ str の結果を返す。

 Procオブジェクト::
  rule.call(str) の結果を返す。

 Hashオブジェクト::
  Hash の各要素について以下を評価し、すべてが真であれば真を返す。

  :any => [ ... ]
    配列の各要素について validate() で評価し、ひとつでも真であれば真。
  :all => [ ... ]
    配列の各要素について validate() で評価し、すべてが真であれば真。
  :rule => obj
    obj を validate() で評価した結果を返す。
  :maxlength => n
    str の文字数が n 以下であれば真。
  :minlength => n
    str の文字数が n 以上であれば真。

==== StringValidator.new(rule_list, flag=true) ====

rule_list のルール群を持つ StringValidator オブジェクトを生成する。

rule_list は Hash で以下の形式。
{{{
  {
    name => rule, ...
  }
}}}

rule は StringValidator.validate() の第１引数と同じ形式で規則を指定する。

flag が true の場合は、StringValidator#validate() が条件を満たさない場合に StringValidator::Error 例外が発生する。

==== StringValidator#validate(rule_name, str) ====

rule_list[rule_name] の規則で str を評価する。
評価結果が偽の場合は、StringValidator::Error 例外が発生する。

==== StringValidator#validated_rule(str) ====

rule_list の各規則で str を評価し、一致した結果の name を返す。
どの規則にも一致しない場合は nil を返す。

rule_list の規則は name の順に評価される。
