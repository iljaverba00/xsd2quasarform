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
				.bottom-bar {
					display: flex;
					justify-content: flex-end;
					margin-right: 10px;
				}
				button {
					transition: background .28s ease-in-out;
					cursor: pointer;
				}
				button[type='submit']:before {
					content: "Сохранить";
					color: white;
				}
				button.cancel:before {
					content: "Отмена";
					color: white;
				}
				button.add,
				button.cancel,
				button[type="submit"] {
					display: inline-flex;
    				flex-direction: row;
    				align-items: center;
    				position: relative;
    				outline: 0;
    				border: 0;
    				vertical-align: middle;
    				font-size: 11px;
    				line-height: 1.715em;
    				text-decoration: none;
    				font-weight: 500;
    				text-transform: uppercase;
    				text-align: center;
    				width: auto;
    				height: auto;
    				padding: 4px 16px;
    				min-height: 2.572em;
    				background: #1976d2;
    				color: white;
    				font-weight: 600;
				}
				button:hover {
					background: #0389e9;
				}
				button.add:before {
					content: "\002795\FE0E  ";
					margin-right: 4px;
				}
				button.remove {
					border-radius: 50%;
					border-style: none;
					margin: 5px;
					height: 20px;
					width: 20px;
					padding: 5px;
					font-size: small;
					display: flex;
					align-items: center;
					justify-content: center;
					background: #1976d2;
    				color: white;
				}
				*:has( > button.remove) {
					display: flex;
    				align-items: center;
				}
				legend:has( > button.remove):before {
					padding-bottom: 3px;
				}
				button.remove:before {
    				content: "\01F5D9\FE0E";
					padding-bottom: 3px;
				}
				input[data-xsd2html2xml-duration='days'] + span:after {
					content: " (days)";
				}
				input[data-xsd2html2xml-duration='minutes'] + span:after {
					content: " (minutes)";
				}
				fieldset {
    				//border-style: none none none solid;
    				//border-width: 2px;
					border: 0;
					display: grid;
					padding-inline-start: 1.2em;
				}

				fieldset:has( > section[collapsed="true"]):not(:has( > section[collapsed="false"])) {
					border: 0;
				}

				legend {
    				cursor: pointer;
    				font-family: Arial, sans-serif;
    				//font-size: 1.2rem;
    				transition: background-color .3s cubic-bezier(.25,.8,.5,1), opacity .4s cubic-bezier(.25,.8,.5,1);
					user-select: none;
				}

				legend:hover {
    				border-radius: 5px;
    				background: #dddddd;
				}

				label[radio] + section > fieldset > legend:hover,
				legend:has(+ label[radio]):hover {
    				border-radius: 0 !important;
    				background: 0 !important;
				}

				label[radio] + section > fieldset > legend:before,
				legend:has(+ label[radio]):before {
    				content: "" !important;
				}

				fieldset:has( > section[collapsed="true"]):not(:has( > section[collapsed="false"])) > legend:before {
					rotate: 210deg;
				}

				label[radio]:has( > input[checked="checked"]) + section {
					display: block !important;
				}

				label[radio] + section > fieldset > legend {
					display: none !important;
				}

				label[radio] + section > fieldset > section {
					display: block !important;
				}

				legend:before {
					content: "\01F53A\FE0E";
					color: black;
					margin-right: 4px;
					rotate: 180deg;
					display: inline-block;
					transition: rotate .28s ease-in-out;
					font-size: small;
				}

				input {
    				border-style: solid;
    				border-color: grey !important;
    				border-width: 1.5px;
					border-radius: 4px;
    				padding: 6px;
				}

				label {
    				min-height: 29px;
					display: flex;
    				align-items: center;
				}

				label > input {
					margin-right: 8px;
				}

				input[type="radio"] + span {
					//font-size: 1.5em;
				}

				span {
					font-size: 16px;
    				color: #0009;
					font-family: sans-serif;
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

				body > form > section {
					height: calc(100vh - 70px);
    				overflow: auto;
				}

				section {
					//display:grid;
					margin-top:10px;
				}

				section[collapsed="true"] {
					display: none;
				}

				button {
					border-radius: 5px;
    				border-style: none;
    				margin: 5px;
				}

				.reqc:after {
					content:" *";
					color: red;
				}
			</xsl:text>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
