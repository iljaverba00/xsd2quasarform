<?xml version="1.0"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema">

    <xsl:template name="add-style">
        <xsl:element name="style">
            <xsl:attribute name="type">text/css</xsl:attribute>
			<xsl:text>
				[hidden] {
					display: none;
				}
				section {
					margin: 5px;
				}
				label {
					display: block;
				}
				label > span {
					float: left;
					margin-right: 5px;
					min-width: 200px;
				}
				button[type='submit']:before {
					content: "OK";
				}
				button.add:before {
					content: "+ ";
				}
				button.remove:before {
					content: "-";
				}
				input[data-xsd2html2xml-duration='days'] + span:after {
					content: " (days)";
				}
				input[data-xsd2html2xml-duration='minutes'] + span:after {
					content: " (minutes)";
				}
				fieldset {
    				border-style: none none none solid;
    				border-width: 2px;
					display: grid;
				}

				legend {
    				cursor: pointer;
    				font-family: Arial, sans-serif;
    				font-size: 1.2rem;
    				transition: background-color .3s cubic-bezier(.25,.8,.5,1), opacity .4s cubic-bezier(.25,.8,.5,1);
				}

				legend:hover {
    				border-radius: 5px;
    				background: #dddddd;
				}

				input {
    				padding: 5px;
    				border-style: solid;
    				border-color: grey !important;
    				border-width: 1.5px;
    				border-radius: 5px;
				}

				label {
    				min-height: 29px;
					display: inline-grid
				}

				span {
					font-size: 16px;
    				color: #0009;
				}

				textarea {
					border-radius: 5px;
					border-width: 1.5px;
				}

				select {
					border-style: solid;
					padding: 5px;
					border-radius: 5px;
					border-width: 1.5px;
					width: 100%
				}

				section {
					display:grid;
					margin-top:10px;
				}

				button {
					border-radius: 5px;
    				border-style: none;
    				margin: 5px;
				}

			</xsl:text>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
