<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:_="urn:sur2html"
    exclude-result-prefixes="xs xd"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>Localization functions
        </xd:desc>
    </xd:doc>
        
    <xsl:variable name="dict" as="document-node()" select="doc('../../dict-de.xml')"/>
    
    <xsl:function name="_:dict">
        <xsl:param name="id"/>
        <xsl:choose>
            <xsl:when test="exists($dict//string[@xml:id = $id])">
                <xsl:value-of select="$dict//string[@xml:id = $id]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$id"/> 
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="_:rdict">
        <xsl:param name="text"/>
        <xsl:choose>
            <xsl:when test="exists($dict//string[text() = $text])">
                <xsl:value-of select="$dict//string[text() = $text]/@xml:id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/> 
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
</xsl:stylesheet>