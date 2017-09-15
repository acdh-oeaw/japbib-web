xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';
declare variable $_:namePart := '([\p{L}\.-]+)\s+(([\p{L}\.-]+)\s+)?([\p{L}-]+)';
declare variable $_:regex := '^\s*'||$_:namePart||'\s*((,|;|u.|/)\s+'||$_:namePart||'\s*)?((,|;|und|u.|/)\s+'||$_:namePart||'\s*)?(\[u\.a\.\]|\.\.\.)?\s*\((Hrsg|Hg)\.\)\s*$';
declare variable $_:vns := (1, 7, 13);
declare variable $_:mns := (3, 9, 15);
declare variable $_:nns := (4, 10, 16);
declare variable $_:etal := 17;

declare function _:select-entries() as element(mods:mods)* {
  collection($_:db-name)//mods:mods[.//mods:name[matches(mods:namePart, $_:regex)]]
};

declare function _:transform($e as element(mods:mods)) as element(mods:mods) {
  $e update
  { for $name in .//mods:name[matches(mods:namePart, $_:regex)]
    let $analyzed := analyze-string($name/mods:namePart, $_:regex),
        $vns := _:getMatches($_:vns, $analyzed),
        $mns := _:getMatches($_:mns, $analyzed),
        $nns := _:getMatches($_:nns, $analyzed),
        $newNameNodes := 
            (if ($nns[2]/text()) then _:createName($name/mods:namePart, $nns[2]/text(), $vns[2]/text(), $mns[2]/text()) else (),
             if ($nns[3]/text()) then _:createName($name/mods:namePart, $nns[3]/text(), $vns[3]/text(), $mns[3]/text()) else (),
             if ($analyzed//fn:group[@nr = $_:etal]) then _:createEtal($name/mods:namePart) else ())
    return (replace node $name with _:createName($name/mods:namePart, $nns[1]/text(), $vns[1]/text(), $mns[1]/text()),
            if ($nns[2]/text() or $analyzed//fn:group[@nr = $_:etal]) then insert node $newNameNodes after $name else ())}
};

declare function _:getMatches($seq as xs:integer+, $analyzed as element()) as element(fn:group)+ {
  for $i in $seq
  return 
    if ($analyzed//fn:group[@nr = $i]) then $analyzed//fn:group[@nr = $i] else <fn:group/>
};

declare function _:createName($originalName as xs:string, $nn as xs:string, $vn as xs:string, $mn as xs:string?) as element(mods:name) {
  <name xmlns="http://www.loc.gov/mods/v3" type="personal">
  {comment {'Bug #9279 1 '||$originalName}}
  <namePart>{$nn||', '||string-join(($vn, $mn), ' ')}</namePart>
  <role>
    <roleTerm type="code" authority="marcrelator">edt</roleTerm>
  </role>
  </name>
};

declare function _:createEtal($originalName as xs:string) as element(mods:name) {
  <name xmlns="http://www.loc.gov/mods/v3" type="personal">
  {comment {'Bug #9279 1 etal '||$originalName}}
  <etal/>
  <role>
    <roleTerm type="code" authority="marcrelator">edt</roleTerm>
  </role>
  </name>
};

declare function _:main() {
  for $e in _:select-entries()
  return hist:add-change-record(_:transform($e))
};

_:main()