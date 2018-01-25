xquery version "3.1";

(: Call this script directly to process a few hundred of entries with small
   changes.
   To update the whole database with larger changes try them and then use
   write-to-db-in-junks.xq with this script as the $script_to_run parameter
   else for large changes the list of updates will exhaust the memory. 
:)

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";
declare namespace mods = "http://www.loc.gov/mods/v3";

declare variable $_:maxNumberOfChangesPerJob external := 300;
declare variable $_:onlyGetNumberOfEntries external := false();
declare variable $_:getParams external := false();

declare variable $__db__ external := 'japbib_06';
declare variable $__helper_tables__ external := "helper_tables";

declare function _:select-entries() as element(mods:mods)* {
  collection($__db__)//mods:mods[some $t in .//text() satisfies $t[matches(., '&amp;\w+;')]]
};

declare function _:get-params() as element(params) {
<params>
</params>
};

declare %updating function _:transform($e as element(mods:mods)) {
  let $comment := '9203 remove &amp;amp;',
      $texts := $e//text()[matches(., '&amp;\w+;')]/..
  return for $e in $texts
     return try {
     (insert node comment {$comment} before $e,
     replace value of node $e with
     $e/text() => replace('&amp;gt;', '>')
               => replace('&amp;lt;', '<')
               => replace('&amp;amp;', '&amp;'))
     } catch * {
        error($err:code, $err:additional||'&#xa;'||serialize($e))
     }
};

declare function _:main() {
  let $sub := <_>{subsequence(_:select-entries(), 1, $_:maxNumberOfChangesPerJob)}</_>,
      $ret := $sub update {
    for $e in ./* return
     _:transform($e) }
  return $ret/*
};

if ($_:onlyGetNumberOfEntries) then count(_:select-entries())
else if ($_:getParams) then serialize(_:get-params())
else try { _:main() } catch * { $err:additional }