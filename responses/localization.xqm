xquery version "3.0";

module namespace _ = "urn:sur2html";

(: Localization functions (like localization.xsl) :)

declare variable $_:dict := doc('../dict-de.xml');

declare function _:dict($id as xs:string?) as xs:string? {
  if (empty($id)) then ()
  else if (exists($_:dict//string[@xml:id = $id])) then $_:dict//string[@xml:id = $id] else $id
};

declare function _:rdict($text as xs:string?) as xs:string? {
  if (empty($text)) then ()
  else if (exists($_:dict//string[text() = $text])) then $_:dict//string[text() = $text]/data(@xml:id) else $text
};