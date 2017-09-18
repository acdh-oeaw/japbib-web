xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';

declare function _:select-entries() as element(mods:mods)* {
  collection($_:db-name)//mods:mods[mods:genre[@authority="local" and . eq 'Series'] and mods:originInfo[matches(., '^[^:]+:[^,]+,\s\d{4}-\d{0,4}$')]]
};

declare function _:transform($e as element(mods:mods)) as element(mods:mods) {
  let $originInfoParsed := analyze-string($e/mods:originInfo, '^([^:]+):\s([^,]+),\s(\d{4})-(\d{0,4})$'),
      $newOriginInfo := <originInfo xmlns="http://www.loc.gov/mods/v3">
         <dateIssued point='start'>{$originInfoParsed/fn:match/fn:group[@nr = 3]/text()}</dateIssued>
         {if ($originInfoParsed/fn:match/fn:group[@nr = 4 and . ne '']) then 
         <dateIssued point='end'>{$originInfoParsed/fn:match/fn:group[@nr = 4]/text()}</dateIssued>
         else ()}
         <publisher>{$originInfoParsed/fn:match/fn:group[@nr = 2]/text()}</publisher>
         <place>
            <placeTerm type="text">{$originInfoParsed/fn:match/fn:group[@nr = 1]/text()}</placeTerm>
         </place>
         <issuance>serial</issuance>
         </originInfo>
  return $e update
    { replace node ./mods:originInfo/text() with $newOriginInfo/* }  
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