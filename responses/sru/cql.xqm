xquery version "3.1";

(:
The MIT License (MIT)

Copyright (c) 2016 Austrian Centre for Digital Humanities at the Austrian Academy of Sciences

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE
:)

(:~ This module provides methods to transform CQL query to XPath   
: @see http://clarin.eu/fcs 
: @author Matej Durco
: @since 2012-03-01
: @version 1.1 
:)
module namespace cql = "http://exist-db.org/xquery/cql";

(: The following two declarations pull in the required classes from cql-java-1.13.jar :)
import module namespace cqlparser = "http://z3950.org/zing/cql/c-q-l-parser";
declare namespace cqlnode = "http://z3950.org/zing/cql/c-q-l-node";

import module namespace index = "japbib:index" at "../../index.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";
declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace rest = "http://exquery.org/ns/restxq";
import module namespace l = "http://basex.org/modules/admin";
import module namespace _ = "urn:sur2html" at "../localization.xqm";

import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "diagnostics.xqm";

declare variable $cql:defaultIndexName := "cql.serverChoice";
declare variable $cql:defaultRelationValue := "scr";
declare variable $cql:modifierRegex := "(/(\w+\.)?\w+((=)(\w+)?))*"; 

 
(:~ Takes a CQL query string and parses it to XCQL syntax: 
 : @param $query: the query string                        
 : @result the XCQL representation of the query                          
~:)
declare 
%rest:path("cql/parse")
%rest:query-param("q", "{$query}")
function cql:parse($query as xs:string?) as element() {
  let $checked-query := if (not(exists($query)) or normalize-space($query) eq '') then '""' else $query,
      $register := (cqlparser:registerCustomRelation('contains'),
                    cqlparser:registerCustomRelation('exact')),
      $node := cqlparser:parse($checked-query)
  return parse-xml(cqlnode:toXCQL($node))/* update {
    delete node .//text()['' eq normalize-space(.)]
  }
};

(:~ Translates a query in CQL-syntax to a corresponding XPath
: Called and evaluated by api:searchRetrieve()
: This happens in two steps: 
: <ol>
: <li>1. parsing into XCQL (XML-representation of the parsed query</li>
: <li>2. and process the XCQL recursively with xquery (as opposed to old solution, with the XCQL2Xpath.xsl-stylesheet)</li>
: </ol>
: @param $cql-expression a query string in CQL-syntax
: @param $context identifies the context-project (providing the custom index-mappings, needed in the second step) 
: @return XPath expression as a string (or if not a string, whatever came from the parsing) 
:)
declare function cql:cql-to-xpath($cql-expression, $context) as item()* {
    typeswitch ($cql-expression) 
        case element(diagnostics) return $cql-expression
        case xs:string return cql:xcql-to-xpath(cql:parse($cql-expression), $context)
        default return
            fn:error(
                xs:QName("cql:unexpectedInputType"),
                "First parameter has unexpected type (node-name = "||node-name($cql-expression)||")"
            )
};

declare function cql:xcql-to-xpath ($xcql as node(), $context as xs:string) as item() {
    let $map := index:map($context)
    return 
        if ($map instance of element(sru:diagnostics))
        then $map
        else 
            let $xpath := 
                if ($xcql instance of document-node())
                then cql:process-xcql($xcql/*, $map)
                else cql:process-xcql($xcql, $map)
            return
            if ($xpath instance of element(sru:diagnostics))
            then $xpath
            else string-join($xpath,'')
        
};

declare function cql:xcql-to-orderExpr ($xcql as node(), $context as xs:string) as item()? {
    let $map := index:map($context)
    let $sortIndex := $xcql//sortKeys/key[1]/index
    return 
        if (not(exists($sortIndex)))
        then ()
        else 
            if ($map instance of element(sru:diagnostics))
            then $map
            else 
               let $sortIndexMap := index:index-from-map($sortIndex/text(), $map),
                   $sortIndexXpath := index:index-as-xpath-from-map($sortIndex, $map)
               return
                    if ($sortIndexXpath instance of element(sru:diagnostics))
                    then $sortIndexXpath
                    else 
                        let $sortIndexType := $sortIndexMap/@datatype,
                            $desSelfSortIndexXpath :=
                            if (starts-with($sortIndexXpath, '(')) then "(descendant-or-self::"||string-join(tokenize(substring($sortIndexXpath, 2), '\|'), '|descendant-or-self::')
                            else "descendant-or-self::"||$sortIndexXpath,
                            $sortIndexXpath-typed := 
                            if (exists($sortIndexType))
                            then $desSelfSortIndexXpath||"[. castable as "||$sortIndexType||"]/"||$sortIndexType||"(.)"
                            else $desSelfSortIndexXpath
                        return string-join($sortIndexXpath-typed,'')
};

(:~ the default recursive processor of the parsed query expects map with indexes defined
: @param $xcql the parsed query as XCQL
: @param $map map element as defined in the project-configuration 
: @returns xpath corresponding to the abstract cql query as string
:)

declare function cql:process-xcql($xcql as element(),$map) as item()* {     
    typeswitch ($xcql)
        case element(sru:diagnostics) return $xcql
        case text() return normalize-space($xcql)
        case element(triple) return cql:boolean($xcql/boolean/value, $xcql/boolean/modifiers, $xcql/leftOperand, $xcql/rightOperand, $map)
        case element(searchClause) return cql:searchClause($xcql, $map)
        case element(boolean) return cql:boolean($xcql/value, $xcql/modifiers, $xcql/following-sibling::leftOperand, $xcql/following-sibling::rightOperand, $map)
        default return 
            if (exists($xcql/*))
            then cql:process-xcql($xcql/*, $map)
            else $xcql
};
(:
declare function cql:process-xcql-default($node as node(), $map) as item()* {
  cql:process-xcql($node/node(), $map))
  
 };:) 
 
declare function cql:boolean($value as element(value), $leftOperand as element(leftOperand), $rightOperand as element(rightOperand),$map) as item()* {
    cql:boolean($value,(),$leftOperand,$rightOperand,$map) 
};

declare function cql:boolean($value as element(value), $modifiers as element(modifiers)?, $leftOperand as element(leftOperand), $rightOperand as element(rightOperand),$map) as item()* {
    switch(lower-case($value))
        case "or" return cql:union($leftOperand, $rightOperand, $map)   
        case "not" return cql:except($leftOperand, $rightOperand, $map)
        case "prox" return cql:prox($leftOperand, $rightOperand, $modifiers, $map)
        (: default operator AND :)
        default return cql:intersect($leftOperand, $rightOperand, $map) 
 };

declare function cql:searchClause($clause as element(searchClause), $map) {
    let $index-key := $clause/index/text(),        
        $index := index:index-from-map($index-key ,$map),
        $index-type := ($index/xs:string(@type),'')[1],
        $index-xpath := index:index-as-xpath-from-map($index-key,$map,''),
        $match-on-xpath := index:index-as-xpath-from-map($index-key,$map ,'match-only'),
        $relation := if ($clause/relation/value/text() eq '=') then index:scr($index-key, $map) else $clause/relation/value/text(),
        (: exact, starts-with, contains, ends-with :)
        $term := if (index:case($index-key ,$map)) then xs:string($clause/term) else lower-case($clause/term),
        $match-mode := if ($relation = 'contains') then 'contains'
                                                   else if (ends-with($term,'*')) then     
                                                        if (starts-with($term,'*')) then 'contains'
                                                        else 'starts-with'
                                                    else if (starts-with($term,'*')) then 'ends-with'
                                                    else if (contains($term,'*')) then 'starts-ends-with'
                else 'exact',
        $predicate := switch (true())
            case ($index-type eq $index:INDEX_TYPE_FT) return cql:xqft-predicate($match-mode, $match-on-xpath, $term, index:datatype($index-key ,$map), $relation, index:case($index-key,$map))
            default return cql:xquery-predicate($match-mode, $match-on-xpath, $term, index:datatype($index-key ,$map), $relation, index:case($index-key,$map))                     
                        
    return 
        if ($index instance of element(sru:diagnostics)) then $index
        else if ($term eq '') then 'collection($__db__)//'||index:base-elt($map)||'[./descendant-or-self::'||$index-xpath||'[normalize-space('||$match-on-xpath||') eq ""]'||' or not(./descendant-or-self::'||$index-xpath||')]'
        else 'collection($__db__)//'||$index-xpath||'['||$predicate||']'||"/ancestor-or-self::"||index:base-elt($map)
};

declare %private function cql:xqft-predicate($match-mode as xs:string, $match-on-xpath as xs:string?, $term as xs:string, $index-datatype as xs:string?, $relation as xs:string, $case as xs:boolean) as xs:string {
let $match-on-xpath := if ($match-on-xpath) then $match-on-xpath else 'text()',
    $wildcards := if (contains($term,'*')) then ' using wildcards' else '',
    $case-sensitive := if ($case) then ' using case sensitive' else ' using case insensitive',
    $rtrans-term := _:rdict($term),
    $sanitized-term := cql:sanitize-xqft-term($rtrans-term),
    $language := " using language '"||db:info($model:dbname)/indexes/language||"' "
return switch (true())  
  case ($sanitized-term eq 'false') return 'not('||$match-on-xpath||')'
  case ($sanitized-term eq 'true') return $match-on-xpath
  default return if ($index-datatype != '')
        then $match-on-xpath||" castable as "||$index-datatype||" and "||$index-datatype||"("||$match-on-xpath||") "||$relation||" "||$index-datatype||"("||$term||")"
        else $match-on-xpath||'/text() contains text "'||$sanitized-term||'"'||$wildcards||$case-sensitive||$language
};

declare %private function cql:sanitize-xqft-term($term) {
 (: replace leading and/or trailing stars with .* :)
 $term => replace('(\*$|^\*)','.*')
       => replace('&amp;', '&amp;amp;')
};

declare %private function cql:xquery-predicate($match-mode as xs:string, $match-on-xpath as xs:string?, $term as xs:string, $index-datatype as xs:string?, $relation as xs:string, $case as xs:boolean) as xs:string {
let $rtrans-term := _:rdict($term),
    $sanitized-term := cql:sanitize-term($rtrans-term),
    $match-on-xpath := if ($match-on-xpath) then $match-on-xpath else '.',
    $match-on := if ($case) then $match-on-xpath else 'lower-case('||$match-on-xpath||')'
return switch (true())  
  case ($sanitized-term eq 'false') return 'not('||$match-on-xpath||')'
  case ($sanitized-term eq 'true') return $match-on-xpath
  default return switch ($match-mode)
    case ('exact') return $match-on||'="'||$sanitized-term||'"'
                                    case ('starts-with') return 'starts-with('||$match-on||",'"||$sanitized-term||"')"
                                    case ('ends-with') return 'ends-with('||$match-on||",'"||$sanitized-term||"')"
                                    case ('contains') return 'contains('||$match-on||",'"||$sanitized-term||"')"
                                    case ('starts-ends-with') return 
                                            let $starts-with := substring-before($sanitized-term,'*')
                                            let $ends-with := substring-after($sanitized-term,'*')
                                            return 'starts-with('||$match-on||",'"||$starts-with||"') and ends-with("||$match-on||",'"||$ends-with||"')"
                                    default return 
                                        if ($index-datatype != '')
                                        then $match-on||" castable as "||$index-datatype||" and "||$index-datatype||"("||$match-on||") "||$relation||" "||$index-datatype||"("||$sanitized-term||")"
        else $match-on||$relation||"'"||$sanitized-term||"'"   
};

(:~ remove quotes :)
declare %private function cql:sanitize-term($term) {
 (: remove leading and/or trailing stars :)
 $term => replace('(\*$|^\*)','.*')
       => replace('&amp;', '&amp;amp;')
};

declare function cql:predicate($clause,$map) as item() {
    let $clause := cql:searchClause($clause,$map)
    return 
        if ($clause instance of element(sru:diagnostics))
        then $clause
        else 
            if (starts-with($clause,'('))
            then "["||$clause||"]"
            else "[self::"||$clause||"]"
};

declare function cql:intersect($leftOperand as element(leftOperand), $rightOperand as element(rightOperand), $map) as item()* {
    let $operands := (cql:process-xcql($leftOperand, $map), cql:process-xcql($rightOperand, $map)) 
    return 
        if (some $o in $operands satisfies $o instance of element(sru:diagnostics))
        then $operands[. instance of element(sru:diagnostics)]
        else "("||string-join($operands,' intersect ')||")"
};

declare function cql:except($leftOperand as element(leftOperand), $rightOperand as element(rightOperand), $map) as item()* {
    let $operands := (cql:process-xcql($leftOperand,$map),cql:process-xcql($rightOperand,$map))
    return 
        if (some $o in $operands satisfies $o instance of element(sru:diagnostics))
        then $operands[. instance of element(sru:diagnostics)]
        else "("||string-join($operands,' except ')||")"
};

declare function cql:union($leftOperand as element(leftOperand), $rightOperand as element(rightOperand), $map) as item()* {
    let $operands := (cql:process-xcql($leftOperand,$map),cql:process-xcql($rightOperand,$map))
    return 
        if (some $o in $operands satisfies $o instance of element(sru:diagnostics))
        then $operands[. instance of element(sru:diagnostics)]
        else "("||string-join($operands,' union ')||")"
};

declare function cql:prox($leftOperand as element(leftOperand), $rightOperand as element(rightOperand), $modifiers as element(modifiers)?, $map) as xs:string {
    let $operands := (cql:process-xcql($leftOperand,$map),cql:process-xcql($rightOperand,$map)),
        $distance := ($modifiers/modifier[type='distance']/value),
        $comparison := ($modifiers/modifier[type='distance']/comparison),
        $proximityExpPrev := 
            (:if ($comparison = "=") 
            then :)"@cr:w = (xs:integer($hit/@cr:w)+1 to xs:integer($hit/@cr:w)+"||$distance||")"
            (:else "@cr:w "||$comparison||" $hit/@cr:w":),
        $proximityExpFoll := 
            (:if ($comparison = "=") 
            then :)"@cr:w = (xs:integer($hit/@cr:w)-"||$distance||" to xs:integer($hit/@cr:w)-1)"
            (:else "@cr:w "||$comparison||" $hit/@cr:w":)
    return 
        "for $hit in $data//("||$operands[1]||")
            let $prev := root($hit)//*["||$proximityExpPrev||"],
                $foll := root($hit)//*["||$proximityExpFoll||"],
                $window := ($prev,$foll)
            return 
                if ($window/self::"||$operands[2]||")
                then ($prev,$hit,$foll)
                else ()" (: " :)
};