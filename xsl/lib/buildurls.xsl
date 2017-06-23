<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:_="urn:sur2html"
    exclude-result-prefixes="xs xd"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>Functions that build urls according to parameters passed
        </xd:desc>
    </xd:doc>
        
    <xsl:param name="startRecord" select="1" as="xs:integer"/>
    <xsl:param name="maximumRecords" select="10" as="xs:integer"/>
    <xsl:param name="query" select="''" as="xs:string"/>
    <xsl:param name="base-uri-public" select="''" as="xs:string"/>
    <xsl:param name="base-uri" select="''" as="xs:string"/>
    <xsl:param name="version" select="''" as="xs:string"/>
    <xsl:param name="x-style" select="''" as="xs:string"/>
    <xsl:param name="operation" select="''" as="xs:string"/>
    
    <xsl:function name="_:urlParameters" as="xs:string">
        <xsl:value-of select="_:urlParameters($startRecord, $query)"/>
    </xsl:function>   
    <xsl:function name="_:urlParameters" as="xs:string">
        <xsl:param name="startRecord" as="xs:integer"/>      
        <xsl:value-of select="_:urlParameters($startRecord, $query)"/>
    </xsl:function>
    <xsl:function name="_:urlParameters" as="xs:string">
        <xsl:param name="startRecord" as="xs:integer"/>
        <xsl:param name="query" as="xs:string"/>
        <xsl:value-of select="concat(
            '?version=', $version,
            '&amp;operation=searchRetrieve',
            '&amp;query=', $query,
            '&amp;maximumRecords=', $maximumRecords,
            '&amp;startRecord=', $startRecord,
            '&amp;x-style=', $x-style)"/>
    </xsl:function>
    
    <xsl:function name="_:scanUrlParameters">
        <xsl:param name="scanClause"/>
        <xsl:param name="maximumTerms"/>
        <xsl:value-of select="concat(
            '?version=', $version,
            '&amp;operation=scan',
            '&amp;scanClause=', encode-for-uri($scanClause),
            '&amp;maximumTerms=', $maximumTerms)"/>     
    </xsl:function>
    
</xsl:stylesheet>