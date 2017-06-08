<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns="http://www.w3org/1999/xhtml"
    exclude-result-prefixes="#all"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>Produces various parts of the website using a searchRetrieve query
        </xd:desc>
    </xd:doc>
    
    <xsl:output indent="no" method="xhtml"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="startRecord" select="1" as="xs:integer"/>
    <xsl:param name="maximumRecords" select="10" as="xs:integer"/>
    <xsl:param name="x-style" select="''" as="xs:string"/>
    <xsl:param name="query" select="''" as="xs:string"/>
    <xsl:param name="base-uri-public" select="''" as="xs:string"/>
    <xsl:param name="base-uri" select="''" as="xs:string"/>
    <xsl:param name="version" select="''" as="xs:string"/>
    
    <xsl:template match="/">
        <div>
            <div class="search-result">
                <xsl:apply-templates
                    select="sru:searchRetrieveResponse/sru:records"/>                
            </div>
            <div class="categoryFilter">
                <xsl:apply-templates
                    select="sru:searchRetrieveResponse/sru:extraResponseData/subjects/taxonomy"/>
            </div>
        </div>
    </xsl:template>

    <!-- Results -->
    
    <xsl:template match="sru:records">
        <ol data-numberOfRecords="{/sru:searchRetrieveResponse/sru:numberOfRecords}" data-nextRecordPosition="{sru:searchRetrieveResponse/sru:nextRecordPosition}"><xsl:apply-templates select="*"/></ol>
    </xsl:template>
    
    <xsl:template match="sru:record">
        <li value="{sru:recordNumber}"><xsl:apply-templates select="sru:recordData/mods:mods"/></li>
    </xsl:template>
    
    <xsl:template match="mods:mods">
        <xsl:if test="not(mods:name[mods:role/mods:roleTerm = 'aut'])"><span class="authors">o. A.</span></xsl:if>
        <xsl:apply-templates select="mods:name[mods:role/mods:roleTerm = 'aut']"/><xsl:text>,</xsl:text>
        <xsl:if test="not(mods:originInfo/mods:dateIssued)"><span class="year">o. J.</span></xsl:if>
        <xsl:apply-templates select="mods:originInfo/mods:dateIssued"/>
        <a href="{$base-uri-public}?version={$version}&amp;operation=searchRetrieve&amp;x-style=record2html.xsl&amp;query=id={mods:recordInfo/mods:recordIdentifier}" class="sup" target="_blank"><xsl:apply-templates select="mods:titleInfo"/></a>
    </xsl:template>
    
    <xsl:template match="mods:name[mods:role/mods:roleTerm = 'aut']">
        <span class="authors"><xsl:value-of select="string-join(mods:namePart, '/ ')"/></span>
    </xsl:template>
    
    <xsl:template match="mods:dateIssued">
        <span class="year"><xsl:value-of select="."/></span>
    </xsl:template>
    
    <xsl:template match="mods:titleInfo">
        <span class="title"><xsl:apply-templates select="*"/></span>
    </xsl:template>
    
    <xsl:template match="mods:title"><xsl:value-of select="normalize-space(.)"/>.</xsl:template>
    
    <xsl:template match="mods:subTitle"><xsl:text xml:space="preserve"> </xsl:text><xsl:value-of select="normalize-space(.)"/>.</xsl:template>

    <!-- Taxonomy -->
    <xsl:template match="taxonomy">
        <ol><xsl:apply-templates select="*"/></ol>
    </xsl:template>
    
    <xsl:template match="category[matches(@n, '^[123456789]$')]">
        <li class="li1"><span><xsl:value-of select="catDesc"/></span>
            <ol><xsl:apply-templates select="category"/></ol>           
        </li>
    </xsl:template>
    
    <xsl:template match="category">
        <li><span class="catNum"><xsl:value-of select="@n"/></span><span class="sup"><xsl:value-of select="catDesc"/></span>
            <xsl:if test="numberOfRecords">
                <a href="{$base-uri-public}?version={$version}&amp;operation=searchRetrieve&amp;x-style={$x-style}&amp;startRecord=1&amp;maximumRecords={$maximumRecords}&amp;query=subject%3D&quot;{catDesc}&quot;" class="zahl" title="Suchergebnisse"><xsl:value-of select="numberOfRecords"/></a>
            </xsl:if>
            <xsl:if test="category">
                <ol><xsl:apply-templates select="category"/></ol>
            </xsl:if>
        </li>
    </xsl:template>
    
</xsl:stylesheet>