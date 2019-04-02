<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:dct="http://purl.org/dc/terms/"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:jb80="http://vocabs.acdh.oeaw.ac.at/JB80"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output method="xml" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="base-url" select="'http://vocabs.acdh.oeaw.ac.at/JB80'"/>
    <xsl:template match="/">
        <rdf:RDF>
            <xsl:attribute name="xml:base" select="$base-url"/>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template>
    
    <xsl:function name="jb80:url">
        <xsl:param name="context" as="item()"/>
        <xsl:variable name="local-name">
            <xsl:choose>
                <xsl:when test="$context instance of attribute(n)">
                    <xsl:value-of select="concat('c',$context)"/>
                </xsl:when>
                <xsl:when test="$context instance of element(thesaurus)"/>
                <xsl:when test="$context instance of element(category)">
                    <xsl:value-of select="concat('c',$context/@n)"/>
                </xsl:when>
                <xsl:when test="$context instance of element(catDesc)">
                    <xsl:value-of select="concat('c',$context/parent::category/@n)"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($base-url,if ($local-name!='') then concat('#',$local-name) else ())"/>
    </xsl:function>
    
    <xsl:template match="taxonomy">
        <rdf:Description rdf:about="{$base-url}">
            <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#ConceptScheme"/>
            <dct:title>JB 80 Thesaurus</dct:title>
            <dct:rights>https://creativecommons.org/licenses/by/4.0/</dct:rights>
            <dct:language>German</dct:language>
            <dct:format>application/rdf+xml</dct:format>
            <dct:author>Bernhard Scheid</dct:author>
            <dct:contributor>Lennart-Pascal Hruska</dct:contributor>
            <xsl:for-each select="category">
                <skos:hasTopConcept rdf:resource="{jb80:url(.)}"/>
            </xsl:for-each>
        </rdf:Description>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="category">
        <rdf:Description rdf:about="{jb80:url(.)}">
            <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
            <xsl:apply-templates select="* except category"/>
            <skos:inScheme rdf:resource="{jb80:url(ancestor::taxonomy)}"/>
            <xsl:if test="parent::category">
                <skos:broader rdf:resource="{jb80:url(parent::category/@n)}"/>
            </xsl:if>
        </rdf:Description>
        <xsl:apply-templates select="category"/>
    </xsl:template>
    
    <xsl:template match="catDesc">
        <skos:prefLabel xml:lang="de"><xsl:value-of select="."/></skos:prefLabel>
    </xsl:template>
</xsl:stylesheet>