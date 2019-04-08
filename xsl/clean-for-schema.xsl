<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:jb80="http://www.oeaw.ac.at/jb80"
    xmlns="http://www.loc.gov/mods/v3"
    exclude-result-prefixes="xs xd"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Apr 2, 2019</xd:p>
            <xd:p><xd:b>Author:</xd:b> osiam</xd:p>
            <xd:p>Cleans up many errors which prevent japbib from being mods conformant</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output indent="yes"/>
    
    <xd:doc>
        <xd:desc>found the automated <_match_/> tag !?</xd:desc>
    </xd:doc>
    <xsl:template match="mods:_match_">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Porcess a few for now</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:processing-instruction name="xml-model">href="http://www.loc.gov/standards/mods/v3/mods-3-7.xsd"</xsl:processing-instruction>
        <modsCollection>
            <xsl:apply-templates select="subsequence(./*:modsCollection/*:mods, 1, 50000)"/>
        </modsCollection>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>no note in part, after that</xd:desc>
    </xd:doc>
    <xsl:template match="mods:part[.//mods:note]">
        <part>
            <xsl:apply-templates select="* except *:note"/> 
        </part>
        <xsl:apply-templates select=".//*:note"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>no note in extent in part, after part</xd:desc>
    </xd:doc>
    <xsl:template match="mods:extent[mods:note]">
        <extent>
            <xsl:apply-templates select="* except *:note"/> 
        </extent>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Extent has a text() needs to be start or list</xd:desc>
    </xd:doc>
    <xsl:template match="mods:relatedItem/mods:part/mods:extent[@unit = 'page' and not(*)]">
        <extent unit='page'>
            <xsl:choose>
                <xsl:when test=". castable as xs:integer">                    
                    <start><xsl:value-of select="."/></start>
                </xsl:when>
                <xsl:otherwise>
                    <list><xsl:value-of select="."/></list>
                </xsl:otherwise>
            </xsl:choose>
        </extent>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>xml:id -> ID</xd:desc>
    </xd:doc>
    <xsl:template match="@xml:id">
        <xsl:attribute name="ID" select="data(.)"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Redo extensions to be confomant</xd:desc>
    </xd:doc>
    <xsl:template match="mods:extension[jb80:data]">
        <extension>
        <jb80:data xmlns:jb80="http://www.oeaw.ac.at/jb80" xmlns="http://www.oeaw.ac.at/jb80">
              <xsl:apply-templates select="jb80:data/*" mode="to-jb80-namespace"/>
        </jb80:data>
        </extension>
        <extension>
            <jb80:history xmlns="http://www.tei-c.org/ns/1.0" xml:space="preserve"><xsl:apply-templates select="../*:fs" mode="to-TEI-namespace"/></jb80:history>
        </extension>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Recreate element in TEI-namespace</xd:desc>
    </xd:doc>
    <xsl:template match="*" mode="to-TEI-namespace">
        <xsl:element name="{local-name()}" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:apply-templates select="node()|@*|comment()|processing-instruction()" mode="to-TEI-namespace"/>
        </xsl:element>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Recreate element in Jb80-namespace</xd:desc>
    </xd:doc>
    <xsl:template match="*" mode="to-jb80-namespace">
        <xsl:element name="{local-name()}" namespace="http://www.oeaw.ac.at/jb80">
            <xsl:apply-templates select="node()|@*|comment()|processing-instruction()" mode="to-jb80-namespace"/>
        </xsl:element>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Used for feature structures, no text there</xd:desc>
    </xd:doc> 
    <xsl:template match="text()" mode="to-TEI-namespace"/>
    
    
    <xd:doc>
        <xd:desc> else text() copied </xd:desc>
    </xd:doc>
    <xsl:template match="@*|comment()|processing-instruction()" mode="to-TEI-namespace to-jb80-namespace">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*|comment()|processing-instruction()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>remove all (TEI)fs</xd:desc>
    </xd:doc>
    <xsl:template match="mods:fs"/>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template match="text()[preceding-sibling::*[1] instance of element(mods:fs)]"/>
    
    <xd:doc>
        <xd:desc>remove usage != primary</xd:desc>
    </xd:doc>
    <xsl:template match="@usage[. != 'primary']"/>
    
    <xd:doc>
        <xd:desc>remove keyDate != yes</xd:desc>
    </xd:doc>
    <xsl:template match="@keyDate[. != 'yes']"/>
    
    <xd:doc>
        <xd:desc>Remove empty nodes physicalDescription, orginInfo</xd:desc>
    </xd:doc>
    <xsl:template match="(mods:physicalDescription|mods:originInfo)[not(text()|*)]" priority="2"/>  
    
    <xd:doc>
        <xd:desc>Remove empty nodes, there are to many false positives</xd:desc>
    </xd:doc>
<!--    <xsl:template match="*[not(text()|*)]" priority="2"/>-->
    
    <xd:doc>
        <xd:desc>Copy the rest</xd:desc>
    </xd:doc>
    <xsl:template match="node()|@*|comment()|processing-instruction()">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*|comment()|processing-instruction()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>