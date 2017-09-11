xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "/tmp/dba/vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';

declare function _:select-entries() as element(mods:mods)* {
  collection($_:db-name)//mods:mods[.//mods:originInfo[matches(., '^([^:]+)\s*:\s*([^,]+)\s*,\s*(\d{4})\s*-\s*(\d{0,4})$')]]
};

declare function _:transform($e as element(mods:mods)) as element(mods:mods) {
  let $originInfoParsed := analyze-string($e//mods:originInfo, '^([^:]+)\s*:\s*([^,]+)\s*,\s*(\d{4})\s*-\s*(\d{0,4})$'),
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
    { let $replace := .//mods:originInfo/text()[matches(., '^([^:]+)\s*:\s*([^,]+)\s*,\s*(\d{4})\s*-\s*(\d{0,4})$')]
      return (replace node $replace with $newOriginInfo/*,
              replace node $replace/preceding-sibling::comment() with comment {'Task #9277 1: parse series originInfo'}) }  
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