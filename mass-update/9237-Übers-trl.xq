xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';
declare variable $_:regex := '\s*/\s*Übers\.\s*$';

declare function _:select-entries() as element(mods:mods)+ {
  collection($_:db-name)//mods:mods[.//mods:namePart[matches(., $_:regex)]]
};

declare %updating function _:transform($e as element(mods:mods)) {
  let $oldNames := $e//mods:name[mods:namePart[matches(., $_:regex)]]
    for $oldName in $oldNames
    return
    let $namePart := $oldName/mods:namePart/text(),
        $newName := 
        <name type="personal" xmlns="http://www.loc.gov/mods/v3">
          {comment {'Task #9237 '||$namePart}}
          <namePart>{replace($namePart, $_:regex, '')}</namePart>
          <role>
             <roleTerm type="code" authority="marcrelator">trl</roleTerm>
          </role>
        </name>
    return replace node $oldName with $newName
};

declare function _:main() {
  for $e in subsequence(_:select-entries(), 1, 200)
  return $e update {
     _:transform(.),
     hist:add-change-record(.)}
};

_:main()