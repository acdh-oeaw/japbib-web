xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';
declare variable $_:regex := '^(\S+)\s+(\S+)\s*\.\.\.$';

declare function _:select-entries() as element(mods:mods)* {
  collection($_:db-name)//mods:mods[.//mods:namePart[matches(., $_:regex)]]
};

declare function _:transform($e as element(mods:mods)) as element(mods:mods) {
  $e update
  { let $oldNames := .//mods:name[mods:namePart[matches(., $_:regex)]]
    for $oldName in $oldNames
    return
    let $namePart := $oldName/mods:namePart/text(),
        $analyzed := analyze-string($namePart, $_:regex),
        $newName := (
        <name type="personal" xmlns="http://www.loc.gov/mods/v3">
          {comment {'Task #9235 '||$namePart}}
          <namePart>{$analyzed//fn:group[@nr='2']||', '||$analyzed//fn:group[@nr='1']}</namePart>
          <role>
             <roleTerm type="code" authority="marcrelator">edt</roleTerm>
          </role>
        </name>,
        <name type="personal" xmlns="http://www.loc.gov/mods/v3">
          {comment {'Task #9235 '||$namePart}}
          <etal/>
          <role>
             <roleTerm type="code" authority="marcrelator">edt</roleTerm>
          </role>
        </name>)
    return replace node $oldName with $newName }
};

declare function _:main() {
  for $e in _:select-entries()
  return hist:add-change-record(_:transform($e))
};

_:main()