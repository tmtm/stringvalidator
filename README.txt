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

str が "abc" または "def"？
{{{
StringValidator.validate([:ANY, "abc", "def"], str)
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
StringValidator.validate([:ALL, Integer, 1..255], str)
}}}

str の長さが 3〜10？
{{{
StringValidator.validate({:minlength=>3, :maxlength=>10}, str)
}}}

str の長さが 3〜10 で正規表現に一致？
{{{
StringValidator.validate({:minlength=>3, :maxlength=>10, rule=>/abc/}, str)
}}}
