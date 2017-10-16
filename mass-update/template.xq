xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';

declare function _:select-entries() as element(mods:mods)* {
  collection($_:db-name)//mods:mods[mods:genre[@authority="local" and . eq 'Series'] and mods:originInfo[matches(., '^[^:]+:[^,]+')]]
};

declare %updating function _:transform($e as element(mods:mods)) {
  let $comment := 'Changed!'
  return insert node comment {$comment}  as first into $e
};

declare function _:main() {
  for $e in subsequence(_:select-entries(), 1, 200)
  return $e update {
     _:transform(.),
     hist:add-change-record(.)}
};

_:main()