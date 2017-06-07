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

module namespace diag  = "http://www.loc.gov/zing/srw/diagnostic/";

declare namespace sru = "http://www.loc.gov/zing/srw/";

declare variable $diag:msgs := doc('diagnostics.xml');

declare function diag:diagnostics($key as xs:string, $param as item()*) as element() {
    let $diag := 
	       if (exists($diag:msgs//diag:diagnostic[@key=$key])) 
	       then $diag:msgs//diag:diagnostic[@key=$key]
	       else $diag:msgs//diag:diagnostic[@key='general-error']
    return
        <sru:diagnostics>{ 
            if (exists($diag)) 
            then diag:render($diag, $param) 
            else () 
        }</sru:diagnostics>	   
};

declare %private function diag:render($diag as element(diag:diagnostic), $param as item()*){
    diag:copy($diag, $param)
};

declare %private function diag:copy($item as item(), $param as item()*){
    typeswitch ($item) 
        case element() return element {QName(namespace-uri($item), local-name($item))} {for $i in ($item/@*, $item/node()) return diag:copy($i, $param)}
        case text() return if ($item = '{$param}') then $param else $item
        case attribute() return $item
        default return $item
};