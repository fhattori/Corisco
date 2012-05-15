<?xml version="1.0" encoding="UTF-8"?>

<!--
  new-structural.xsl

  Copyright (c) 2010-2011, Brasiliana Digital Library (http://brasiliana.usp.br).
  Copyright (c) 2002-2005, Hewlett-Packard Company and Massachusetts
  Institute of Technology.  All rights reserved.
 
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:
 
  - Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
 
  - Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
 
  - Neither the name of the Hewlett-Packard Company nor the name of the
  Massachusetts Institute of Technology nor the names of their
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.
 
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
  DAMAGE.
-->

<!--
    Author: Fernando Hattori
-->

<xsl:stylesheet xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
        xmlns:dri="http://di.tamu.edu/DRI/1.0/"
        xmlns:mets="http://www.loc.gov/METS/"
        xmlns:xlink="http://www.w3.org/TR/xlink/"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
        xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"
        xmlns:xhtml="http://www.w3.org/1999/xhtml"
        xmlns:mods="http://www.loc.gov/mods/v3"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:exsl="http://exslt.org/common"
        xmlns:fn="http://www.w3.org/2005/xpath-functions"
        xmlns="http://www.w3.org/1999/xhtml"
        extension-element-prefixes="exsl"
        exclude-result-prefixes="#default dri mets xlink xsl dim xhtml mods dc exsl fn">
    
    <xsl:output indent="yes"/>

    <xsl:variable name="string-max-length">80</xsl:variable>

    <!-- This stylesheet's purpose is to translate a DRI document to an HTML one, a task which it accomplishes
        through interative application of templates to select elements. While effort has been made to
        annotate all templates to make this stylesheet self-documenting, not all elements are used (and
        therefore described) here, and those that are may not be used to their full capacity. For this reason,
        you should consult the DRI Schema Reference manual if you intend to customize this file for your needs.
    -->

    <!--
        The starting point of any XSL processing is matching the root element. In DRI the root element is document,
        which contains a version attribute and three top level elements: body, options, meta (in that order).
        
        This template creates the html document, giving it a head and body. A title and the CSS style reference
        are placed in the html head, while the body is further split into several divs. The top-level div
        directly under html body is called "ds-main". It is further subdivided into:
            "ds-header"  - the header div containing title, subtitle, trail and other front matter
            "ds-body"    - the div containing all the content of the page; built from the contents of dri:body
            "ds-options" - the div with all the navigation and actions; built from the contents of dri:options
            "ds-footer"  - optional footer div, containing misc information
        
        The order in which the top level divisions appear may have some impact on the design of CSS and the
        final appearance of the DSpace page. While the layout of the DRI schema does favor the above div
        arrangement, nothing is preventing the designer from changing them around or adding new ones by
        overriding the dri:document template.
    -->

    <xsl:template name="conteudo-central">
        <div id="conteudo-central">
            <xsl:choose>

                <xsl:when test="//dri:body/dri:div[@n='item-view']">
                    <xsl:call-template name="itemViewer"/>
                </xsl:when>

                <xsl:otherwise>
                    <div id="coluna-resultados">
                        <xsl:if test="//dri:options/dri:list[@n='discovery-location']">
                            <div id="abas">
                                <xsl:apply-templates select="//dri:options/dri:list[@n='discovery-location']" mode="tabList"/>
                            </div>
			    </xsl:if>

                        <xsl:apply-templates select="//dri:body/dri:div/*[not(@n='search-controls') and not(name()='head')]"/>
                    </div>

                    <xsl:apply-templates select="//dri:options"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <xsl:template match="dri:options/dri:list[dri:list][@n='discovery']" priority="4">
      <!--
      <xsl:apply-templates select="//dri:div[@n='search-filters']" />
      -->
      <!-- Once the search box is built, the other parts of the options are added -->
      <div id="titulo-refinar" class="borda">
        <h3><i18n:text>xmlui.dri2xhtml.structural.search-filter</i18n:text></h3>
      </div>

      <xsl:apply-templates select="*[not(name()='head')]" mode="nested"/>
    </xsl:template>

    <xsl:template match="dri:options/dri:list[@n='secondary-search']" priority="3">
      <xsl:if test="count(dri:item) > 0">
	<div id="titulo-buscas" class="borda">
          <h3><i18n:text>xmlui.Discovery.SimpleSearch.filter_head</i18n:text></h3>
	</div>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="dri:field[@type='composite']">
          <xsl:call-template name="pick-label"/>
          <xsl:apply-templates select="*[not(name()='head')]" mode="formComposite"/>
        </xsl:when>
        <xsl:when test="dri:list[@type='form']">
          <xsl:apply-templates />
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="pick-label"/>
          <div id="adicionar-busca" class="ds-form-content2">
            <xsl:apply-templates select="*[not(name()='head')]" mode="formComposite"/>
	    <!-- special name used in submission UI review page -->
	    <xsl:if test="@n = 'submit-review-field-with-authority'">
              <xsl:call-template name="authorityConfidenceIcon">
                <xsl:with-param name="confidence" select="substring-after(./@rend, 'cf-')"/>
              </xsl:call-template>
            </xsl:if>
	    <!--                        Botão BUSCAR-->
	    <!--                        <xsl:apply-templates select="//dri:div[@interactive='yes'][@n='general-query']/dri:p"/>-->
          </div>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>
    
    <xsl:template match="dri:options//dri:item" mode="Corisco" priority="1">
      <xsl:choose>
        <xsl:when test="contains(dri:xref/@target, 'community-list')">
          <!-- SKIP -->
        </xsl:when>
        <xsl:when test="contains(dri:xref/@target, 'title')">
	  <li class="lista-item">
            <span>
              <a>
		<xsl:attribute name="href">
		  <xsl:value-of select="$context-path"/>
		  <xsl:if test="//dri:meta/dri:pageMeta/dri:metadata[@element='focus'][@qualifier='container']">
                    <xsl:text>/handle/</xsl:text>
                    <xsl:value-of select="substring-after(//dri:meta/dri:pageMeta/dri:metadata[@element='focus'][@qualifier='container'], ':')"/>
		  </xsl:if>
		  <xsl:text>/discover?sort_by=dc.title_sort&amp;order=ASC</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="class">
		  <xsl:value-of select="@rend"/>
		</xsl:attribute>
		<xsl:apply-templates select="dri:xref/*"/>
              </a>
            </span>
	  </li>
	</xsl:when>
        <xsl:otherwise>
          <li class="lista-item">
            <span><xsl:apply-templates /></span>
          </li>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>
    
    <xsl:template match="dri:list[@n='account']" priority="100">
      <!-- hide -->
    </xsl:template>
    
</xsl:stylesheet>
