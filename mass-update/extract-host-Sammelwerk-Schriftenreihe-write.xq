xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';

declare %updating function _:main() {
  let $subjectToGenre := map {
    'Sammelwerk': 'Book',
    'Schriftenreihe': 'Series'
  }
  let $wrongRelatedItemEntry := collection($_:db-name)//mods:mods[not(exists(.//mods:genre)) and not(exists(mods:originInfo)) and mods:relatedItem[@type='host'] and mods:subject[. = map:keys($subjectToGenre)]],
      $store-in-history := hist:save-entry-in-history($_:db-name, $wrongRelatedItemEntry)
  for $e in $wrongRelatedItemEntry
  return (
    (: keine Wirkung wegen nächster Zeile if ($e/mods:subject[. eq 'Schriftenreihe']) then insert node <issuance>series</issuance> into $e/mods:relatedItem[@type='host']/mods:originInfo else (),:)
    replace node $e/mods:relatedItem[@type='host'] with $e/mods:relatedItem[@type='host']/(*|text()|comment()), 
    insert node <genre authority="local">{$e/mods:subject!$subjectToGenre(.)}</genre> after $e/mods:typeOfResource
)
};

_:main()