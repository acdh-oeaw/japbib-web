xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';

declare function _:select-entries() as element(mods:mods)+ {
  collection($_:db-name)//mods:mods[.//mods:namePart[matches(., '^(\p{L}+)\s+(\p{L}+)[\s,]*\.\.\.$')]]
};

declare function _:transform($e as element(mods:mods)) as element(mods:mods) {
  $e update
  { for $name in .//mods:name[mods:namePart[matches(., '^(\p{L}+)\s+(\p{L}+)[\s,]*\.\.\.$')]]  
    return (replace value of node $name/mods:namePart with replace($name/mods:namePart, '^(\p{L}+)\s+(\p{L}+)[\s,]*\.\.\.$', '$2, $1'),
            insert node comment{'Task #9274 etal'||$name/mods:namePart} as first into $name,
            insert node <name><etal/>{$name/mods:role}</name> after $name)}
};

declare %updating function _:main() {
  for $e in _:select-entries()
  return
    let $transformed-entry := hist:add-change-record(_:transform($e))
    return (hist:save-entry-in-history($_:db-name, $e),
     replace node $e with $transformed-entry,
     db:output($transformed-entry))
};

_:main()