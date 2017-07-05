<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"    
    xmlns:math="http://exslt.org/math"
    xmlns:l="urn:local"
    exclude-result-prefixes="xs xd l math"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>Sorts a tree by subsection numbering like 1.1.1.1, 1.23.45, 1.12.22 -> 1.1.1.1, 1.12.22, 1.23.45
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:function name="l:sort-subsection-fn" as="xs:integer?">
        <xsl:param name="subsection-string" as="xs:string?"/>
        <xsl:variable name="sections" select="tokenize($subsection-string, '\.')"/>
        <xsl:variable name="nums" select="for $i in 1 to count($sections) return xs:integer($sections[$i]) * math:power(1000, count($sections) - $i)"/>
        <xsl:variable name="ret" select="if (empty($nums)) then 0 else sum($nums)"/>
        <xsl:sequence select="$ret"/>       
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Default action is to deep copy the nodes</xd:desc>
    </xd:doc>
    <xsl:template match="@*|*|processing-instruction()|comment()" mode="#all" priority="-1">
        <xsl:copy>
            <xsl:apply-templates select="*|@*|text() except text()[normalize-space(.) eq '']|processing-instruction()|comment()" mode="#current">
                <xsl:sort select="l:sort-subsection-fn(@n)"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>