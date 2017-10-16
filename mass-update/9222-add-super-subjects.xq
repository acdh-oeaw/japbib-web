xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';
declare variable $_:thesaurus := 
  for $c in doc('../../japbib-web/thesaurus.xml')//catDesc return
    <topic xmlns="http://www.loc.gov/mods/v3" primary="{$c}">{
      for $pc in $c/ancestor::*:category except $c/.. return
        <topic>{($pc/*:catDesc)/text()}</topic>
      }
    </topic>;

declare function _:select-entries() as element(mods:mods)* {
  collection($_:db-name)//mods:mods[not(mods:subject/@usage)]
};

declare %updating function _:transform($e as element(mods:mods)) {  
    let $subjects := $e/mods:subject[not(@displayLabel)]
    return for $subject in $subjects
      let $newSubject := (
        <subject usage="primary" xmlns="http://www.loc.gov/mods/v3">
        {(comment {'#Task #9222 add super categories'||$subject/mods:topic}, $subject/*)}
        </subject>,
        <subject usage="secondary" xmlns="http://www.loc.gov/mods/v3">
        {$_:thesaurus[@primary = $subject/mods:topic]/*}
        </subject>
        )
      return replace node $subject with $newSubject
};

declare function _:main() {
  let $sub := <_>{subsequence(_:select-entries(), 1, 200)}</_>,
      $ret := $sub update {
    for $e in ./* return
     (_:transform($e),
     hist:add-change-record($e))}
  return $ret/*
};

_:main()