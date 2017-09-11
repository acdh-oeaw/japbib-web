xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "/tmp/dba/vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';

declare function _:select-entries() as element(mods:mods)+ {
  collection($_:db-name)//mods:mods[.//mods:namePart[matches(., '^(\p{L}+)\s+(\p{L}+)$')]]
};

declare function _:transform($e as element(mods:mods)) as element(mods:mods) {
  $e update
  { for $name in .//mods:name[mods:namePart[matches(., '^(\p{L}+)\s+(\p{L}+)$')]]  
    return (replace value of node $name/mods:namePart with replace($name/mods:namePart, '^(\p{L}+)\s+(\p{L}+)$', '$2, $1'),
            insert node comment{'Task #9274 '||$name/mods:namePart} as first into $name)}
};

declare function _:main() {
let $ret := 
  for $e in _:select-entries()
  return hist:add-change-record(_:transform($e))
return (count($ret), $ret)
};

_:main()