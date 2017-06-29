xquery version "3.0";

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

import module namespace index = "japbib:index" at "../../index.xqm";
declare namespace cqlparser = "http://exist-db.org/xquery/cqlparser";
declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace rest = "http://exquery.org/ns/restxq";

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
function cql:parse($query as xs:string) as item()* {
    let $quotes-parsed := cql:parse-quotes($query)
    let $groups-parsed := cql:parse-groups($quotes-parsed)
    let $boolOps-parsed := cql:parse-boolean-operators($groups-parsed)
    let $sortClause-parsed := cql:parse-sort-clause($boolOps-parsed) 
    let $searchClauses-parsed := cql:parse-searchClauses($sortClause-parsed)
    return cql:create-triples($searchClauses-parsed)
};      

(:~ NOT USED ~:)
declare function cql:parse-modifiers($string as xs:string){
    let $a := analyze-string($string, $cql:modifierRegex)
    return $a 
};

(:~
 : Parses the cql "sort" specification in the request  
~:)
declare function cql:parse-sort-clause($parts as item()*){
    for $p in $parts
    let $parse-sortBy-clause := function($sbc as xs:string){
        let $a := analyze-string($sbc, "^\s*sortBy\s+((\w+\.)?\w+)"||$cql:modifierRegex)
        let $index := $a/fn:match/fn:group[1]
        let $modifiers := $a/fn:match/fn:group[2]
        return ( 
            if ($index != '') then <index>{data($index)}</index> else (),
            if ($modifiers != '') then <modifiers>{data($modifiers)}</modifiers> else ()
        )
    }
    let $format-analyze-string-results := function($a as element()){
        for $e in $a/* return 
        typeswitch($e)
            case element(fn:match) return <sortKeys>{$parse-sortBy-clause(xs:string($e))}</sortKeys>
            case element(fn:non-match) return xs:string($e) 
            default return () 
    }
    return
        if ($p instance of xs:string)
        then $format-analyze-string-results(analyze-string($p, "\s+sortBy.+"))
        else $p
};

(:~
 : Takes a sequence of elements and groups them into triples
 : @input $parts: flat sequence of elements
 : @output: either a simple <searchClause> or a <triple>
~:)
declare function cql:create-triples($parts as element()+) {
    let $formatSearchClause := function($w as element()+){
        (<searchClause>{(
            if (exists($w[self::index])) then $w[self::index] else <index>{$cql:defaultIndexName}</index>,
            if (exists($w[self::relation])) then $w[self::relation] else <relation><value>{$cql:defaultRelationValue}</value></relation>,
            $w[not(self::boolean or self::relation or self::index)]
        )}</searchClause>,
        $w[self::boolean])
    }
    return 
    (: if there is only a term, the formatSearchClause() function will put it into a simple cql.serverChoice query :)
    if (count($parts) eq 1 and $parts/self::term)
    then $formatSearchClause($parts)
    else
        (: if there are already parsed query items <index>, <relation> and <term>, formatSeachClause() will simply wrap them with a <searchClause> element :) 
        if (every $p in $parts satisfies local-name($p) = ('index', 'relation', 'term', 'sortKeys'))
        then $formatSearchClause($parts)
        else 
            let $searchClauses-grouped := 
                for tumbling window $w in $parts
                start $s when true()
                end $e when $e instance of element(boolean)
                return $formatSearchClause($w)
            (:Currently grouping is commented out since it is not implemented correctly ... :)
            return cql:group-triples($searchClauses-grouped)
};

(:~
 : Group searchClauses into triples
~:)
declare function cql:group-triples($elts as element()+) as element(){
    (:let $boolean := 
        if (exists($elts[descendant::groupStart])) 
        (\:then $elts[self::boolean][position() lt $elts[descendant::groupStart]/position()][1]:\)
        then $elts[self::boolean][1]
        else $elts[self::boolean][1],:)
    let $boolean := $elts[self::boolean][1],
        $lo := $elts[self::searchClause][1],
        $ro := $elts[self::searchClause][2],
        $rest := $elts except ($boolean, $lo, $ro) 
    return 
        try {
            if (exists($boolean) and exists($lo) and exists($ro))
            then 
                if (exists($elts[descendant::groupEnd]) and exists($elts[descendant::groupStart]))
                then cql:do-group-triples($boolean, $elts/self::*[descendant::groupStart], $elts/self::*[descendant::groupEnd], $rest)
                else cql:do-group-triples($boolean, $lo, $ro, $rest)
            else ()
        } catch * {
            <error code="{$err:code}" module="{$err:module}" line-number="{$err:line-number}" column-number="{$err:column-number}" value="{$err:value}"><description>{$err:description}</description><bo>{$boolean}</bo><lo>{$lo}</lo><ro>{$ro}</ro><re>{$rest}</re></error>
        }
};

declare function cql:do-group-triples($boolean as element(boolean), $lo as element(), $ro as element(), $rest as element()*) as element(triple){
    let $t := <triple>
                  {$boolean}
                  <leftOperand>{$lo}</leftOperand>
                  <rightOperand>{$ro}</rightOperand>                  
              </triple>
    (:return $t:)
    let $boolean-rest := $rest/self::boolean[1],
        $first-sc-of-rest := $rest/self::searchClause[1],
        $rest-rest := $rest except ($boolean-rest, $first-sc-of-rest)
    return  
        if (exists($boolean-rest) and exists($first-sc-of-rest)) 
        then cql:do-group-triples($boolean-rest, $t, $first-sc-of-rest, $rest-rest)
        else $t
};

(:~   
 : Parses a searchClause into its constituents.
 : @param $parts: A flat sequence of items (elements or strings) from previous parsing steps
 : @result: The same flat input sequence, with tagged <index>, <relation> and <term> elements 
~:)
declare function cql:parse-searchClauses($parts as item()*) as item()* { 
    let $relationOperators :=  "\s*(\w+\.)?(==|=|<=|>=|<|>|<>|any|contains)"||$cql:modifierRegex||"\s*"
    let $parse-searchClause := function($s as xs:string) as element()*{
        let $is := analyze-string($s, $relationOperators)/fn:*
        return 
            for tumbling window $w in $is
            start $s at $s-pos previous $prev when true()
            end $e at $e-pos next $next when true()
            return 
              if ($w instance of element(fn:match)) then <relation><value>{lower-case(normalize-space($w))}</value></relation> else  
              if ($prev instance of element(fn:match)) then <term>{data($w)}</term>
              else <index>{normalize-space($w)}</index>
    }
    return 
        for $p in $parts
        return (:$parse-searchClause($p):)
            if ($p instance of element())
            then $p
            else 
            if ($p instance of xs:string and matches($p, $relationOperators))
            then $parse-searchClause($p)
            else <term>{$p}</term>
};      

declare function cql:parse-quotes($expr as xs:string) as item()* {
    let $a := analyze-string($expr,'".*[^\\]?"')
    let $it := function($e as item(), $it){
        typeswitch($e)
            case element(fn:match) return <term>{for $i in $e/node() return $it($i, $it)}</term>
            case element(fn:non-match) return for $i in $e/node() return $it($i, $it)
            case text() return 
                if (matches($e, '".*?"'))    
                then xs:string(replace($e,'(\\")|"','$1'))
                else xs:string($e)  
            default return $e/node()!$it(., $it)
    }
    let $parse-quotes := function($a){$it($a, $it)},
        $ret := $parse-quotes($a)
    return if (exists($ret)) then $ret else <term/>
}; 


(:~
 : Parses parentheses in the into groups
~:)
declare function cql:parse-groups($parts as item()*) as item()* {
    cql:parse-groups($parts, 1)
};
declare function cql:parse-groups($parts as item()*, $depth as xs:integer) as item()* {
    (: anonymous identity transform function :)
    let $it := function($e as item(), $it) as item()* {
                    switch($e)
                        case $e/self::fn:analyze-string-result return $e/*!$it(., $it)
                        case $e/self::fn:match[. = '('] return <groupStart/>
                        case $e/self::fn:match[. = ')'] return <groupEnd/>
                        case $e/self::fn:non-match return xs:string($e)
                        (:case $e/self::text() return $e:)
                        (:default return $e/node()!$it(., $it):)
                        default return xs:string($e)
                }
    (: syntactic wrapper around the $it function :)
    let $analyze-string-result2groups := function($analyze-string-result as element(fn:analyze-string-result)){$it($analyze-string-result, $it)}
    let $parsed as item()* := 
        for $expr in $parts
        return 
            typeswitch($expr)
                (: if it's a text, cast it to a string and call the function again :)
                case text() return cql:parse-groups(xs:string($expr), $depth+1)
                case xs:string return
                    let $a := analyze-string($expr,'[\(\)]')
                    return $analyze-string-result2groups($a)
                default return $expr
     
    return 
    if ($depth gt 1) 
    then $parsed
    else     
        if (count($parsed[. instance of node()]/self::groupStart) ne count($parsed[. instance of node()]/self::groupEnd))
        then fn:error(xs:QName("cql:syntaxError"),"Syntax error. Found "||count($parsed[self::groupStart])||" opening parentheses and "||count($parsed[self::groupEnd])||" closing.") (:else:) 
        else $parsed
}; 

declare function cql:parse-boolean-operators($parts as item()*) as item()* {
     let $format-analyze-string-results := function($r as element(fn:analyze-string-result)) {
        for $e in $r/* 
        return 
            if ($e instance of element(fn:match)) 
            then <boolean><value>{lower-case(normalize-space($e))}</value></boolean> 
            else xs:string($e)
     }
     return
     for $p in $parts
     return 
        if ($p instance of xs:string)
        then $format-analyze-string-results(analyze-string($p, "\s+(AND|and|OR|or|PROX|prox)"||$cql:modifierRegex||"\s+"))
        else $p
};

declare function cql:make-triples($parts as item()*) as item()* {
 ()        
};

declare function cql:group-expressions($expr as element()+) as item()* {
    for tumbling window $w in $expr
        start at $s when starts-with($expr[$s], '(')
        end at $e when ends-with($expr[$e], ')')
    return <group>{$w}</group>
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
declare function cql:cql-to-xpath($cql-expression, $context)  as item()* {
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
    let $sortIndex := $xcql//sortKeys/index
    return 
        if (not(exists($sortIndex)))
        then ()
        else 
            if ($map instance of element(sru:diagnostics))
            then $map
            else 
                if (not(exists($sortIndex)))
                then ()
                else 
                    let $sortIndexMap := index:index-from-map($sortIndex/text(), $map)
                    let $sortIndexXpath := index:index-as-xpath-from-map($sortIndex, $map)
                    return
                    if ($sortIndexXpath instance of element(sru:diagnostics))
                    then $sortIndexXpath
                    else 
                        let $sortIndexType := $sortIndexMap/@datatype
                        let $sortIndexXpath-typed := 
                            if (exists($sortIndexType))
                            then $sortIndexXpath||"[. castable as "||$sortIndexType||"]/"||$sortIndexType||"(.)"
                            else $sortIndexXpath
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
        $index-datatype := $index/xs:string(@datatype),
        $index-case := ($index/xs:string(@case),'')[1],
        $index-xpath := index:index-as-xpath-from-map($index-key,$map,''),        
        $match-on := index:index-as-xpath-from-map($index-key,$map,'match-only'),
        $relation := if ($clause/relation/value/text() eq 'scr') then 'contains' else $clause/relation/value/text(),
        (: exact, starts-with, contains, ends-with :)
        $term := if ($index-case='yes') then $clause/term else lower-case($clause/term), 
        $sanitized-term := cql:sanitize-term($term),
        $predicate := switch (true())
                        case ($sanitized-term eq 'false') return 'not('||$match-on||')'
                        case ($sanitized-term eq 'true') return $match-on
                        case ($index-type eq $index:INDEX_TYPE_FT) return
                                if (contains($term,'*')) then 
                                            'ft:query('||$match-on||',<query><wildcard>'||$term||'</wildcard></query>)'
                                        else
                                            'ft:query('||$match-on||',<query><phrase>'||$term||'</phrase></query>)'
                        default return
                                let $match-mode := if ($relation = 'contains') 
                                                   then 'contains'
                                                   else if (ends-with($term,'*')) then     
                                                        if (starts-with($term,'*')) then 'contains'
                                                        else 'starts-with'
                                                    else if (starts-with($term,'*')) then 'ends-with'
                                                    else if (contains($term,'*')) then 'starts-ends-with'
                                                        else 'exact'
                               return switch ($match-mode) 
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
                        
    return 
        if ($index instance of element(sru:diagnostics))
        then $index
        else '//'||$index-xpath||'['||$predicate||']'||"/ancestor-or-self::"||index:base-elt($map)

};
(:
declare function cql:predicate($index-type as xs:string?, $relation as xs:string, $term as xs:string) {
    
};:)


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
        

(:~ remove quotes :)
declare function cql:sanitize-term($term) {
 (: remove leading and/or trailing stars :)
 replace($term,'(\*$|^\*)','')
};

