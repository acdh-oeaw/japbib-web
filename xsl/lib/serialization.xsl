<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:_="urn:sur2html"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>Seriialization tweaks
        </xd:desc>
    </xd:doc>

    <xsl:function name="_:serialize">
        <xsl:param name="node" as="node()?"/>
        <xsl:param name="omit-nodes" as="node()?"/>
        <xsl:sequence select="_:serialize($node, $omit-nodes, ())"/>
    </xsl:function>
    
    <xsl:function name="_:serialize">
        <xsl:param name="node" as="node()?"/>
        <xsl:param name="omit-nodes" as="node()?"/>
        <xsl:param name="params" as="item()?"/>
        <xsl:variable name="preprocessedXML">
            <xsl:apply-templates mode="filter" select="$node">
                <xsl:with-param name="omit-nodes" tunnel="yes" select="$omit-nodes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:value-of select="serialize($preprocessedXML)"/>
    </xsl:function>
    
    <xsl:template mode="filter" match="@*|*|processing-instruction()|comment()">
        <xsl:param name="omit-nodes" as="node()?" tunnel="yes"/>
        <xsl:if test="not(. = $omit-nodes)">
            <xsl:copy>
                <xsl:apply-templates select="*|@*|text()|processing-instruction()|comment()" mode="filter"/>
            </xsl:copy>
        </xsl:if>
        <!--        <xsl:if test=". = $omit-nodes">
            <xsl:message terminate="no"><xsl:value-of select="local-name(.)"/> omitted</xsl:message> 
        </xsl:if>-->
    </xsl:template>
    
</xsl:stylesheet>